import csv
import argparse
import json
import logging
from edgar_importing import db
from geoalchemy import WKTSpatialElement
import geoalchemy.functions

# map of BLA categories to db classification enum values
CLASSIFICATIONS_BY_BLA_CATEGORIES = {
        'irruptive': 'irruptive',
        'vagrant': 'vagrant',
        'escaped': 'vagrant',
        'historic': 'historic',
        'suspect': 'invalid',
        'introduced, breeding and non-breeding': 'introduced breeding',
        'introduced, breeding': 'introduced breeding',
        'introduced, non-breeding': 'introduced non-breeding',
        'core, breeding and non-breeding': 'breeding',
        'core, breeding': 'breeding',
        'core, non-breeding': 'non-breeding'
}

# global logger for this module
_log = logging.getLogger(__name__)


class Taxon(object):

    def __init__(self, spno=None, common=None, sci=None):
        self.spno = spno
        self.common_name = common
        self.sci_name = sci
        self.db_id = None
        self.polys_by_classification = {}

    def __repr__(self):
        return '<Taxon spno="{spno}" db_id="{dbid}" sci="{sci}" common="{common}" />'.format(
                spno=self.spno,
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
        vettings.''')

    parser.add_argument('csv', type=str, nargs=1, help='''The path the the csv
        file, which was converted from the TaxonList_May11.xlsx file supplied
        by Birdlife Australia''')

    parser.add_argument('config', type=str, nargs=1, help='''The path to the
        JSON config file.''')

    parser.add_argument('user_id', type=int, nargs=1, help='''The id Birdlife
        Australia user. This user will own the vettings that are added to the
        database.''')

    return parser.parse_args()


def load_taxons_by_spno(csv_path):
    taxons = {}

    with open(csv_path, 'rb') as f:
        reader = csv.DictReader(f)
        for row in reader:
            is_species = (row['TaxonLevel'] == 'sp' and
                len(row['PopCode']) == 0 and
                len(row['SpSciName']) > 0)

            if is_species:
                taxon_spno = int(row['SpNo'])
                if taxon_spno in taxons:
                    raise RuntimeError('Duplicate SpNo: ' + str(taxon_spno))
                taxons[taxon_spno] = Taxon(spno=taxon_spno,
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


def classification_for_bla_row(row):
    category = row['range_t']
    if category == 'core' or category == 'introduced':
        category += ', ' + rec['br_rnge_t']

    assert category in CLASSIFICATIONS_BY_BLA_CATEGORIES
    return CLASSIFICATIONS_BY_BLA_CATEGORIES[category]


def polys_for_taxon(taxon):
    q = db.birdlife_import.select()\
        .where(db.birdlife_import.c.spno == taxon.spno)\
        .execute()

    for row in q:
        print str(dict(row))
        yield classification_for_bla_row(row), row['the_geom']


def insert_vettings_for_taxon(taxon, user_id):
    if taxon.db_id is None:
        _log.warning('Skipping species with no db_id: %s', taxon.sci_name)
        return

    num_inserted = 0
    for classification, poly in polys_for_taxon(taxon):
        q = db.vettings.insert().values(
                user_id=user_id,
                species_id=taxon.db_id,
                comment='Polygons imported from Birdlife Australia',
                classification=classification,
                area=poly
            ).execute()

        num_inserted += 1

    _log.info('Inserted %d vettings for %s', num_inserted, taxon.sci_name)


def main():
    logging.basicConfig()
    logging.root.setLevel(logging.INFO)
    args = parse_args()

    # connect to db
    with open(args.config[0], 'rb') as f:
        db.connect(json.load(f))

    # lookup taxons (species) in BLA and local db
    taxons = load_taxons_by_spno(args.csv[0])
    set_db_id_for_taxons(taxons.itervalues())

    # wipe existing vettings
    db.vettings.delete().where(db.vettings.c.user_id == args.user_id[0]).execute()

    # create new vettings
    for t in taxons.itervalues():
        insert_vettings_for_taxon(t, args.user_id[0])
