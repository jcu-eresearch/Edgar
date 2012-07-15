from edgar_importing import db
import sqlalchemy
import argparse
import logging
import json
import datetime
import shapely
import shapely.prepared
import shapely.wkt
import shapely.geometry
from pprint import pprint

# 3 digits means the size of each grid cell is 0.001
GRID_DIGITS = 3
GRID_SIZE = float(10.0 ** -GRID_DIGITS)
FLOAT_FMT = '%0.' + str(GRID_DIGITS) + 'f'


def parse_args():
    parser = argparse.ArgumentParser(description='''Recalculates occurrence
        record classifications based on vettings''')

    parser.add_argument('config', type=str, help='''The JSON config file''')

    parser.add_argument('species_id', type=int, help='''The id of the species
        to recalculate vettings for''')

    return parser.parse_args()


def main():
    args = parse_args()

    logging.basicConfig()
    logging.root.setLevel(logging.INFO)

    with open(args.config, 'rb') as f:
        db.connect(json.load(f))

    log_info('Starting');
    num_vettings, num_coords = None, None
    try:
        num_vettings, num_coords = vet_species(args)
    finally:
        log_info('Finished running %s coords through %s vettings', num_coords,
            num_vettings);


def vet_species(args):
    species = db.species.select()\
        .where(db.species.c.id == args.species_id)\
        .execute()\
        .fetchone()

    log_info('Resetting classifications to source classifications')
    # TODO: uncomment this when done
    #db.occurrences.update()\
        #.values(classification=db.occurrences.c.source_classification)\
        #.execute()

    log_info('Loading all vettings')
    vettings = ordered_vettings_for_species_id(species['id'])

    log_info('Vetting grid cells')
    num_coords = 0
    for lon, lat in unique_gridded_coords_for_species_id(species['id']):
        update_occurrences_in_grid_cell(lon, lat, species['id'], vettings)
        num_coords += 1

    return len(vettings), num_coords


def update_occurrences_in_grid_cell(lon, lat, species_id, ordered_vettings):
    contention = False
    classification = None
    cell_center = shapely.geometry.Point(lon + GRID_SIZE/2.0, lat + GRID_SIZE/2.0)

    # for each vetting, ordered most-authoritive first
    for vetting in ordered_vettings:
        # check if the vetting applies to this grid cell
        if vetting.area.intersects(cell_center):
            # first, look for classification (if not found previously)
            if classification is None:
                classification = vetting.classification
            # second, look for contention (if not found previously)
            elif classification != vetting.classification:
                contention = True
                # if both classification and contention are found, no need
                # to check the rest of the polygons
                break

    # only update db if one of the vettings was applied
    if classification is not None:
        db.engine.execute('''
            UPDATE occurrences
            SET contentious = {cont}, classification = '{classi}'
            WHERE species_id = {sid}
                AND location && {box}
            '''.format(
                cont=('TRUE' if contention else 'FALSE'),
                classi=classification,
                sid=int(species_id),
                box=make_box2d_for_grid_cell(lon, lat)
            ))


def ordered_vettings_for_species_id(species_id):
    vettings = []

    query = db.engine.execute('''
        SELECT
            vettings.classification AS classi,
            ST_AsText(ST_SimplifyPreserveTopology(vettings.area, {acc})) AS area
        FROM vettings INNER JOIN users ON vettings.user_id=users.id
        WHERE vettings.species_id = {sid} AND users.can_vet
        ORDER BY users.authority DESC, vettings.updated_on DESC
        '''.format(
            sid=int(species_id),
            acc=GRID_SIZE
        ))

    for row in query:
        vettings.append(Vetting(row['classi'], row['area']))

    return vettings


def unique_gridded_coords_for_species_id(species_id):
    query = db.engine.execute('''
        SELECT DISTINCT
            TRUNC(ST_X(location)::numeric, {truncd}) AS lon,
            TRUNC(ST_Y(location)::numeric, {truncd}) AS lat
        FROM occurrences
        WHERE species_id = {sid}
        '''.format(
            truncd=GRID_DIGITS,
            sid=species_id
        ))

    for row in query:
        yield float(row['lon']), float(row['lat'])


def get_grid_bounds_for_dimension(dimension):
    '''Returns (min_bounds, max_bounds). Bounds are based on the truncation of
    the dimension. Negative numbers become more negative, and the bounds around
    0.0 are twice the size of the rest (can't tell if a positive or negative
    number was truncated).'''
    if dimension > 0:
        return dimension, dimension + GRID_SIZE
    elif dimension < 0:
        return dimension - GRID_SIZE, dimension
    else:
        return -GRID_SIZE, GRID_SIZE


def make_box2d_for_grid_cell(lon, lat):
    lonmin, lonmax = get_grid_bounds_for_dimension(lon)
    latmin, latmax = get_grid_bounds_for_dimension(lat)

    return "ST_SetSRID('BOX({lonmin} {latmin},{lonmax} {latmax})'::box2d,4326)".format(
        lonmin=(FLOAT_FMT % lonmin),
        latmin=(FLOAT_FMT % latmin),
        lonmax=(FLOAT_FMT % lonmax),
        latmax=(FLOAT_FMT % latmax))


class Vetting(object):
    def __init__(self, classi, wkt_area):
        self.classification = classi
        self.area = shapely.prepared.prep(shapely.wkt.loads(wkt_area))


def log_info(msg, *args, **kwargs):
    logging.info(datetime.datetime.today().strftime('%H:%M:%S: ') + msg, *args,
        **kwargs)
