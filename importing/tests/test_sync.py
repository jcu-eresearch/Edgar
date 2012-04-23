import pathfix
import mockala
import sync
import db
import unittest
import uuid
import datetime
import os.path
import json
import logging

def setUpModule():
    test_dir = os.path.dirname(os.path.abspath(__file__))
    config_path = test_dir + '/testconfig.json'
    with open(config_path, 'rb') as f:
        conf = json.load(f)
        db.connect(conf)

    #logging.root.setLevel(logging.__dict__[conf['logLevel']])

def tearDownModule():
    #db.disconnect()
    pass


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

        # nicer test output
        print


    def db_species_exists(self, scientific_name):
        result = db.species.select().\
                    where(db.species.c.scientific_name == scientific_name).\
                    execute()
        return result.rowcount == 1


    def test_added_species(self):
        added, deleted = self.syncer.added_and_deleted_species()
        self.assertEqual(len(list(added)), 2)
        self.assertEqual(len(list(deleted)), 0)

        for species in added:
            self.syncer.add_species(species)

        self.assertTrue(self.db_species_exists('sci1'))
        self.assertTrue(self.db_species_exists('sci2'))


    def test_renamed_species(self):
        self.syncer.sync()
        self.assertTrue(self.db_species_exists('sci1'))

        sRenamed = self.mockala.Species('renamed', 'sciRenamed', 'lsidRenamed')
        self.mockala.mock_rename_species(self.s1, sRenamed,
                datetime.datetime.utcnow())
        self.assertEqual(self.mockala.num_occurrences_for_lsid(self.s1.lsid), 0)

        self.syncer = sync.Syncer(self.mockala)
        self.syncer.sync()

        self.assertFalse(self.db_species_exists('sci1'))
        self.assertTrue(self.db_species_exists('sciRenamed'))



    def test_removes_species_without_records(self):
        self.mockala.mock_add_species(self.mockala.Species('no records', 'sciNone', 'nr'))
        self.syncer.sync()

        self.assertFalse(self.db_species_exists('sciNone'))



if __name__ == '__main__':
    logging.basicConfig()
    unittest.main()
