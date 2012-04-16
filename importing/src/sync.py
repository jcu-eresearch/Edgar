import db
import ala
import logging
import multiprocessing
import binascii
import uuid
from sqlalchemy import func, select

log = logging.getLogger(__name__)


class Syncer:

    def __init__(self):
        '''TODO: might pass db into here for unit testing purposes instead of
        using the module directly. Might also do the same for ala module.'''

        row = db.sources.select('id')\
                .where(db.sources.c.name == 'ALA')\
                .execute().fetchone()

        if row is None:
            raise RuntimeError('ALA row missing from sources table in db')

        self.source_row_id = row['id']
        self.cached_upserts = []
        self.num_dirty_records_by_species_id = {}

    def local_species(self):
        '''Returns all db.species rows in the local database.'''
        return db.species.select().execute().fetchall()

    def local_species_by_scientific_name(self):
        '''Returns all species in the local db in a dict. Scientific name is the
        key, the db row is the value.'''

        species = {}
        for row in db.species.select().execute():
            species[row['scientific_name']] = row;
        return species

    def remote_species_by_scientific_name(self):
        '''Returns all species available at ALA in a dict. Scientific name is the
        key, the ala.Species object is the value.'''

        species = {}
        for bird in ala.all_bird_species():
            species[bird.scientific_name] = bird
        return species

    def added_and_deleted_species(self):
        '''Returns (added, deleted) where `added` is an iterable of ala.Species
        objects that are not present in the local db, and `deleted` is an iterable
        of rows from the db.species table that were not found at ALA.'''

        local = self.local_species_by_scientific_name()
        local_set = frozenset(local.keys())
        remote = self.remote_species_by_scientific_name()
        remote_set = frozenset(remote.keys())

        added_set = remote_set - local_set
        deleted_set = local_set - remote_set

        added = [species for name, species in remote.iteritems() if name in added_set]
        deleted = [row for name, row in local.iteritems() if name in deleted_set]

        return (added, deleted)


    def add_species(self, species):
        '''Adds `species` to the local db, where `s` is an ala.Species
        object'''

        log.info('Adding new species "%s"', species.scientific_name)
        db.species.insert().execute(
            scientific_name=species.scientific_name,
            common_name=species.common_name)

    def delete_species(self, row):
        '''Deletes `row` from the local db, where `s` is a row from the
        db.species table'''

        log.info('Deleting species "%s"', row['scientific_name'])
        db.species.delete().where(db.species.c.id == row['id']).execute()

    def sync_occurrences(self, utc_since_date):
        '''Performs all adding, updating, and deleting of rows in the
        db.occurrences table of the database.

        Also updates db.species.c.num_dirty_occurrences.'''

        # insert new, and update existing, occurrences
        for occ in self.occurrences_changed_since(utc_since_date, True):
            self.upsert_occurrence(occ, occ.species_id)
        self.flush_upserts()

        remote_counts = self.remote_occurrence_counts_by_species_id()

        # delete occurrences that have been deleted at ALA
        self.delete_local_occurrences_if_needed(remote_counts)

        # log warnings if the counts dont match up
        self.check_occurrence_counts(remote_counts)

        # increase number in db.species.num_dirty_occurrences
        self.update_num_dirty_occurrences()

    def delete_local_occurrences_if_needed(self, remote_counts):
        '''This must be called as the last step in syncing occurrence records,
        because adding and updating occurrences will alter the number of
        records per species. Checking for deleted records is expensive in terms
        of memory and time, so it only happens with the local occurrence count
        per species is higher than the count at ALA.

        Builds a set of uuid.UUID objects for records that exist at ALA, then
        checks every local record to see if it still exists in the set.'''

        for row, lc, rc in self.species_with_occurrence_counts(remote_counts):
            # don't run unless our count is lower than ALAs count
            if lc <= rc:
                continue

            log.info('Checking for deleted records for species %s',
                     row['scientific_name'])

            # species should never be None, because we already have a count for
            # it from ALA
            species = ala.species_for_scientific_name(row['scientific_name'])
            if species is None:
                log.critical('species should never be None')
                continue

            # build the set of existing uuids
            existing_uuids = set()
            for occurrence in ala.records_for_species(species.lsid):
                existing_uuids.add(occurrence.uuid)

            # loop through every local occurrence, and store the ids of the
            # rows that do not exist at ALA
            row_ids_to_delete = []
            all_rows_for_species = \
                db.occurrences.select().\
                where(db.occurrences.c.species_id == row['id']).\
                where(db.occurrences.c.source_id == self.source_row_id).\
                execute()
            for occ_row in all_rows_for_species:
                occ_uuid = uuid.UUID(bytes=occ_row['source_record_id'])
                if occ_uuid not in existing_uuids:
                    row_ids_to_delete.append(occ_row['id'])

            # free up some memory, because this may be very large
            del existing_uuids

            # delete all the neccessary local occurrences
            for occ_id in row_ids_to_delete:
                db.occurrences.delete().\
                    where(db.occurrences.c.id == occ_id).\
                    execute()

            # free up more memory
            num_deleted = len(row_ids_to_delete)
            del row_ids_to_delete

            # log and keep track of the deletaions
            log.info('Deleted %d records for %s', num_deleted,
                    row['scientific_name'])

            self.increase_dirty_count(row['id'], num_deleted)


    def check_occurrence_counts(self, remote_counts):
        '''Logs warnings if the local and remote occurrence counts per species
        do not match.'''

        for row, lc, rc in self.species_with_occurrence_counts(remote_counts):
            if lc == rc:
                continue #  counts are the same

            log.warning('Occurrence counts differ for species %s,' +
                        '(local count = %d, ALA count = %d)',
                        row['scientific_name'],
                        lc, rc)


    def species_with_occurrence_counts(self, remote_counts):
        '''Checks the number of local occurrences against the number of
        occurrences at ALA, yielding the db.species row, local count and remote
        count if the counts are different.'''

        local_counts = self.local_occurrence_counts_by_species_id()

        for row in self.local_species():
            if row['id'] in remote_counts:
                yield (row, local_counts[row['id']], remote_counts[row['id']])


    def remote_occurrence_counts_by_species_id(self):
        '''Returns a dict with db.species.c.id keys, and the values are the
        number of occurrences present at ALA for that species.'''

        counts = {}

        for row in self.local_species():
            species = ala.species_for_scientific_name(row['scientific_name'])
            if species is not None:
                counts[row['id']] = ala.num_records_for_lsid(species.lsid)

        return counts;

    def local_occurrence_counts_by_species_id(self):
        '''Returns a dict with db.species.c.id keys, and the calues are the
        number of occurrences present in the local database for that
        species.'''

        counts = {}

        for row in self.local_species():
            local_count = \
                db.engine.execute(select(
                    [func.count('*')],
                    #where
                     (db.occurrences.c.species_id == row['id']) &
                     (db.occurrences.c.source_id == self.source_row_id))
                ).scalar()

            counts[row['id']] = local_count

        return counts



    def upsert_occurrence(self, occurrence, species_id):
        '''Looks up whether `occurrence` (an ala.OccurrenceRecord object)
        already exists in the local db. If it does, the db row is updated with
        the information in `occurrence`. If it does not exist, a new row is
        inserted.

        `species_id` must be supplied as an argument because it is not
        obtainable from `occurrence`

        The inserts/updates are cached for performance reasons. The cache is
        flushed every 1000 occurrences. YOU MUST CALL `flush_upserts` AFTER YOU
        HAVE CALLED THIS METHOD FOR THE FINAL TIME.'''

        if len(self.cached_upserts) > 1000:
            self.flush_upserts()

        # TODO: determine rating better using lists of assertions
        rating = 'assumed invalid'
        if occurrence.is_geospatial_kosher:
            rating = 'assumed valid'

        # these should be escaped strings ready for insertion into the SQL
        cols = (str(float(occurrence.latitude)),
                str(float(occurrence.longitude)),
                '"' + rating + '"',
                str(int(species_id)),
                str(int(self.source_row_id)),
                _mysql_encode_binary(occurrence.uuid.bytes))

        self.cached_upserts.append('(' + ','.join(cols) + ')')


    def flush_upserts(self):
        if len(self.cached_upserts) <= 0:
            return

        query = '''INSERT INTO occurrences(
                        latitude, longitude, rating, species_id, source_id,
                        source_record_id)

                   VALUES ''' + \
                \
                ','.join(self.cached_upserts) + \
                \
                ''' ON DUPLICATE KEY UPDATE
                        latitude=VALUES(latitude),
                        longitude=VALUES(longitude),
                        rating=VALUES(rating),
                        species_id=VALUES(species_id);'''

        db.engine.execute(query)

        self.cached_upserts = []


    def occurrences_changed_since(self, since_date, record_dirty=False):
        '''Generator for ala.OccurrenceRecord objects.

        Will use whatever is in the species table of the database, so call
        update the species table before calling this function.

        Uses a pool of processes to fetch occurrence records. The subprocesses
        feed the records into a queue which the original process reads and
        yields. This should let the main process access the database at full
        speed while the subprocesses are waiting for more records to arrive
        over the network.'''

        record_q = multiprocessing.Queue(10000)
        pool = multiprocessing.Pool(8, _mp_init, [record_q])
        active_workers = 0

        # fill the pool full with every species
        for row in db.species.select().execute():
            args = (row['scientific_name'], row['id'], since_date)
            pool.apply_async(_mp_fetch, args)
            active_workers += 1

        pool.close()

        # keep reading from the queue until all the subprocesses are finished
        while active_workers > 0:
            record = record_q.get()
            if isinstance(record, ala.OccurrenceRecord):
                yield record
            elif isinstance(record, tuple):
                active_workers -= 1
                if len(record) == 3:
                    if record[2] > 0:
                        log.info('Finished processing %d records for %s',
                                 record[2],
                                 record[0])
                    if record_dirty:
                        self.increase_dirty_count(record[1], record[2])
                else:
                    raise RuntimeError('Worker process failed: ' + record[0])
            else:
                raise RuntimeError('Unexpected type coming from record_q: ' +
                                   str(type(record)))


        # all the subprocesses should be dead by now
        pool.join()


    def increase_dirty_count(self, species_id, num_dirty):
        if species_id in self.num_dirty_records_by_species_id:
            self.num_dirty_records_by_species_id[species_id] += num_dirty
        else:
            self.num_dirty_records_by_species_id[species_id] = num_dirty


    def local_species_with_no_occurrences(self):
        '''A generator for db.species rows, for rows without any occurrence
        records in the local database'''

        for row in self.local_species():
            q = select(['count(*)'], db.occurrences.c.species_id == row['id'])
            if db.engine.execute(q).scalar() == 0:
                yield row


    def update_num_dirty_occurrences(self):
        '''Updates the species.num_dirty_occurrences column with the number of
        occurrences that have been changed by self.

        TODO: account for deleted records
        '''
        dirty_col = db.species.c.num_dirty_occurrences

        for row in self.local_species():
            if row['id'] not in self.num_dirty_records_by_species_id:
                continue

            newly_dirty = self.num_dirty_records_by_species_id[row['id']]
            if newly_dirty <= 0:
                continue

            db.species.update().\
                values(num_dirty_occurrences=(dirty_col + newly_dirty)).\
                where(db.species.c.id == row['id']).\
                execute()


def _mp_init(record_q):
    '''Called when a subprocess is started. See
    Syncer.occurrences_changed_since'''
    _mp_init.record_q = record_q
    _mp_init.log = None #  multiprocessing.log_to_stderr()


def _mp_fetch(species_sname, species_id, since_date):
    '''Gets all relevant records for the given species from ALA, and pumps the
    records into _mp_init.record_q.

    If the function finished successfully, will put a len 3 tuple in the
    record_q with (scientific_name, species_id, num_records_found). If the
    function fails, will put a len 1 tuple in the record_q with a failure
    message string in it.

    Adds a `species_id` attribute to each ala.OccurrenceRecord object set to
    the argument given to this function.'''

    num_records = 0
    failure_msg = None
    try:
        num_records = _mp_fetch_inner(species_sname, species_id, since_date)
    except Exception, e:
        failure_msg = str(e)
        if _mp_init.log is not None:
            _mp_init.log.exception()

    if failure_msg is None:
        _mp_init.record_q.put((species_sname, species_id, num_records))
    else:
        _mp_init.record_q.put((failure_msg,))


def _mp_fetch_inner(species_sname, species_id, since_date):
    species = ala.species_for_scientific_name(species_sname)
    if species is None:
        if _mp_init.log is not None:
            _mp_init.log.warning('Species not found at ALA: %s', species_sname)
        return 0

    num_records = 0
    for record in ala.records_for_species(species.lsid, since_date):
        record.species_id = species_id
        _mp_init.record_q.put(record)
        num_records += 1

    return num_records


def _mysql_encode_binary(binstr):
    '''
    >>> _mysql_encode_binary('hello')
    "x'68656c6c6f'"
    '''
    return "x'" + binascii.hexlify(binstr) + "'"
