from edgar_importing import db
import csv
import sys
import json
import uuid


def startup():
    with open(sys.argv[1]) as f:
        config = json.load(f)

    db.connect(config)


def exp():
    startup()

    output = csv.writer(sys.stdout)
    for occ in db.occurrences.select().execute():
        if occ['basis'] is not None:
            recid = str(uuid.UUID(bytes=occ['source_record_id']))
            output.writerow([recid, occ['basis']])


def imp():
    startup()

    num_rows = 0
    input_data = csv.reader(sys.stdin)
    for uuid_str, basis_in in input_data:
        num_rows += 1
        if num_rows % 1000 == 0:
            print 'Finished ' + str(num_rows) + ' occurrences'
            print uuid_str, basis

        recid = uuid.UUID(uuid_str)
        db.occurrences.update()\
            .values(basis=basis_in)\
            .where(db.occurrences.c.source_record_id == recid.bytes)\
            .execute()
