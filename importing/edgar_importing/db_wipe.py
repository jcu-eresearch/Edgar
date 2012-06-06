#!/usr/bin/python

from edgar_importing import db
import json
import sys

def main():
    # make sure this isn't run accidentally
    if '--go' not in sys.argv:
        print
        print "Wipes the database clean and inserts some debug data."
        print "Don't use this in production!"
        print
        print "Usage:"
        print "\t{0} --go".format(sys.argv[0])
        print
        sys.exit()

    # connect
    with open('config.json', 'rb') as f:
        db.connect(json.load(f))

    # wipe
    db.species.delete().execute()
    db.sources.delete().execute()
    db.occurrences.delete().execute()
    db.sensitive_occurrences.delete().execute()

    # insert species

    # Old name for "cracticus tibicen". 400k records.
    db.species.insert().execute(
        scientific_name='Gymnorhina tibicen',
        common_name='Australian Magpie')

    db.species.insert().execute(
        scientific_name='Motacilla flava',
        common_name='Yellow Wagtail')

    db.species.insert().execute(
        scientific_name='Ninox (Rhabdoglaux) strenua',
        common_name='Powerful Owl')

    db.species.insert().execute(
        scientific_name='Dacelo (Dacelo) leachii',
        common_name='Blue-winged Kookaburra')

    db.species.insert().execute(
        scientific_name='Ninox (Hieracoglaux) connivens',
        common_name='Barking Owl')

    db.species.insert().execute(
        scientific_name='Tyto alba',
        common_name='Barn Owl')

    db.species.insert().execute(
        scientific_name='Tyto (Megastrix) novaehollandiae',
        common_name='Masked Owl')

    db.species.insert().execute(
        scientific_name='Ninox (Ninox) novaeseelandiae',
        common_name='Southern Boobook')

    db.species.insert().execute(
        scientific_name='Corvus tasmanicus',
        common_name='Forest Raven')

    db.species.insert().execute(
        scientific_name='Falco (Hierofalco) hypoleucos',
        common_name='Grey Falcon')

    # 1000 records, of which 79 are sensitive
    db.species.insert().execute(
        scientific_name='Atrichornis (Atrichornis) rufescens',
        common_name='Rufous Scrub-bird')

    # insert ALA source
    db.sources.insert().execute(
        name='ALA',
        last_import_time=None)
