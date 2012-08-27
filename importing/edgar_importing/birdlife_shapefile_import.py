import csv
import argparse
import json
import logging
import textwrap
from edgar_importing import db
from edgar_importing import ala
from geoalchemy import WKTSpatialElement
import geoalchemy.functions
import sqlalchemy
import shapely.wkt
from shapely.geometry import Polygon, MultiPolygon

# map of BLA categories to db classification enum values
CLASSIFICATIONS_BY_BLA_CATEGORIES = {
    1: 'core',
    2: 'invalid', # aka suspect
    3: 'vagrant',
    4: 'historic',
    5: 'irruptive',
    6: 'introduced',
    7: 'core', # only applies to one species, not 100% sure what classification 7 is
    8: 'vagrant' # aka escaped
}

# global logger for this module
_log = logging.getLogger(__name__)


class Taxon(object):

    def __init__(self, common=None, sci=None):
        self.common_name = common
        self.sci_name = sci
        self.db_id = None
        self.polys_by_classification = {}

    def __repr__(self):
        return '<Taxon db_id="{dbid}" sci="{sci}" common="{common}" />'.format(
                dbid=self.db_id,
                sci=self.sci_name,
                common=self.common_name)

    def _get_sci_name_part(self, idx):
        if self.sci_name is None:
            return None
        parts = self.sci_name.split()
        if len(parts) < 2 or len(parts) > 3:
            raise RuntimeError("Can't split sciname: " + repr(self))
        assert idx < len(parts)
        return parts[idx]

    @property
    def genus(self):
        return self._get_sci_name_part(0)

    @property
    def species(self):
        return self._get_sci_name_part(-1)



def parse_args():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=textwrap.dedent('''
        Loads Birdlife Australia shapefiles into the database as
        vettings.

        The shapefile first needs to be loaded into the database using the
        `shp2pgsql` command provided by PostGIS. Assuming the database is named
        "edgar", and the shapefile is named "TaxonPolys1.shp", the following
        command will load the shapefile into the database:

            shp2pgsql TaxonPolys1.shp birdlife_import | sudo -u postgres psql edgar'''
        ))

    parser.add_argument('config', type=str, help='''The path to the JSON config
        file.''')

    parser.add_argument('csv', type=str, help='''The path the the CSV file,
        which was converted from the TaxonList_May11.xlsx file supplied by Birdlife
        Australia''')

    parser.add_argument('user_id', type=int, help='''The id Birdlife
        Australia user. This user will own the vettings that are added to the
        database.''')

    parser.add_argument('--species_translations', type=str, help='''A CSV that
        translates Birdlife Australia (BLA) species names into names that ALA
        recognises.  First column is the exact BLA species name (from the SpSciName
        column of the other CSV). The second column is the ALA species name. The
        first row of this file will be ignored, so use it for column
        headings.''')

    return parser.parse_args()


def load_taxons_by_spno(csv_path, translations):
    taxons = {}

    with open(csv_path, 'rb') as f:
        reader = csv.DictReader(f)
        for row in reader:
            is_species = (row['TaxonLevel'] == 'sp' and
                len(row['PopCode']) == 0 and
                len(row['SpSciName']) > 0)

            if not is_species:
                continue

            taxon_spno = int(row['SpNo'])
            if taxon_spno in taxons:
                raise RuntimeError('Duplicate SpNo: ' + str(taxon_spno))

            species_name = row['SpSciName']
            if species_name in translations:
                _log.info('Translating species "%s" into "%s"', species_name,
                    translations[species_name])
                species_name = translations[species_name]

            species = ala.species_for_scientific_name(species_name, convert_subspecies=True)
            if species is None:
                _log.warning("Can't find species '%s' at ALA", species_name)
                continue

            taxons[taxon_spno] = Taxon(common=species.common_name,
                                       sci=species.scientific_name)

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
        if genus in db_ids:
            if species in db_ids[genus]:
                t.db_id = db_ids[genus][species]


def classification_for_bla_row(row):
    category = row['rnge']
    assert category in CLASSIFICATIONS_BY_BLA_CATEGORIES
    return CLASSIFICATIONS_BY_BLA_CATEGORIES[category]


def polys_for_spno(spno):
    q = sqlalchemy.select([
        'rnge',
        'brrnge',
        'ST_AsText(the_geom) as the_geom'])\
        .select_from(db.birdlife_import)\
        .where(db.birdlife_import.c.spno == spno)\
        .execute()

    for row in q:
        if row['the_geom'] is None:
            _log.warning('Found row with no geometry: %s', str(dict(row)))
            continue

        poly = shapely.wkt.loads(row['the_geom'])

        if not poly.is_valid:
            poly = poly.buffer(0) # can turn invalid polygons into valid ones
            if not poly.is_valid:
                _log.warning('Found invalid polygon on row: %s', str(dict(row)))
                continue

        # db only accepts multipolygons, but shape can contain both
        # polygons and multipolygons
        if isinstance(poly, Polygon):
            poly = MultiPolygon([poly])

        yield classification_for_bla_row(row), poly


def insert_vettings_for_taxon(taxon, spno, user_id):
    if taxon.db_id is None:
        _log.warning('Skipping species with no db_id: %s', taxon.sci_name)
        return

    num_inserted = 0
    for classification, poly in polys_for_spno(spno):
        q = db.vettings.insert().values(
                user_id=user_id,
                species_id=taxon.db_id,
                comment='Polygons imported from Birdlife Australia',
                classification=classification,
                area=WKTSpatialElement(poly.wkt, 4326)
            ).execute()

        num_inserted += 1

    _log.info('Inserted %d vettings for %s', num_inserted, taxon.sci_name)


def load_translations(csv_path):
    translations = {}

    with open(csv_path, 'rb') as f:
        reader = csv.reader(f)
        reader.next() # skip row of headings
        for row in reader:
            assert len(row) == 2
            translations[row[0].strip()] = row[1].strip()

    return translations


def main():
    logging.basicConfig()
    logging.root.setLevel(logging.INFO)
    args = parse_args()

    # connect to db
    with open(args.config, 'rb') as f:
        db.connect(json.load(f))

    # load translations if present
    translations = {}
    if args.species_translations is not None:
        translations = load_translations(args.species_translations)
        _log.info('Loaded %d species name translations', len(translations))

    # lookup taxons (species) in BLA and local db
    taxons = load_taxons_by_spno(args.csv, translations)
    set_db_id_for_taxons(taxons.itervalues())

    # wipe existing vettings
    db.vettings.delete().where(db.vettings.c.user_id == args.user_id).execute()

    # create new vettings
    for spno, taxon in taxons.iteritems():
        insert_vettings_for_taxon(taxon, spno, args.user_id)
