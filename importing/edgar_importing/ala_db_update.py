#!/usr/bin/env python

import sys
from edgar_importing import db
from edgar_importing import ala
from edgar_importing import sync
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

    return parser.parse_args()


def main():
    args = parse_args()
    with open(args.config[0], 'rb') as f:
        config = json.load(f)

    db.connect(config)

    if 'alaApiKey' in config and config['alaApiKey'] is not None:
        ala.set_api_key(config['alaApiKey'])

    if 'logLevel' in config:
        logging.basicConfig()
        logging.root.setLevel(logging.__dict__[config['logLevel']])

    if 'maxRetrySeconds' in config:
        ala.set_max_retry_secs(float(config['maxRetrySeconds']));

    logging.info("Started at %s", str(datetime.now()))
    try:
        syncer = sync.Syncer(ala)
        syncer.sync(sync_species=config['updateSpecies'],
                    sync_occurrences=config['updateOccurrences'])
    finally:
        logging.info("Ended at %s", str(datetime.now()))


