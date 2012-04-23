import mockala
import unittest
import uuid
import datetime

class TestMockALA(unittest.TestCase):

    def setUp(self):
        self.mock = mockala.MockALA()
        self.mock.mock_remove_all_species()

    def test_add_species(self):
        s = self.mock.Species('Bug Bear', 'Bugus Bearii', 'bbblsid')
        self.assertIsNone(self.mock.species_for_lsid(s.lsid))
        self.mock.mock_add_species(s)
        self.assertIs(s, self.mock.species_for_lsid(s.lsid))
        self.assertIs(s,
                self.mock.species_for_scientific_name(s.scientific_name))

    def test_add_records(self):
        s = self.mock.Species('Gorrilla Bird', 'Apus (Orangutanii) avex', 'asd')
        self.mock.mock_add_species(s)

        now = datetime.datetime.utcnow()
        oneDay = datetime.timedelta(1)

        # add 2 records yesterday
        when1 = now - oneDay
        records1 = [
            self.mock.Occurrence(1, 2, uuid.uuid4()),
            self.mock.Occurrence(3, 4, uuid.uuid4())
        ]
        self.mock.mock_add_records(s, records1, when1)
        all_occurrences = list(self.mock.occurrences_for_species(s.lsid))
        self.assertEqual(len(all_occurrences), 2)

        # add 3 records tomorrow
        when2 = now + oneDay
        records2 = [
            self.mock.Occurrence(5, 6, uuid.uuid4()),
            self.mock.Occurrence(7, 8, uuid.uuid4()),
            self.mock.Occurrence(9, 10, uuid.uuid4())
        ]
        self.mock.mock_add_records(s, records2, when2)
        all_occurrences = list(self.mock.occurrences_for_species(s.lsid))
        self.assertEqual(len(all_occurrences), 5)

        # get both sets or occurrences
        two_days_ago = now - oneDay - oneDay
        since_two_d_ago = list(self.mock.occurrences_for_species(s.lsid,
            two_days_ago))
        self.assertEqual(len(since_two_d_ago), 5)

        # get the most recent set only
        since_now = list(self.mock.occurrences_for_species(s.lsid, now))
        self.assertEqual(len(since_now), 3)

        # get none of the occurrences
        two_days_away = now + oneDay + oneDay
        since_two_days_away = list(self.mock.occurrences_for_species(s.lsid,
            two_days_away))
        self.assertEqual(len(since_two_days_away), 0)

    def test_rename_species(self):
        old = self.mock.Species('Oldy McGoldy', 'Agedus oldii', 'olddddd')
        new = self.mock.Species('Newy McGooey', 'Newbus youngii', 'newwww')
        old_records = [self.mock.Occurrence(1, 2, uuid.uuid4())]

        self.mock.mock_add_species(old)
        self.mock.mock_add_records(old, old_records, datetime.datetime.utcnow())
        all_birds = list(self.mock.all_bird_species())
        self.assertEqual(len(all_birds), 1)
        self.assertIs(all_birds[0], old)

        self.mock.mock_rename_species(old, new, datetime.datetime.utcnow())
        all_birds = list(self.mock.all_bird_species())
        self.assertEqual(len(all_birds), 1)
        self.assertIs(all_birds[0], new)

        new_records = list(self.mock.occurrences_for_species(new.lsid))
        self.assertEqual(new_records, old_records)

        self.assertEqual(self.mock.num_occurrences_for_lsid(old.lsid), 0)

        self.assertIsNone(self.mock.species_for_lsid(old.lsid))
        self.assertIs(self.mock.species_for_scientific_name(old.scientific_name), new)

        self.assertIs(self.mock.species_for_lsid(new.lsid), new)
        self.assertIs(self.mock.species_for_scientific_name(new.scientific_name), new)

    def test_remove_species(self):
        s = self.mock.Species('Dodo', 'Dodo dodii', 'dododododod')

        self.mock.mock_add_species(s)

        all_species = list(self.mock.all_bird_species())
        self.assertTrue(s in all_species)
        self.assertIs(self.mock.species_for_lsid(s.lsid), s)

        self.mock.mock_remove_species(s)

        all_species = list(self.mock.all_bird_species())
        self.assertFalse(s in all_species)
        self.assertIsNone(self.mock.species_for_lsid(s.lsid))


if __name__ == '__main__':
    unittest.main()
