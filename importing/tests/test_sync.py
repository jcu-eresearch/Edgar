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
from sqlalchemy import select, func

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


    def id_for_species(self, species):
        sci_name = species.scientific_name
        result = db.species.select().\
                    where(db.species.c.scientific_name == sci_name).\
                    execute()
        if result.rowcount == 1:
            return result.fetchone()['id']
        else:
            return None

    def num_occurrences_for_species(self, species):
        species_id = self.id_for_species(species)
        q = select([func.count("(*)")]).\
                where(db.occurrences.c.species_id == species_id)
        return db.engine.execute(q).scalar()


    def test_added_species(self):
        added, deleted = self.syncer.added_and_deleted_species()
        self.assertEqual(len(list(added)), 2)
        self.assertEqual(len(list(deleted)), 0)

        for species in added:
            self.syncer.add_species(species)

        self.assertIsNotNone(self.id_for_species(self.s1))
        self.assertIsNotNone(self.id_for_species(self.s2))


    def test_renamed_species(self):
        #sync
        self.syncer.sync()
        self.assertIsNotNone(self.id_for_species(self.s1))
        num_records = self.num_occurrences_for_species(self.s1)

        #rename s1 to sRenamed
        sRenamed = self.mockala.Species('renamed', 'sciRenamed', 'lsidRenamed')
        self.mockala.mock_rename_species(self.s1, sRenamed,
                datetime.datetime.utcnow())

        #sync again
        self.syncer = sync.Syncer(self.mockala)
        self.syncer.sync()

        #make sure s1 is missing
        self.assertIsNone(self.id_for_species(self.s1))

        #make sure sRenamed exists
        self.assertIsNotNone(self.id_for_species(sRenamed))

        #make sure all records have been moved across
        self.assertEqual(num_records,
                self.num_occurrences_for_species(sRenamed))


    def test_removes_species_without_records(self):
        sNone = self.mockala.Species('no records', 'sciNone', 'nr');
        self.mockala.mock_add_species(sNone)
        self.syncer.sync()

        self.assertIsNone(self.id_for_species(sNone))



if __name__ == '__main__':
    logging.basicConfig()
    unittest.main()
