import pathfix
import ala

class MockALA(object):

    Occurrence = ala.Occurrence
    Species = ala.Species

    def __init__(self):
        self._all_species = []

    def occurrences_for_species(self, species_lsid, changed_since=None):
        s = self.species_for_lsid(species_lsid)
        if s is None:
            return

        for when in sorted(s.records.iterkeys(), reverse=True):
            if changed_since is not None and when < changed_since:
                break

            for occ in s.records[when]:
                yield occ


    def species_for_lsid(self, species_lsid):
        for s in self._all_species:
            if s.lsid == species_lsid and s.rename is None:
                return s

        return None


    def species_for_scientific_name(self, scientific_name):
        for s in self._all_species:
            if unicode(s.scientific_name) == unicode(scientific_name):
                return self._get_rename(s)

        return None


    def all_bird_species(self):
        for s in self._all_species:
            if s.rename is None:
                yield s


    def num_occurrences_for_lsid(self, lsid):
        s = self.species_for_lsid(lsid)
        if s is None:
            return 0

        num_records = 0
        for records in s.records.itervalues():
            num_records += len(records)

        return num_records


    def mock_add_species(self, species):
        species.records = {}
        species.rename = None
        self._all_species.append(species)


    def mock_add_records(self, species, records, at_date):
        species = self.species_for_lsid(species.lsid)
        assert species is not None
        species.records[at_date] = records


    def mock_rename_species(self, old_species, new_species, when):
        self.mock_add_species(new_species)

        old_species = self.species_for_lsid(old_species.lsid)
        assert old_species is not None
        old_species.rename = new_species

        new_species.records[when] = sum(old_species.records.itervalues(), [])
        old_species.record = None


    def mock_remove_species(self, species):
        self._all_species.remove(species)


    def mock_remove_all_species(self):
        del self._all_species[:]


    def _get_rename(self, species):
        while species.rename is not None:
            species = species.rename

        return species
