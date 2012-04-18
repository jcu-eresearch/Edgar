#!/usr/bin/env python

import pathfix
import sys
import db
import sync
import logging
import argparse
import json
import multiprocessing as mp
from datetime import datetime


def parse_args():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description='Synchronises local database with ALA')

    parser.add_argument('config', metavar='config_file', type=str, nargs=1,
            help='''The path to the JSON config file.''')

    return parser.parse_args();


def update(config):
    ala_source = db.sources.select().execute(name='ALA').fetchone()
    from_d = ala_source['last_import_time']
    to_d = datetime.utcnow()
    syncer = sync.Syncer()

    # add new species
    logging.info('Adding new species')
    if config['updateSpecies']:
        added_species, deleted_species = syncer.added_and_deleted_species()
        for species in added_species:
            syncer.add_species(species)

    # update occurrences
    logging.info('Updating occurrence records')
    if config['updateOccurrences']:
        syncer.sync_occurrences(from_d)

        # store last import time in db.sources
        db.sources.update().\
                where(db.sources.c.id == ala_source['id']).\
                values(last_import_time=to_d).\
                execute()

    # delete old species, and species without any occurrences
    logging.info("Deleting species that don't exist any more")
    if config['updateSpecies']:
        for species in deleted_species:
            syncer.delete_species(species)
        for species in syncer.local_species_with_no_occurrences():
            syncer.delete_species(species)


if __name__ == '__main__':
    args = parse_args()
    with open(args.config[0], 'rb') as f:
        config = json.load(f)

    db.connect(config)

    if 'logLevel' in config:
        logging.basicConfig()
        logging.root.setLevel(logging.__dict__[config['logLevel']])


    logging.info("Started at %s", str(datetime.now()))
    try:
        update(config)
    finally:
        logging.info("Ended at %s", str(datetime.now()))


