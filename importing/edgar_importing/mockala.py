from datetime import datetime
from edgar_importing import ala
from copy import deepcopy

class MockALA(object):

    Coord = ala.Coord
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
        species = deepcopy(species)
        species.records = {}
        species.rename = None
        self._all_species.append(species)
        return species


    def mock_add_records(self, species, records, at_date=None):
        species = self.species_for_lsid(species.lsid)
        assert species is not None

        if at_date is None:
            at_date = datetime.utcnow()

        species.records[at_date] = deepcopy(records)


    def mock_remove_records(self, species, records_to_remove):
        species = self.species_for_lsid(species.lsid)
        uuids_to_remove = frozenset([r.uuid for r in records_to_remove])

        for species_records in species.records.itervalues():
            for r in species_records[:]:
                if r.uuid in uuids_to_remove:
                    species_records.remove(r)


    def mock_update_record(self, old_species, record, at_date=None,
            new_species=None):

        if new_species is None:
            new_species = old_species

        if at_date is None:
            at_date = datetime.utcnow()

        old_species = self.species_for_lsid(old_species.lsid)
        new_species = self.species_for_lsid(new_species.lsid)

        for records in old_species.records.itervalues():
            for r in records:
                if r.uuid == record.uuid:
                    records.remove(r)
                    break

        if at_date in new_species.records:
            new_species.records[at_date].append(deepcopy(record))
        else:
            new_species.records[at_date] = [deepcopy(record)]


    def mock_rename_species(self, old_species, new_species, when):
        new_species = self.mock_add_species(new_species)

        old_species = self.species_for_lsid(old_species.lsid)
        assert old_species is not None
        old_species.rename = new_species

        new_species.records[when] = sum(old_species.records.itervalues(), [])
        old_species.record = None


    def mock_remove_species(self, species):
        self._all_species.remove(species)


    def _get_rename(self, species):
        while species.rename is not None:
            species = species.rename

        return species
