#!/usr/bin/env python

import sys
import pathfix
import csv
import string
import ala
import argparse
import textwrap
import logging
import logging.handlers
import time

log = logging.getLogger()


def parse_args():
    args = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description='Writes a CSV of occurrence records to standard output',
        epilog=textwrap.dedent('''\
            Below are some example LSID values, but they are not persistant so
            they may have changed by now.

                Yellow Wagtail - Motacilla flava
                urn:lsid:catalogueoflife.org:taxon:d1d4d6f7-2dc5-11e0-98c6\
-2ce70255a436:col20110201

                Grey Falcon - Falco (Hierofalco) hypoleucos
                urn:lsid:biodiversity.org.au:afd.taxon:b1e0112f-3e9a-41d4-\
a205-1c0800f51306

                Powerful Owl - Ninox (Rhabdoglaux) strenua
                urn:lsid:biodiversity.org.au:afd.taxon:a396b19c-14b1-4b53-\
bd08-6536a53abec9

                Australian Magpie - Cracticus tibicen
                WARNING: 358,037 occurrence records
                urn:lsid:biodiversity.org.au:afd.taxon:b76f8dcf-fabd-4e48\
-939c-fd3cafc1887a
        '''))

    args.add_argument('lsid', metavar='LSID', type=str, nargs=1,
            help='The LSID of the species')

    args.add_argument('--speed-info', action='store_true', dest='speed_info',
            help='''Print speed information to standard error.  Useful for
            finding bottlenecks and such.''')

    args.add_argument('--strategy', type=str, nargs=1,
            choices=['search', 'facet', 'download'], default=['search'],
            help='''Default is 'search'. There are three ways to get occurrence
            records from ALA: 'search' uses the 'occurrences/search' web
            service, which is high on bandwidth (1.5kb per record). 'facet'
            uses the 'occurrences/facet/download' web service, which is low on
            bandwidth but does not contain any record information except the
            lat/long.  'download' uses the 'occurrences/download' web service,
            which is very low on bandwidth (250kb for 30k records) but ALA
            servers can't generate the data fast enough (max download speed is
            about 8kb/s).  This argument will probably be removed once the best
            strategy is clear.''')

    return args.parse_args()


def spp_code_for_species_name(species_name):
    '''Uppercase alpha-only name with length <= 8

    Not sure if this is too restrictive, but Jeremy's example uses
    "GOULFINC" for "Gould Finch"
    '''
    allowed_chars = frozenset(string.ascii_letters + ' ')
    filtered = ''.join([c for c in species_name if c in allowed_chars])
    filtered = filtered.upper()
    parts = filtered.split(' ')
    if len(parts) > 1:
        return parts[0].strip()[:4] + parts[-1].strip()[:4]
    else:
        return filtered.strip()[:8]


def write_csv_for_species_lsid(species_lsid, strategy):
    species = ala.species_for_lsid(species_lsid)
    sppCode = spp_code_for_species_name(species.scientific_name)

    t = time.time()
    num_records = 0
    writer = csv.writer(sys.stdout)
    writer.writerow(['SPPCODE', 'LATDEC', 'LONGDEC'])
    for record in ala.records_for_species(species_lsid, strategy):
        writer.writerow([sppCode, record.latitude, record.longitude])
        num_records += 1
    t = time.time() - t
    log.info('Processed %d total records in %0.2f secs (%0.2f records/sec)',
            num_records, t, float(num_records) / t)


if __name__ == '__main__':
    args = parse_args()
    if args.speed_info:
        log.setLevel(logging.INFO)
        log.addHandler(logging.StreamHandler())
    write_csv_for_species_lsid(args.lsid[0], args.strategy[0])
