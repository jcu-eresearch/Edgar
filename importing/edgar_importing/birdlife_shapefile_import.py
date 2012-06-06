import shapefile
import shapely
import csv
import argparse
import json
import logging
from edgar_importing import db

_log = logging.getLogger(__name__)

class Taxon(object):

    def __init__(self, id=None, common=None, sci=None, db_id=None):
        self.id = id
        self.common_name = common
        self.sci_name = sci
        self.db_id = db_id

    def __repr__(self):
        return '<Taxon id="{id}" db_id="{dbid}" sci="{sci}" common="{common}" />'.format(
                id=self.id,
                dbid=self.db_id,
                sci=self.sci_name,
                common=self.common_name)

    def _get_sci_name_part(self, idx):
        if self.sci_name is None:
            return None
        parts = self.sci_name.split()
        if len(parts) != 2:
            raise RuntimeError("Can't split sciname: " + repr(self))
        assert idx < len(parts)
        return parts[idx]

    @property
    def genus(self):
        return self._get_sci_name_part(0)

    @property
    def species(self):
        return self._get_sci_name_part(1)



def parse_args():
    parser = argparse.ArgumentParser(
        description='''Loads Birdlife Australia shapefiles into the database as
        vettings/ratings.''')

    parser.add_argument('shapefile', type=str, nargs=1, help='''The path to
        the `.shp` file.''')

    parser.add_argument('csv', type=str, nargs=1, help='''The path the the csv
        file, which was converted from the TaxonList_May11.xlsx file supplied
        by Birdlife Australia''')

    parser.add_argument('config', type=str, nargs=1, help='''The path to the
        JSON config file.''')

    return parser.parse_args()


def load_taxons_by_id(csv_path):
    taxons = {}

    with open(csv_path, 'rb') as f:
        reader = csv.DictReader(f)
        for row in reader:
            is_species = (row['TaxonLevel'] == 'sp' and
                len(row['PopCode']) == 0 and
                len(row['SpSciName']) > 0)

            if is_species:
                taxon_id = int(row['SpNo'])
                if taxon_id in taxons:
                    raise RuntimeError('Duplicate TaxonID: ' + str(taxon_id))
                taxons[taxon_id] = Taxon(id=taxon_id,
                                         common=row['SpName'],
                                         sci=row['SpSciName'])

    return taxons


def load_db_species_ids_by_genus_and_species():
    ids = {}

    for result in db.species.select().execute():
        parts = result['scientific_name'].split()
        assert 2 <= len(parts) <= 3
        genus = parts[0].encode('utf-8').upper()
        species = parts[-1].encode('utf-8').upper()

        if genus not in ids:
            _log.debug('DB genus: %s', genus)
            ids[genus] = {}

        _log.debug('DB species: %s', species)
        ids[genus][species] = result['id']

    return ids


def set_db_id_for_taxons(taxons):
    db_ids = load_db_species_ids_by_genus_and_species()

    for t in taxons:
        genus = t.genus.upper()
        species = t.species.upper()
        _log.debug('Finding %s %s...', genus, species)
        if genus in db_ids:
            if species in db_ids[genus]:
                t.db_id = db_ids[genus][species]
                _log.debug('\tfound %d', t.db_id)
            else:
                _log.debug('\tspecies missing')
        else:
            _log.debug('\tgenus missing')


def main():
    logging.basicConfig()
    logging.root.setLevel(logging.INFO)
    args = parse_args()

    with open(args.config[0], 'rb') as f:
        db.connect(json.load(f))

    taxons = load_taxons_by_id(args.csv[0])
    set_db_id_for_taxons(taxons.itervalues())

    num_found = len(taxons)
    for t in taxons.itervalues():
        if t.db_id is None:
            num_found -= 1
            _log.info('Species not found in db: %s', repr(t))

    _log.info('Found %d out of %d species in db', num_found, len(taxons))
