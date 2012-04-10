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

    parser.add_argument('--dont-add-species', action='store_true',
        dest='dont_add_species', help='''If new species are found in the ALA
        data, then don't add them to the database.''')

    parser.add_argument('--dont-delete-species', action='store_true',
        dest='dont_delete_species', help='''If species in the local database are
        not present in the ALA data, don't delete them. Species can be removed
        from ALA when they are merged into another existing species, or if
        their scientific name changes.''')

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


def update_species(syncer, add_new=True, delete_old=True):
    '''Updates the species table in the database

    Checks ALA for new species, and species that have been deleted (e.g. merged
    into another existing species).
    '''
    if not add_new and not delete_old:
        return

    added, deleted = syncer.added_and_deleted_species()

    if delete_old:
        for row in deleted:
            syncer.delete_species(row)

    if add_new:
        for species in added:
            syncer.add_species(species)


def update_occurrences(syncer, from_d, to_d, ala_source_id):
    '''Updates the occurrences table of the db with data from ALA '''

    for occurrence in syncer.occurrences_changed_since(from_d):
        syncer.upsert_occurrence(occurrence, occurrence.species_id)

    syncer.flush_upserts()


def update():
    ala_source = db.sources.select().execute(name='ALA').fetchone()
    from_d = ala_source['last_import_time']
    to_d = datetime.utcnow()
    syncer = sync.Syncer()

    update_species(syncer, not args.dont_add_species, not args.dont_delete_species)

    if not args.dont_update_occurrences:
        update_occurrences(syncer, from_d, to_d, ala_source['id'])
        # only set the last_import_time if records were updated
        db.sources.update().\
                where(db.sources.c.id == ala_source['id']).\
                values(last_import_time=to_d).\
                execute()


if __name__ == '__main__':
    args = parse_args()

    logging.basicConfig()
    logging.root.setLevel(logging.__dict__[args.log_level[0]])

    with open(args.config[0], 'rb') as f:
        db.connect(json.load(f))

    logging.info("Started at %s", str(datetime.now()))
    try:
        update()
    finally:
        logging.info("Ended at %s", str(datetime.now()))


