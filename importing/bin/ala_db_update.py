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

    parser.add_argument('--dont-update-species', action='store_true',
        dest='dont_update_species', help='''Doesn't update the species table of
        the database. Use if you only want to update the occurrences table.''')

    parser.add_argument('--dont-update-occurrences', action='store_true',
        dest='dont_update_occurrences', help='''If this flag is set, doesn't do
        anything to the occurrences table. Useful if you only want to update
        the species table.''')

    parser.add_argument('--log-level', type=str, nargs=1,
            choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
            default=['INFO'], help='''Determines how much info is printed.''')

    parser.add_argument('config', metavar='config_file', type=str, nargs=1,
            help='''The path to the JSON config file.''')

    return parser.parse_args();


def update(args):
    ala_source = db.sources.select().execute(name='ALA').fetchone()
    from_d = ala_source['last_import_time']
    to_d = datetime.utcnow()
    syncer = sync.Syncer()

    # add new species
    if not args.dont_update_species:
        added_species, deleted_species = syncer.added_and_deleted_species()
        for species in added_species:
            syncer.add_species(species)

    # update occurrences
    if not args.dont_update_occurrences:
        # insert/update (upsert) all changed occurrences
        for occurrence in syncer.occurrences_changed_since(from_d):
            syncer.upsert_occurrence(occurrence, occurrence.species_id)
        syncer.flush_upserts()

        if syncer.check_occurrence_counts():
            # store last import time in db.sources
            db.sources.update().\
                    where(db.sources.c.id == ala_source['id']).\
                    values(last_import_time=to_d).\
                    execute()

    # delete old species, and species without any occurrences
    if not args.dont_update_species:
        for species in deleted_species:
            syncer.deleted_species(species)
        for species in syncer.local_species_with_no_occurrences():
            syncer.delete_species(species)



if __name__ == '__main__':
    args = parse_args()

    logging.basicConfig()
    logging.root.setLevel(logging.__dict__[args.log_level[0]])

    with open(args.config[0], 'rb') as f:
        db.connect(json.load(f))

    logging.info("Started at %s", str(datetime.now()))
    try:
        update(args)
    finally:
        logging.info("Ended at %s", str(datetime.now()))


