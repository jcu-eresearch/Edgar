import re
import os.path
import shapefile
import shapely
import csv
import argparse
import json
import logging
from edgar_importing import db
from shapely.geometry import Polygon, MultiPolygon
from geoalchemy import WKTSpatialElement


# column indexes in shapefile
COL_ID = 0
COL_SPNO = 1
COL_TAXONID = 2
COL_RANGE_T = 3
COL_BR_RNGE_T = 4

# map of BLA categories to db rating enum values
RATINGS_BY_BLA_CATEGORIES = {
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
        self.polys_by_rating = {}

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
        ratings.''')

    parser.add_argument('shapefile', type=str, nargs=1, help='''The path to
        the `.shp` file.''')

    parser.add_argument('csv', type=str, nargs=1, help='''The path the the csv
        file, which was converted from the TaxonList_May11.xlsx file supplied
        by Birdlife Australia''')

    parser.add_argument('config', type=str, nargs=1, help='''The path to the
        JSON config file.''')

    parser.add_argument('user_id', type=int, nargs=1, help='''The id Birdlife
        Australia user. This user will own the ratings that are added to the
        database.''')

    parser.add_argument('srid', type=int, nargs=1, help='''The EPSG-compliant
        SRID of the geometry in the shapefile. The '.prj' file in the shapefile
        directory contains info about this, but you may have to look up the
        SRID manually. Last import, the SRID was 4283 (the '.prj' file said the
        projection was GCS_GDA_1994).''')

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


def poly_from_shapefile_shape(shape):
    # Type 5 is a single polygon in the shapefile format
    assert shape.shapeType == 5

    if len(shape.points) <= 0:
        _log.warning('Shape has no points?')
        return None

    # buffer(0) causes self-intersecting polygons to fix themselves
    # super important, because self-intersecting polygons break everything
    p = Polygon(shape.points).buffer(0)
    if p.is_simple and p.is_valid:
        return p
    else:
        return None


def rating_for_record(rec):
    category = rec[COL_RANGE_T]
    if category == 'core' or category == 'introduced':
        category += ', ' + rec[COL_BR_RNGE_T]

    assert category in RATINGS_BY_BLA_CATEGORIES
    return RATINGS_BY_BLA_CATEGORIES[category]


def update_poly_on_taxon(taxon, record):
    poly = poly_from_shapefile_shape(record.shape)
    if poly is None:
        _log.warning('Invalid polygon on record: %s', repr(record.record))
        return

    rating = rating_for_record(record.record)
    if rating in taxon.polys_by_rating:
        existing = taxon.polys_by_rating[rating]
        taxon.polys_by_rating[rating] = existing.union(poly)
    else:
        taxon.polys_by_rating[rating] = poly


def set_polys_for_taxons(shapef, taxons_by_spno):
    # each row has an extra column as a deletion marker
    assert(len(shapef.fields) == 6)

    for record in shapef.shapeRecords():
        taxon = taxons_by_spno[record.record[COL_SPNO]]
        update_poly_on_taxon(taxon, record)


def insert_ratings_for_taxon(taxon, user_id, srid):
    if taxon.db_id is None:
        _log.warning('Skipping species with no db_id: %s', taxon.sci_name)
        return

    # TODO: make sure the rating polygons don't overlap
    # TODO: load SRID for shapefile (using 4326 temporarily for debugging)

    for rating, poly in taxon.polys_by_rating.iteritems():
        # `poly` can be either a `Polygon` or a `MultiPolygon`
        # postgis expects a `MultiPolygon`, so convert if a `Polygon`
        if isinstance(poly, Polygon):
            poly = MultiPolygon([poly])

        db.ratings.insert().execute(
            user_id=user_id,
            comment='Polygons imported from Birdlife Australia',
            rating=rating,
            area=WKTSpatialElement(shapely.wkt.dumps(poly), srid))


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

    # load shapefiles
    sf = shapefile.Reader(args.shapefile[0])
    set_polys_for_taxons(sf, taxons)

    # wipe existing ratings
    db.ratings.delete().where(db.ratings.c.user_id == args.user_id[0]).execute()

    # create new ratings
    for t in taxons.itervalues():
        insert_ratings_for_taxon(t, args.user_id[0], args.srid[0])
