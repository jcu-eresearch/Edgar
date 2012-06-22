from edgar_importing import db
from edgar_importing import ala
import logging
import argparse
import json
import shapely
from datetime import datetime
from geoalchemy import WKTSpatialElement
import shapely.geometry


def parse_args():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description='''Refetches all sensitive coords from ALA.''')

    parser.add_argument('config', metavar='config_file', type=str, nargs=1,
            help='''The path to the JSON config file.''')

    return parser.parse_args()


def insert_sensitive_coord_on_occ(occ, source_row_id):
    if occ.sensitive_coord is None:
        logging.warning('Record without sensitive coord: %s', str(occ))
        return None

    existing = db.occurrences.select()\
            .where(db.occurrences.c.source_id == source_row_id)\
            .where(db.occurrences.c.source_record_id == occ.uuid.bytes)\
            .execute()\
            .fetchone()

    if existing is None:
        return None

    p = shapely.geometry.Point(occ.sensitive_coord.longi, occ.sensitive_coord.lati)
    sens_location = WKTSpatialElement(shapely.wkt.dumps(p), 4326)

    db.sensitive_occurrences.insert()\
        .values(occurrence_id=existing['id'],
                sensitive_location=sens_location)\
        .execute()

    return existing['species_id']


def update_dirty(num_dirty_by_species):
    dirty_col = db.species.c.num_dirty_occurrences

    for sid, newly_dirty in num_dirty_by_species.iteritems():
        logging.info('Dirtied %d occurrences for species id = %d',
                newly_dirty, sid)

        db.species.update()\
            .values(num_dirty_occurrences=(dirty_col + newly_dirty))\
            .where(db.species.c.id == sid)\
            .execute()


def fetch_sensitive():
    source_row = db.sources.select()\
            .where(db.sources.c.name == 'ALA')\
            .execute()\
            .fetchone()
    if source_row is None:
        raise RuntimeError('Failed to find ALA in sources table')

    logging.info('Deleting all sensitive coords in db')
    db.sensitive_occurrences.delete().execute()

    logging.info('Refetching all sensitive coords')
    num_fetched = 0
    num_dirty_by_species = {}
    for occ in ala.occurrences_for_species(None, sensitive_only=True):
        sid = insert_sensitive_coord_on_occ(occ, source_row['id'])

        if sid is not None:
            if sid in num_dirty_by_species:
                num_dirty_by_species[sid] += 1
            else:
                num_dirty_by_species[sid] = 1

        num_fetched += 1
        if num_fetched % 1000 == 0:
            logging.info('Finished fetching %d sensitive coords at %s',
                    num_fetched, str(datetime.now()))

    update_dirty(num_dirty_by_species)


def main():
    args = parse_args()
    with open(args.config[0], 'rb') as f:
        config = json.load(f)

    db.connect(config)

    if 'alaApiKey' in config and config['alaApiKey'] is not None:
        ala.set_api_key(config['alaApiKey'])
    else:
        print "alaApiKey is missing from: " + args.config[0]
        return

    if 'logLevel' in config:
        logging.basicConfig()
        logging.root.setLevel(logging.__dict__[config['logLevel']])

    if 'maxRetrySeconds' in config:
        ala.set_max_retry_secs(float(config['maxRetrySeconds']));

    logging.info("Started at %s", str(datetime.now()))
    try:
        fetch_sensitive()
    finally:
        logging.info("Ended at %s", str(datetime.now()))



