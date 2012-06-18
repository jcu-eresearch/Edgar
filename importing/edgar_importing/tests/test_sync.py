from edgar_importing import mockala
from edgar_importing import sync
from edgar_importing import db
import unittest
import uuid
import datetime
import os.path
import json
import logging
from sqlalchemy import select, func


class TestSync(unittest.TestCase):

    def make_occ(self, lati, longi, sens_lati=None, sens_longi=None, uuid_in=None):
        sens_coord = None
        if sens_lati is not None:
            assert sens_longi is not None
            sens_coord = self.mockala.Coord(sens_lati, sens_longi)

        return self.mockala.Occurrence(
            coord=self.mockala.Coord(lati, longi),
            sens_coord=sens_coord,
            uuid_in=(uuid.uuid4() if uuid_in is None else uuid_in)
        )

    def setUp(self):
        self.now = datetime.datetime.utcnow()
        self.yesterday = self.now - datetime.timedelta(1)
        self.tomorrow = self.now + datetime.timedelta(1)

        #wipe db
        db.sensitive_occurrences.delete().execute()
        db.occurrences.delete().execute()
        db.species.delete().execute()
        db.sources.delete().execute()
        db.sources.insert().execute(
            name='ALA',
            last_import_time=None)

        #wipe mockala
        self.mockala = mockala.MockALA()

        # dummy species
        self.s1 = self.mockala.Species('com1', 'sci1', 'lsid1')
        self.s2 = self.mockala.Species('com2', 'sci2', 'lsid2')
        self.mockala.mock_add_species(self.s1)
        self.mockala.mock_add_species(self.s2)

        # dummy records
        self.records1 = [
            self.make_occ(1, 2),
            self.make_occ(3, 4),
            self.make_occ(5, 6, 1005, 1006)
        ]
        self.records2 = [
            self.make_occ(7, 8),
            self.make_occ(9, 10)
        ]
        self.mockala.mock_add_records(self.s1, self.records1, self.yesterday)
        self.mockala.mock_add_records(self.s2, self.records2, self.now)

        #make new Syncer
        self.syncer = sync.Syncer(self.mockala)


    def id_for_species(self, species):
        sci_name = species.scientific_name
        result = db.species.select().\
                where(db.species.c.scientific_name == sci_name).\
                execute().\
                fetchone()

        if result is None:
            return None
        else:
            return result['id']


    def num_db_occ_for_spec(self, species, sensitive_only=False):
        species_id = self.id_for_species(species)
        if species_id is None:
            return 0

        if sensitive_only:
            table = db.sensitive_occurrences.join(db.occurrences)
        else:
            table = db.occurrences

        q = select([func.count("(*)")]).\
                select_from(table).\
                where(db.occurrences.c.species_id == species_id)
        return db.engine.execute(q).scalar()


    def test_added_species(self):
        added, deleted = self.syncer.added_and_deleted_species()
        self.assertEqual(len(list(added)), 2)
        self.assertEqual(len(list(deleted)), 0)

        for species in added:
            self.syncer.add_species(species)

        self.assertNotEqual(self.id_for_species(self.s1), None)
        self.assertNotEqual(self.id_for_species(self.s2), None)


    def test_renamed_species(self):
        #sync
        self.syncer.sync()
        self.assertFalse(self.id_for_species(self.s1) == None)
        num_records = self.num_db_occ_for_spec(self.s1)

        #rename s1 to sRenamed
        sRenamed = self.mockala.Species('renamed', 'sciRenamed', 'lsidRenamed')
        self.mockala.mock_rename_species(self.s1, sRenamed,
                datetime.datetime.utcnow())

        #sync again
        self.syncer = sync.Syncer(self.mockala)
        self.syncer.sync()

        #make sure sRenamed exists
        self.assertNotEqual(self.id_for_species(sRenamed), None)

        #make sure all records have been moved across
        self.assertEqual(num_records, self.num_db_occ_for_spec(sRenamed))


    def test_added_records(self):
        #assert 0 records
        self.assertEqual(self.num_db_occ_for_spec(self.s1), 0)

        #sync
        self.syncer.sync()

        #assert all records synced
        self.assertEqual(len(self.records1),
                         self.num_db_occ_for_spec(self.s1))


    def test_added_records_after_sync(self):
        #sync
        self.syncer.sync()

        #simulate new records
        new_records = [
            self.make_occ(22, 33),
            self.make_occ(44, 55)
        ]
        self.mockala.mock_add_records(self.s1, new_records)

        #sync again
        self.syncer = sync.Syncer(self.mockala)
        self.syncer.sync()

        #check new records added
        self.assertEqual(len(new_records) + len(self.records1),
                         self.num_db_occ_for_spec(self.s1))


    def test_deleted_records_after_sync(self):
        #sync
        self.syncer.sync()

        #delete a couple of records
        deleted_records = self.records1[:2]
        remaining_records = self.records1[2:]
        self.mockala.mock_remove_records(self.s1, deleted_records)

        #sync again
        self.syncer = sync.Syncer(self.mockala)
        self.syncer.sync()

        #check deleted records are deleted
        deleted_uuids = frozenset([r.uuid for r in deleted_records])
        remaining_uuids = set()
        for occ in db.occurrences.select().execute():
            occ_uuid = uuid.UUID(bytes=occ['source_record_id'])
            self.assertTrue(occ_uuid not in deleted_uuids)

            remaining_uuids.add(occ_uuid)

        #check that remaining records remain
        for occ in remaining_records:
            self.assertTrue(occ.uuid in remaining_uuids)


    def test_updated_records_after_sync(self):
        #syncwheri
        self.syncer.sync()

        #remember some counts
        old_s1_count = self.num_db_occ_for_spec(self.s1)
        old_s2_count = self.num_db_occ_for_spec(self.s2)

        #change a record, keeping the same uuid
        old_record = self.records1[-1]
        new_record = self.make_occ(12, 34, uuid_in=old_record.uuid)
        self.mockala.mock_update_record(self.s1, new_record,
                new_species=self.s2)

        #sync again
        self.syncer = sync.Syncer(self.mockala)
        self.syncer.sync()

        #check that counts reflect updated record
        self.assertEqual(self.num_db_occ_for_spec(self.s1),
                         old_s1_count - 1)
        self.assertEqual(self.num_db_occ_for_spec(self.s2),
                         old_s2_count + 1)

        #check that updated record has correct lat/long
        query = select(['*', 'ST_X(location::geometry) as longitude', 'ST_Y(location::geometry) as latitude']).\
                    select_from(db.occurrences)
        for occ in db.engine.execute(query):
            occ_uuid = uuid.UUID(bytes=occ['source_record_id'])
            if occ_uuid == old_record.uuid:
                self.assertEqual(occ['latitude'], new_record.coord.lati)
                self.assertEqual(occ['longitude'], new_record.coord.longi)
                break

    def test_added_sensitive_records(self):
        #sync
        self.syncer.sync()

        #check that sensitive record is there
        sensitive_records = [x for x in self.records1 if x.sensitive_coord
                is not None]

        self.assertEqual(len(sensitive_records),
                self.num_db_occ_for_spec(self.s1, sensitive_only=True))

    def test_added_sensitive_records_after_sync(self):
        #sync
        self.syncer.sync()

        #simulate new records
        new_records = [
            self.make_occ(66, 77),
            self.make_occ(88, 99, 1088, 1099)
        ]
        self.mockala.mock_add_records(self.s1, new_records)

        #sync again
        self.syncer = sync.Syncer(self.mockala)
        self.syncer.sync()

        #check new records added
        sensitive_records = [x for x in (self.records1 + new_records)
                if x.sensitive_coord is not None]

        self.assertEqual(len(sensitive_records),
                         self.num_db_occ_for_spec(self.s1, sensitive_only=True))


    def test_deleted_sensitive_records_after_sync(self):
        #sync
        self.syncer.sync()

        #delete all sensitive records for s1
        sensitive_records = [x for x in self.records1
                if x.sensitive_coord is not None]
        self.mockala.mock_remove_records(self.s1, sensitive_records)

        #sync again
        self.syncer = sync.Syncer(self.mockala)
        self.syncer.sync()

        #check deleted records are deleted
        self.assertEqual(0,
                self.num_db_occ_for_spec(self.s1, sensitive_only=True))



def test_suite():
    test_config_path = os.path.abspath(__file__ + "/../../../config.unittests.json")
    with open(test_config_path) as f:
        db.connect(json.load(f))
    return unittest.makeSuite(TestSync)
