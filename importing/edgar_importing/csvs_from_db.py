import json
import csv
import argparse
import logging
import sqlalchemy
from edgar_importing import db


def parse_args():
    parser = argparse.ArgumentParser(description='''Makes one CSV per species
        in the current directory from data in the database, for Jeremy.''')

    parser.add_argument('config', metavar='config_file', type=str, nargs=1,
            help='''The path to the JSON config file.''')

    return parser.parse_args()


def rows_for_species_id(species_id):
    q = sqlalchemy.select([
        'ST_X(location) as longitude',
        'ST_Y(location) as latitude',
        'ST_X(sensitive_location) as sensitive_longitude',
        'ST_Y(sensitive_location) as sensitive_latitude',
        'uncertainty',
        'date']).\
        select_from(db.occurrences.outerjoin(db.sensitive_occurrences)).\
        where(db.occurrences.c.species_id == species_id).\
        where(sqlalchemy.or_(
            db.occurrences.c.classification >= 'irruptive',
            db.occurrences.c.classification == 'unknown'
        )).execute()

    for row in q:
        row = dict(row)
        row['date'] = '' if row['date'] is None else row['date'].isoformat()
        if row['sensitive_longitude'] is not None:
            row['longitude'] = row['sensitive_longitude']
            row['latitude'] = row['sensitive_latitude']
        yield row


def write_csv_for_species(species):
    writer = None
    f = None
    num_records = 0

    for row in rows_for_species_id(species['id']):
        # lazy open file, incase this species has 0 records
        if writer is None:
            f = open(species['scientific_name'] + '.csv', 'wb')
            writer = csv.writer(f)
            writer.writerow(["SPPCODE", "LATDEC", "LONGDEC", "UNCERTAINTY", "DATE"])

        writer.writerow((species['id'],
                         row['latitude'],
                         row['longitude'],
                         row['uncertainty'],
                         row['date']))
        num_records += 1

    if f is not None:
        logging.info('Wrote %d records for species %s', num_records, species['scientific_name'])
        f.close()


def main():
    args = parse_args()
    with open(args.config[0], 'rb') as f:
        config = json.load(f)

    db.connect(config)

    if 'logLevel' in config:
        logging.basicConfig()
        logging.root.setLevel(logging.__dict__[config['logLevel']])

    for row in db.species.select().execute():
        write_csv_for_species(row)
