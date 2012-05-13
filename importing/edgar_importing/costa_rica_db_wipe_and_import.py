#!/usr/bin/python

# Custom import script to process the Costa Rica import csv files.
# NOTE: Will wipe the database before performing import.

from edgar_importing import db
import json
import sys
import csv
from datetime import datetime
import logging.handlers
import re

def main():
    # make sure this isn't run accidentally
    if '--go' not in sys.argv:
        print
        print "Wipes the database clean and fills database with Costa Rica data."
        print
        print "Assumes input csv is called costa_rica_import.csv, and is in the"
        print "same folder as config.json. The folder you're in now.."
        print
        print "Usage:"
        print "\t{0} --go".format(sys.argv[0])
        print
        sys.exit()

    import_file_path = 'costa_rica_import.csv'
    import_threshold_file_path = 'costa_rica_import_threshold.csv'

    log = logging.getLogger()
    log.setLevel(logging.DEBUG)
    log.addHandler(logging.StreamHandler())

    species_count = 0
    occurrences_count = 0

    # take note of import start time
    import_d = datetime.utcnow()

    # connect
    with open('config.json', 'rb') as f:
        db.connect(json.load(f))

    # wipe
    db.species.delete().execute()
    db.sources.delete().execute()
    db.occurrences.delete().execute()

    # insert COSTA_RICA_CSV with last_import_time.
    result = db.sources.insert().execute(
        name='COSTA_RICA_CSV',
        last_import_time=import_d)

    db_source_id = result.lastrowid


    # open threshold csv..
    with open(import_threshold_file_path, 'rb') as tf:
        # open the costa_rica csv..
        with open(import_file_path, 'rb') as f:
            reader = csv.reader(f)
            # skip the header
            header = reader.next()

            # iterate over the csv rows
            for csv_row_array in reader:

                in_collection_code             = csv_row_array.pop(0)
                in_catalog_number              = csv_row_array.pop(0)
                in_occurrence_remarks          = csv_row_array.pop(0)
                in_record_number               = csv_row_array.pop(0)
                in_event_date                  = csv_row_array.pop(0)
                in_location_id                 = csv_row_array.pop(0)
                in_state_province              = csv_row_array.pop(0)
                in_county                     = csv_row_array.pop(0)
                in_municipality               = csv_row_array.pop(0)
                in_locality                   = csv_row_array.pop(0)
                in_decimal_latitude            = csv_row_array.pop(0)
                in_decimal_longitude           = csv_row_array.pop(0)
                in_scientific_name             = csv_row_array.pop(0)
                in_kingdom                    = csv_row_array.pop(0)
                in_phylum                     = csv_row_array.pop(0)
                in_class                      = csv_row_array.pop(0)
                in_order                      = csv_row_array.pop(0)
                in_family                     = csv_row_array.pop(0)
                in_genus                      = csv_row_array.pop(0)
                in_specific_epithet            = csv_row_array.pop(0)
                in_infraspecific_epithet       = csv_row_array.pop(0)
                in_taxon_rank                  = csv_row_array.pop(0)



                # Add species if necessary..

                # Look up species by scientific_name
                row = db.species.select('id')\
                        .where(db.species.c.scientific_name == in_scientific_name)\
                        .execute().fetchone()

                db_species_id = None
                if row is None:
                    # If we couldn't find it..
                    # so add the species

                    tf.seek(0)
                    threshold_reader = csv.reader(tf)

                    in_threshold = 1  # The max (will wipe out all values)
                    for threshold_csv_row_array in threshold_reader:
                        in_species_name = threshold_csv_row_array[0]
                        in_threshold = threshold_csv_row_array[1]
                        # compare species sci_names
                        conv_in_scientific_name = in_scientific_name.strip()
                        conv_in_scientific_name = conv_in_scientific_name.replace('.', '')
                        conv_in_scientific_name = conv_in_scientific_name.replace(' ', '_')
                        #print conv_in_scientific_name
                        #print in_species_name
                        #print '...........'
                        if conv_in_scientific_name == in_species_name:
                            print '************'
                            print in_species_name
                            if in_threshold == 'na':
                                in_threshold = '1'
                            print in_threshold
                            break
                        sys.stdout.flush()

                    result = db.species.insert().execute(
                        scientific_name=in_scientific_name,
                        distribution_threshold=in_threshold,
                    )

                    species_count = species_count + 1

                    db_species_id = result.lastrowid
                else:
                    # We found it, grab the species id
                    db_species_id = row['id']

                # insert the occurrence into the db.
                # NOTE: Some records have empty in_record_numbers.
                # The sql db validates source_id vs source_record_id
                # data, so if we have an empty source_record_id, leave it as unspecified
                # 

                occurrences_count = occurrences_count + 1
                if in_record_number.strip() != '':
                    result = db.occurrences.insert().execute(
                        species_id=db_species_id,
                        latitude=in_decimal_latitude,
                        longitude=in_decimal_longitude,
                        source_id=db_source_id,
                        source_record_id=in_record_number,
                        rating='assumed valid'
                    )
                else:
                    result = db.occurrences.insert().execute(
                        species_id=db_species_id,
                        latitude=in_decimal_latitude,
                        longitude=in_decimal_longitude,
                        source_id=db_source_id,
        #                source_record_id=in_record_number,
                        rating='assumed valid'
                    )



    log.debug("Species: %i", species_count)
    log.debug("Occurrences: %i", occurrences_count)
