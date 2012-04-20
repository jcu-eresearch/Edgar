import mockala
import unittest
import uuid
import datetime

class TestMockALA(unittest.TestCase):

    def setUp(self):
        mockala.mock_remove_all_species()

    def test_add_species(self):
        s = mockala.Species('Bug Bear', 'Bugus Bearii', 'bbblsid')
        self.assertIsNone(mockala.species_for_lsid(s.lsid))
        mockala.mock_add_species(s)
        self.assertIs(s, mockala.species_for_lsid(s.lsid))
        self.assertIs(s,
                mockala.species_for_scientific_name(s.scientific_name))

    def test_add_records(self):
        s = mockala.Species('Gorrilla Bird', 'Apus (Orangutanii) avex', 'asd')
        mockala.mock_add_species(s)

        now = datetime.datetime.utcnow()
        oneDay = datetime.timedelta(1)

        # add 2 records yesterday
        when1 = now - oneDay
        records1 = [
            mockala.Occurrence(1, 2, uuid.uuid4()),
            mockala.Occurrence(3, 4, uuid.uuid4())
        ]
        mockala.mock_add_records(s, records1, when1)
        all_occurrences = list(mockala.occurrences_for_species(s.lsid))
        self.assertEqual(len(all_occurrences), 2)

        # add 3 records tomorrow
        when2 = now + oneDay
        records2 = [
            mockala.Occurrence(5, 6, uuid.uuid4()),
            mockala.Occurrence(7, 8, uuid.uuid4()),
            mockala.Occurrence(9, 10, uuid.uuid4())
        ]
        mockala.mock_add_records(s, records2, when2)
        all_occurrences = list(mockala.occurrences_for_species(s.lsid))
        self.assertEqual(len(all_occurrences), 5)

        # get both sets or occurrences
        two_days_ago = now - oneDay - oneDay
        since_two_d_ago = list(mockala.occurrences_for_species(s.lsid,
            two_days_ago))
        self.assertEqual(len(since_two_d_ago), 5)

        # get the most recent set only
        since_now = list(mockala.occurrences_for_species(s.lsid, now))
        self.assertEqual(len(since_now), 3)

        # get none of the occurrences
        two_days_away = now + oneDay + oneDay
        since_two_days_away = list(mockala.occurrences_for_species(s.lsid,
            two_days_away))
        self.assertEqual(len(since_two_days_away), 0)

    def test_rename_species(self):
        old = mockala.Species('Oldy McGoldy', 'Agedus oldii', 'olddddd')
        new = mockala.Species('Newy McGooey', 'Newbus youngii', 'newwww')
        old_records = [mockala.Occurrence(1, 2, uuid.uuid4())]

        mockala.mock_add_species(old)
        mockala.mock_add_records(old, old_records, datetime.datetime.utcnow())
        all_birds = list(mockala.all_bird_species())
        self.assertEqual(len(all_birds), 1)
        self.assertIs(all_birds[0], old)

        mockala.mock_rename_species(old, new, datetime.datetime.utcnow())
        all_birds = list(mockala.all_bird_species())
        self.assertEqual(len(all_birds), 1)
        self.assertIs(all_birds[0], new)

        new_records = list(mockala.occurrences_for_species(new.lsid))
        self.assertEqual(new_records, old_records)

        self.assertEqual(mockala.num_occurrences_for_lsid(old.lsid), 0)

        self.assertIsNone(mockala.species_for_lsid(old.lsid))
        self.assertIs(mockala.species_for_scientific_name(old.scientific_name), new)

        self.assertIs(mockala.species_for_lsid(new.lsid), new)
        self.assertIs(mockala.species_for_scientific_name(new.scientific_name), new)

    def test_remove_species(self):
        s = mockala.Species('Dodo', 'Dodo dodii', 'dododododod')

        mockala.mock_add_species(s)

        all_species = list(mockala.all_bird_species())
        self.assertTrue(s in all_species)
        self.assertIs(mockala.species_for_lsid(s.lsid), s)

        mockala.mock_remove_species(s)

        all_species = list(mockala.all_bird_species())
        self.assertFalse(s in all_species)
        self.assertIsNone(mockala.species_for_lsid(s.lsid))


if __name__ == '__main__':
    unittest.main()
