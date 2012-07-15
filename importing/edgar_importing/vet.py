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

    log_info('Vetting occurrences')
    num_coords = 0
    for lon, lat, occid in occurrences_for_species_id(species['id']):
        update_occurrence(lon, lat, occid, species['id'], vettings)
        num_coords += 1

    return len(vettings), num_coords


def update_occurrence(lon, lat, occid, species_id, ordered_vettings):
    contention = False
    classification = None
    p = shapely.geometry.Point(lon, lat)

    # for each vetting, ordered most-authoritive first
    for vetting in ordered_vettings:
        # check if the vetting applies to this occurrences' location
        if vetting.area.intersects(p):
            # first, look for classification (if not found previously)
            if classification is None:
                classification = vetting.classification
            # second, look for contention (if not found previously)
            elif classification != vetting.classification:
                contention = True
                # if both classification and contention are found, no need
                # to check the rest of the polygons
                log_info('Contention')
                break

    # only update db if one of the vettings was applied
    if classification is not None:
        db.engine.execute('''
            UPDATE occurrences
            SET contentious = {cont}, classification = '{classi}'
            WHERE id = {occid}
            '''.format(
                cont=('TRUE' if contention else 'FALSE'),
                classi=classification,
                occid=occid
            ))


def ordered_vettings_for_species_id(species_id):
    vettings = []

    query = db.engine.execute('''
        SELECT
            vettings.classification AS classi,
            ST_AsText(ST_SimplifyPreserveTopology(vettings.area, 0.001)) AS area
        FROM vettings INNER JOIN users ON vettings.user_id=users.id
        WHERE vettings.species_id = {sid} AND users.can_vet
        ORDER BY users.authority DESC, vettings.updated_on DESC
        '''.format(sid=int(species_id)))

    for row in query:
        vettings.append(Vetting(row['classi'], row['area']))

    return vettings


def occurrences_for_species_id(species_id):
    query = db.engine.execute('''
        SELECT id, ST_X(location) AS lon, ST_Y(location) AS lat
        FROM occurrences
        WHERE species_id = {sid}
        '''.format(sid=species_id))

    for row in query:
        yield float(row['lon']), float(row['lat']), row['id']


class Vetting(object):
    def __init__(self, classi, wkt_area):
        self.classification = classi
        self.area = shapely.prepared.prep(shapely.wkt.loads(wkt_area))


def log_info(msg, *args, **kwargs):
    logging.info(datetime.datetime.today().strftime('%H:%M:%S: ') + msg, *args,
        **kwargs)
