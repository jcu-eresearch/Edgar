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
import pyspatialite
import sys


class TestSync(unittest.TestCase):

    def setUp(self):
        self.now = datetime.datetime.utcnow()
        self.yesterday = self.now - datetime.timedelta(1)
        self.tomorrow = self.now + datetime.timedelta(1)

        #wipe db
        db.species.delete().execute()
        db.occurrences.delete().execute()
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
            self.mockala.Occurrence(1, 2, uuid.uuid4()),
            self.mockala.Occurrence(3, 4, uuid.uuid4()),
            self.mockala.Occurrence(5, 6, uuid.uuid4())
        ]
        self.records2 = [
            self.mockala.Occurrence(7, 8, uuid.uuid4()),
            self.mockala.Occurrence(9, 10, uuid.uuid4()),
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


    def num_db_occ_for_spec(self, species):
        species_id = self.id_for_species(species)
        if species_id is None:
            return 0

        q = select([func.count("(*)")]).\
                select_from(db.occurrences).\
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

        #make sure s1 is missing
        self.assertEqual(self.id_for_species(self.s1), None)

        #make sure sRenamed exists
        self.assertNotEqual(self.id_for_species(sRenamed), None)

        #make sure all records have been moved across
        self.assertEqual(num_records, self.num_db_occ_for_spec(sRenamed))


    def test_removes_species_with_no_records(self):
        sNone = self.mockala.Species('no records', 'sciNone', 'nr');
        self.mockala.mock_add_species(sNone)
        self.syncer.sync()

        self.assertEqual(self.id_for_species(sNone), None)


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
            self.mockala.Occurrence(66, 77, uuid.uuid4()),
            self.mockala.Occurrence(88, 99, uuid.uuid4())
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
        #sync
        self.syncer.sync()

        #remember some counts
        old_s1_count = self.num_db_occ_for_spec(self.s1)
        old_s2_count = self.num_db_occ_for_spec(self.s2)

        #change a record, keeping the same uuid
        old_record = self.records1[-1]
        new_record = self.mockala.Occurrence(123, 456, old_record.uuid)
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
        for occ in db.occurrences.select().execute():
            occ_uuid = uuid.UUID(bytes=occ['source_record_id'])
            if occ_uuid == old_record.uuid:
                self.assertEqual(occ['latitude'], new_record.latitude)
                self.assertEqual(occ['longitude'], new_record.longitude)
                break


def test_suite():
    # in memory sqlite db
    # uses pyspatialite instead of pysqlite2
    sys.modules['pysqlite2'] = pyspatialite
    db.connect({'db.url':'sqlite+pysqlite://'})
    db.engine.execute("SELECT InitSpatialMetaData();")
    db.metadata.create_all()

    return unittest.makeSuite(TestSync)
