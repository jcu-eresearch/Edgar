import db
import Queue
import urllib2
import logging
import multiprocessing
import binascii
import uuid
import traceback
import datetime
import shapely.wkt
import shapely.geometry
from sqlalchemy import func, select
from geoalchemy import WKTSpatialElement

log = logging.getLogger(__name__)


class Syncer:

    def __init__(self, ala):
        '''The `ala` param is the ala.py module. This is passed in a a ctor
        param because it will be substituded with mockala.py during unit
        testing.'''

        row = db.sources.select()\
                .where(db.sources.c.name == 'ALA')\
                .execute().fetchone()

        if row is None:
            raise RuntimeError('ALA row missing from sources table in db')

        self.source_row_id = row['id']
        self.last_import_time = row['last_import_time']
        self.num_dirty_records_by_species_id = {}
        self.ala = ala
        self.ala_species_occurrence_counts = None  # lazy loaded
        self.ala_species_by_sname = None  # lazy loaded


    def sync(self, sync_species=True, sync_occurrences=True):
        # add species
        # species are never deleted, because occassionally ALA does
        # not return the full list of species, which would cause species to be
        # deleted locally and orphan their occurrences.
        if sync_species:
            log.info('Syncing species list')
            added_species, deleted_species = self.added_and_deleted_species()
            for species in added_species:
                self.add_species(species)


        # update occurrences
        if sync_occurrences:
            log.info('Syncing occurrence records')
            self.sync_occurrences()


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


    def _cache_all_remote_species(self):
        if self.ala_species_by_sname is None:
            self.ala_species_by_sname = {}
            for bird in self.ala.all_bird_species():
                self.ala_species_by_sname[bird.scientific_name] = bird


    def added_and_deleted_species(self):
        '''Returns (added, deleted) where `added` is an iterable of ala.Species
        objects that are not present in the local db, and `deleted` is an iterable
        of rows from the db.species table that were not found at ALA.'''

        local = self.local_species_by_scientific_name()
        local_set = frozenset(local.keys())

        self._cache_all_remote_species()
        remote = self.ala_species_by_sname
        remote_set = frozenset(remote.keys())

        added_set = remote_set - local_set
        deleted_set = local_set - remote_set

        added = [species for name, species in remote.iteritems() if name in added_set]
        deleted = [row for name, row in local.iteritems() if name in deleted_set]

        return (added, deleted)


    def add_species(self, species):
        '''Adds `species` to the local db, where `species` is an ala.Species
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


    def sync_occurrences(self):
        '''Performs all adding, updating, and deleting of rows in the
        db.occurrences table of the database.

        Also updates db.species.c.num_dirty_occurrences.'''

        start_time = datetime.datetime.utcnow()

        # insert new, and update existing, occurrences
        occ_generator = self.mp_fetch_occurrences(since=self.last_import_time,
                                                  record_dirty=True)
        for occ in occ_generator:
            self.upsert_occurrence(occ, occ.species_id)

        # update last import time for ALA
        db.sources.update().\
            where(db.sources.c.id == self.source_row_id).\
            values(last_import_time=start_time).\
            execute()

        # Brute force re-download all occurrences if the local and
        # remote counts don't match
        log.info('Performing re-download of occurrences for species'+
                 'with incorrect occurrence counts');
        self.redownload_occurrences_if_needed()

        # log warnings if the counts dont match up
        log.info('Checking that local occurrence counts match ALA')
        self.check_occurrence_counts()

        # increase number in db.species.num_dirty_occurrences
        log.info('Updating number of dirty occurrences')
        self.update_num_dirty_occurrences()



    def redownload_occurrences_if_needed(self):
        '''Re-downloads every single record for each species, but only if the
        occurrence counts differ between ALA and the local database.

        This must be called as the last step in syncing occurrence records,
        because adding and updating occurrences will alter the number of
        records per species.

        This operation is expensive in terms of memory and time, so it only
        happens when the local occurrence count per species is different to the
        count at ALA.

        Builds a set of uuid.UUID objects for records that exist at ALA, then
        checks every local record to see if it still exists in the set.'''

        species_to_redownload = []

        for row, lc, rc in self.species_with_occurrence_counts():
            # don't run unless our count is different to ALAs count
            if lc == rc:
                continue

            log.warning('Performing full re-download for species %s. ' +
                        '(local count = %d, ALA count = %d)',
                        row['scientific_name'],
                        lc, rc)

            species_to_redownload.append(row)

            # delete local records
            # will cascade into sensitive_occurrences table
            db.occurrences.delete().\
                where(db.occurrences.c.species_id == row['id']).\
                where(db.occurrences.c.source_id == self.source_row_id).\
                execute()

            # keep track of the deletions and additions
            self.increase_dirty_count(row['id'], abs(lc - rc))


        # fetch all the records again
        occ_generator = self.mp_fetch_occurrences(
                since=None,
                species_to_fetch=species_to_redownload,
                record_dirty=False)

        for occurrence in occ_generator:
            self.upsert_occurrence(occurrence, occurrence.species_id)


    def check_occurrence_counts(self):
        '''Logs warnings if the local and remote occurrence counts per species
        do not match.'''

        for row, lc, rc in self.species_with_occurrence_counts():
            if lc == rc:
                continue #  counts are the same

            log.warning('Occurrence counts differ for species %s,' +
                        '(local count = %d, ALA count = %d)',
                        row['scientific_name'],
                        lc, rc)


    def species_with_occurrence_counts(self):
        '''Checks the number of local occurrences against the number of
        occurrences at ALA, yielding the db.species row, local count and remote
        count if the counts are different.'''

        remote_counts = self.remote_occurrence_counts_by_species_id()
        local_counts = self.local_occurrence_counts_by_species_id()

        for row in self.local_species():
            if row['id'] in remote_counts:
                yield (row, local_counts[row['id']], remote_counts[row['id']])


    def remote_occurrence_counts_by_species_id(self):
        '''Returns a dict with db.species.c.id keys, and the values are the
        number of occurrences present at ALA for that species.

        The results are cached after the first call to this method.'''

        # try return cached data
        if self.ala_species_occurrence_counts is not None:
            return self.ala_species_occurrence_counts

        log.info('Fetching ALA occurrence counts for species')

        input_q = multiprocessing.Queue()
        pool = multiprocessing.Pool(8, _mp_init, [input_q, self.ala])
        active_workers = 0

        # fill pool with every species
        for row in self.local_species():
            species = self.ala_species_for_scientific_name(row['scientific_name'])
            if species is not None:
                args = (species, row['id'])
                pool.apply_async(_mp_fetch_occur_count, args)
                active_workers += 1

        pool.close()

        #keep reading from the queue until all subprocesses are done
        self.ala_species_occurrence_counts = {}
        while active_workers > 0:
            result = input_q.get()
            active_workers -= 1

            if active_workers % 100 == 0:
                log.info('%d species remaining to fetch occurrence counts for',
                        active_workers)

            if len(result) == 2:
                species_id, occ_count = result
                self.ala_species_occurrence_counts[species_id] = occ_count
            else:
                raise RuntimeError("Worker process failed: " + result[0])

        # all the subprocesses should be dead by now
        pool.join()
        log.info('Finished fetching ALA occurrence counts for species')

        return self.ala_species_occurrence_counts;


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


    def ala_species_for_scientific_name(self, scientific_name):
        '''Same as ala.species_for_scientific_name except caches the result'''
        self._cache_all_remote_species()
        if scientific_name in self.ala_species_by_sname:
            return self.ala_species_by_sname[scientific_name]
        else:
            species = self.ala.species_for_scientific_name(scientific_name)
            self.ala_species_by_sname[scientific_name] = species
            return species

    def rate_occurrence(self, occurrence):
        '''Returns an occurrences.rating enum value for an ala.Occurrence'''
        # TODO: determine rating better using lists of assertions
        if occurrence.is_geospatial_kosher:
            return 'irruptive'
        else:
            return 'invalid'


    def upsert_occurrence(self, occ, species_id):
        '''Looks up whether `occurrence` (an ala.Occurrence object)
        already exists in the local db. If it does, the db row is updated with
        the information in `occurrence`. If it does not exist, a new row is
        inserted.

        `species_id` must be supplied as an argument because it is not
        obtainable from `occurrence`'''

        if occ.coord is not None:
            occ_id = self.upsert_nonsensitive(occ, species_id)
            if occ.sensitive_coord is not None:
                self.upsert_sensitive(occ, occ_id)


    def upsert_nonsensitive(self, occ, species_id):
        existing = db.occurrences.select().\
            where(db.occurrences.c.source_record_id == occ.uuid.bytes).\
            where(db.occurrences.c.source_id == self.source_row_id).\
            execute().\
            fetchone()

        p = shapely.geometry.Point(occ.coord.longi, occ.coord.lati)
        location = WKTSpatialElement(shapely.wkt.dumps(p), 4326)

        rating = self.rate_occurrence(occ)

        if existing is None:
            return db.occurrences.insert().\
                returning(db.occurrences.c.id).\
                values(location=location,
                       source_rating=rating,
                       rating=rating,
                       species_id=species_id,
                       source_id=self.source_row_id,
                       source_record_id=occ.uuid.bytes).\
                execute().\
                scalar()
        else:
            return db.occurrences.update().\
                returning(db.occurrences.c.id).\
                values(location=location,
                       source_rating=self.rate_occurrence(occ),
                       species_id=species_id).\
                where(db.occurrences.c.id == existing['id']).\
                execute().\
                scalar()


    def upsert_sensitive(self, occ, occ_id):
        existing = db.sensitive_occurrences.select().\
            where(db.sensitive_occurrences.c.occurrence_id == occ_id).\
            execute().\
            fetchone()

        p = shapely.geometry.Point(occ.sensitive_coord.longi, occ.sensitive_coord.lati)
        sens_location = WKTSpatialElement(shapely.wkt.dumps(p), 4326)

        if existing is None:
            db.sensitive_occurrences.insert().\
                values(occurrence_id=occ_id,
                       sensitive_location=sens_location).\
                execute()
        else:
            db.sensitive_occurrences.update().\
                values(sensitive_location=sens_location).\
                where(db.sensitive_occurrences.c.occurrence_id == occ_id).\
                execute()


    def mp_fetch_occurrences(self, since, record_dirty=False, species_to_fetch=None):
        '''Generator for ala.Occurrence objects.

        `species` is an iterable of db.species rows. If it is None (default) it
        will get all species rows from the database, so update the species
        table before calling this function.

        Uses a pool of processes to fetch occurrence records. The subprocesses
        feed the records into a queue which the original process reads and
        yields. This should let the main process access the database at full
        speed while the subprocesses are waiting for more records to arrive
        over the network.'''

        if species_to_fetch is None:
            species_to_fetch = db.species.select().execute();

        input_q = multiprocessing.Queue(10000)
        pool = multiprocessing.Pool(8, _mp_init, [input_q, self.ala])
        active_workers = 0

        # fill the pool full with every species
        for species_row in species_to_fetch:
            sciname = species_row['scientific_name']
            species = self.ala_species_for_scientific_name(sciname)
            if species is None:
                log.warning("Should have ALA.Species for %s, but don't",
                            sciname)
            elif species.scientific_name != sciname:
                #old species that has been renamed, don't fetch
                pass
            else:
                args = (species, species_row['id'], since)
                pool.apply_async(_mp_fetch_occurrences, args)
                active_workers += 1

        pool.close()

        # keep reading from the queue until all the subprocesses are finished
        while active_workers > 0:
            record = None
            while record is None:
                try:
                    record = input_q.get(True, 10.0)
                except Queue.Empty:
                    log.warning(
                        'Received nothing from ALA in the last 10 seconds')

            if isinstance(record, self.ala.Occurrence):
                yield record
            elif isinstance(record, tuple):
                active_workers -= 1
                if len(record) == 3:
                    species = record[0]
                    species_id = record[1]
                    num_records = record[2]

                    log.info('Finished processing %d records for %s' +
                             ' (%d species remaining)',
                             num_records,
                             species.scientific_name,
                             active_workers)

                    if record_dirty:
                        self.increase_dirty_count(species_id, num_records)
                else:
                    raise RuntimeError('Worker process failed: ' + record[0])
            else:
                raise RuntimeError('Unexpected type coming from input_q: ' +
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


def _mp_init(output_q, ala):
    '''Called when a subprocess is started. See Syncer.mp_fetch_occurrences'''
    _mp_init.ala = ala
    _mp_init.output_q = output_q
    _mp_init.log = multiprocessing.log_to_stderr()
    _mp_init.log_level = _mp_init.log.getEffectiveLevel()

    #stops annoying "child process shutting down" messages
    _mp_init.log.setLevel(logging.WARNING)


def _mp_format_exception(e):
    formatted = str(e) + '\n' + traceback.format_exc()
    if isinstance(e, urllib2.HTTPError):
        formatted += '\n\nResponse Headers:\n' + str(dict(e.info()))
        formatted += '\n\nResponse Payload:\n' + e.read()

    return formatted


def _mp_fetch_occurrences(species, species_id, since_date):
    '''Gets all relevant records for the given species from ALA, and pumps the
    records into _mp_init.output_q.

    If the function finished successfully, will put a len 3 tuple in the
    output_q with (species, species_id, num_occurrences_found). If the
    function fails, will put a len 1 tuple in the _mp_init.output_q with a
    failure message string in it.

    Adds a `species_id` attribute to each ala.Occurrence object set to
    the argument given to this function.'''

    _mp_init.log.setLevel(_mp_init.log_level);

    try:
        num_records = _mp_fetch_occurrences_inner(species,
                                                  species_id,
                                                  since_date)
        _mp_init.output_q.put((species, species_id, num_records))
    except Exception, e:
        _mp_init.output_q.put((_mp_format_exception(e),))

    #stops annoying "child process shutting down" messages
    _mp_init.log.setLevel(logging.WARNING)


def _mp_fetch_occurrences_inner(species, species_id, since_date):
    num_records = 0
    for record in _mp_init.ala.occurrences_for_species(species.lsid, since_date):
        record.species_id = species_id
        _mp_init.output_q.put(record)
        num_records += 1

    return num_records


def _mp_fetch_occur_count(species, species_id):
    _mp_init.log.setLevel(_mp_init.log_level);

    try:
        count = _mp_init.ala.num_occurrences_for_lsid(species.lsid)
        _mp_init.output_q.put((species_id, count))
    except Exception, e:
        _mp_init.output_q.put((_mp_format_exception(e),))

    #stops annoying "child process shutting down" messages
    _mp_init.log.setLevel(logging.WARNING)
