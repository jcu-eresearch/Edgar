from edgar_importing import db
import sqlalchemy
import argparse
import logging
import json
import time
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

    return parser.parse_args()


def main():
    args = parse_args()

    logging.basicConfig()
    logging.root.setLevel(logging.INFO)

    with open(args.config, 'rb') as f:
        db.connect(json.load(f))

    while True:
        next_species = next_species_row_to_vet()
        if next_species is None:
            log_info('=========== No species need vetting. Sleeping for a while.')
            time.sleep(60)
        else:
            vet_species(next_species)
            db.engine.dispose()


def next_species_row_to_vet():
    return db.engine.execute('''
        SELECT * FROM species
        WHERE needs_vetting_since IS NOT NULL
        ORDER BY needs_vetting_since ASC
        LIMIT 1
        ''').fetchone()


def vet_species(species):
    log_info('>>>>>>>>>>> Started vetting species %d: %s',
            species['id'], species['scientific_name'])

    connection = db.engine.connect()
    transaction = connection.begin()
    try:
        vet_species_inner(species, connection)
        log_info('Committing transaction')
        transaction.commit()
    except:
        logging.warning('Performing rollback due to exception',)
        transaction.rollback()
        raise
    finally:
        connection.close()
        log_info('<<<<<<<<<<< Finished')


def vet_species_inner(species, connection):

    vettings = ordered_vettings_for_species_id(species['id'], connection)

    query = occurrences_for_species_id(species['id'], connection)
    log_info('Vetting %d occurrences through %d vettings', query.rowcount,
            len(vettings))

    rows_remaining = query.rowcount
    rows_changed = 0
    rows_contentious = 0
    for occrow in query:
        changed, contentious = update_occurrence(occrow, vettings, connection)
        if changed: rows_changed += 1
        if contentious: rows_contentious += 1

        rows_remaining -= 1
        if rows_remaining % 10000 == 0 and rows_remaining > 0:
            log_info('%d occurrences remaining', rows_remaining)

    log_info('Dirtied %d occurrences in total', rows_changed)

    connection.execute('''
        UPDATE species
        SET num_dirty_occurrences = num_dirty_occurrences + {changed},
            needs_vetting_since = NULL,
            num_contentious_occurrences = {cont}
        WHERE id = {sid};
        '''.format(
            changed=rows_changed,
            cont=rows_contentious,
            sid=species['id']
        ))


def update_occurrence(occrow, ordered_vettings, connection):
    contentious = False
    classification = None
    location = shapely.wkt.loads(occrow['location'])

    # for each vetting, ordered most-authoritive first
    for vetting in ordered_vettings:
        # check if the vetting applies to this occurrences' location
        if vetting.area.intersects(location):
            # first, look for classification (if not found previously)
            if classification is None:
                classification = vetting.classification
                # if this is an admin vetting, don't check the other vettings.
                # this will keep `contention=False` for all occurrences within
                # vettings by admins
                if vetting.is_by_admin:
                    break
            # second, look for contention (if not found previously)
            elif classification != vetting.classification:
                contentious = True
                # if both classification and contention are found, no need
                # to check the rest of the polygons
                break

    # if no vettings affect this occurrence, use source_classification
    if classification is None:
        classification = occrow['source_classification']

    # only update db if something changed
    if classification != occrow['classification'] or contentious != occrow['contentious']:
        connection.execute('''
            UPDATE occurrences
            SET contentious = {cont},
                classification = '{classi}'
            WHERE id = {occid}
            '''.format(
                cont=('TRUE' if contentious else 'FALSE'),
                classi=classification,
                occid=occrow['id']
            ))
        return True, contentious
    else:
        return False, contentious


def ordered_vettings_for_species_id(species_id, connection):
    vettings = []

    query = connection.execute('''
        SELECT
            vettings.classification AS classi,
            ST_AsText(ST_SimplifyPreserveTopology(vettings.area, 0.001)) AS area,
            users.is_admin as is_admin
        FROM
            vettings INNER JOIN users ON vettings.user_id = users.id
        WHERE
            vettings.species_id = {sid}
            AND vettings.ignored IS NULL
            AND users.can_vet
        ORDER BY
            users.is_admin DESC,
            users.authority DESC,
            vettings.modified DESC
        '''.format(sid=int(species_id)))

    for row in query:
        vettings.append(Vetting(row['classi'], row['area'], row['is_admin']))

    return vettings


def occurrences_for_species_id(species_id, connection):
    return connection.execute('''
        SELECT
            id,
            classification,
            source_classification,
            contentious,
            ST_AsText(location) AS location
        FROM occurrences
        WHERE species_id = {sid}
        '''.format(sid=species_id))


class Vetting(object):
    def __init__(self, classi, wkt_area, is_by_admin):
        self.classification = classi
        self.area = shapely.prepared.prep(shapely.wkt.loads(wkt_area))
        self.is_by_admin = is_by_admin


def log_info(msg, *args, **kwargs):
    logging.info(datetime.datetime.today().strftime('%H:%M:%S: ') + msg, *args,
        **kwargs)
