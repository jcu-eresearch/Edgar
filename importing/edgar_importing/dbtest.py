from cStringIO import StringIO
from edgar_importing import db
from edgar_importing import ala
from time import time
from datetime import timedelta
from geoalchemy import WKTSpatialElement
import uuid
import json
import shapely.geometry
import random
import sqlalchemy

NUM_RECORDS = 4000
LOG_INTERVAL = 1000

class TimeLogger(object):
    def __init__(self, startNow=True):
        self._start = None
        if startNow:
            self.start()

    def __str__(self):
        return self.toStr()

    def toStr(self, things=None):
        if self._start is None:
            return 'Not started'
        else:
            diff = time() - self._start
            base = str(timedelta(seconds=diff))
            if things is not None:
                return base + ' ({0} things/sec)'.format(things/diff)
            else:
                return base

    def start(self):
        self._start = time()

    def log(self, msg, things=None):
        print msg, self.toStr(things)

    def logAndRestart(self, msg, things=None):
        self.log(msg, things)
        self.start()


def upsert_sensitive(occ, occ_id, connection):
        existing = connection.execute(db.sensitive_occurrences.select().\
            where(db.sensitive_occurrences.c.occurrence_id == occ_id)).\
            fetchone()

        p = shapely.geometry.Point(occ.sensitive_coord.longi, occ.sensitive_coord.lati)
        sens_location = WKTSpatialElement(shapely.wkt.dumps(p), 4326)

        if existing is None:
            connection.execute(db.sensitive_occurrences.insert().\
                values(occurrence_id=occ_id,
                       sensitive_location=sens_location))
        else:
            connection.execute(db.sensitive_occurrences.update().\
                values(sensitive_location=sens_location).\
                where(db.sensitive_occurrences.c.occurrence_id == occ_id))


def upsert_nonsensitive(occ, connection):
    existing = connection.execute(db.occurrences.select().\
        where(db.occurrences.c.source_record_id == occ.uuid.bytes).\
        where(db.occurrences.c.source_id == 1))\
        .fetchone()

    p = shapely.geometry.Point(occ.coord.longi, occ.coord.lati)
    location = WKTSpatialElement(shapely.wkt.dumps(p), 4326)

    if existing is None:
        return connection.execute(db.occurrences.insert().\
            returning(db.occurrences.c.id).\
            values(location=location,
                   source_classification='irruptive',
                   classification='irruptive',
                   species_id=1,
                   source_id=1,
                   source_record_id=occ.uuid.bytes))\
            .scalar()
    else:
        return connection.execute(db.occurrences.update().\
            returning(db.occurrences.c.id).\
            values(location=location,
                   source_classification='irruptive',
                   species_id=1).\
            where(db.occurrences.c.id == existing['id']))\
            .scalar()


def upsert_occ(occ, connection=None):
    if occ.coord is not None:
        occ_id = upsert_nonsensitive(occ, connection)
        if occ.sensitive_coord is not None:
            upsert_sensitive(occ, occ_id, connection)
            pass

def postgres_escape_bytea(b):
    strio = StringIO()
    strio.write("E'")

    for ch in b:
        part = oct(ord(ch))
        if len(part) > 3:
            part = part.lstrip('0')
        if len(part) < 3:
            part = part.rjust(3, '0')

        strio.write(r'\\')
        strio.write(part)

    strio.write("'::bytea")
    return strio.getvalue()


def upsert_stored(occ, connection=None):
    sql = '''SELECT EdgarUpsertOccurrence(
        {classi},
        {srid},
        {lat},
        {lon},
        {slat},
        {slon},
        {species_id},
        {source_id},
        {record_id});'''.format(
            classi="'irruptive'",
            srid='4326',
            lat=str(float(occ.coord.lati)),
            lon=str(float(occ.coord.longi)),
            slat=('NULL' if occ.sensitive_coord is None else str(float(occ.sensitive_coord.lati))),
            slon=('NULL' if occ.sensitive_coord is None else str(float(occ.sensitive_coord.longi))),
            species_id='1',
            source_id='1',
            record_id=postgres_escape_bytea(occ.uuid.bytes)
        )

    db.engine.execute(sqlalchemy.text(sql).execution_options(autocommit=True))


def random_coord():
    return ala.Coord(
        lati=random.uniform(-90, 90),
        longi=random.uniform(-180, 180)
    )


def random_occ():
    sens_coord = None
    if random.random() < 0.05:
        sens_coord = random_coord()

    return ala.Occurrence(
        coord=random_coord(),
        sens_coord=sens_coord,
        uuid_in=uuid.uuid4()
    )


def test_without_db():
    t = TimeLogger()
    for i in xrange(NUM_RECORDS):
        random_occ()
        if i > 0 and i % LOG_INTERVAL == 0:
            t.logAndRestart(str(LOG_INTERVAL) + ' records upserted, ' + str(i)
                    + ' total:', LOG_INTERVAL)


def test_with_session():
    t = TimeLogger()
    conn = db.engine.connect()
    trans = conn.begin()
    for i in xrange(NUM_RECORDS):
        upsert_occ(random_occ(), conn)
        if i > 0 and i % LOG_INTERVAL == 0:
            t.logAndRestart(str(LOG_INTERVAL) + ' records upserted, ' + str(i)
                    + ' total:', LOG_INTERVAL)
    trans.commit()
    conn.close()


def test_without_session():
    t = TimeLogger()
    for i in xrange(NUM_RECORDS):
        conn = db.engine.connect()
        upsert_occ(random_occ(), conn)
        conn.close()
        if i > 0 and i % LOG_INTERVAL == 0:
            t.logAndRestart(str(LOG_INTERVAL) + ' records upserted, ' + str(i)
                    + ' total:', LOG_INTERVAL)

def test_stored_procedure():
    t = TimeLogger()
    conn = db.engine.connect()
    trans = conn.begin()
    for i in xrange(NUM_RECORDS):
        upsert_stored(random_occ(), conn)
        if i > 0 and i % LOG_INTERVAL == 0:
            t.logAndRestart(str(LOG_INTERVAL) + ' records upserted, ' + str(i)
                    + ' total:', LOG_INTERVAL)
    trans.commit()
    conn.close()

def init_db():
    db.sensitive_occurrences.delete().execute()
    db.occurrences.delete().execute()
    db.sources.delete().execute()
    db.species.delete().execute()

    db.sources.insert()\
        .values(name='dingle', id=1)\
        .execute()

    db.species.insert()\
        .values(
            scientific_name='Tesycakes McTestii',
            common_name='Test Species',
            id=1
        ).execute()


def main():
    with open('config.unittests.json', 'rb') as f:
        config = json.load(f)

    db.connect(config)

    random.seed()

    tests = [
        test_without_db,
        test_stored_procedure,
        test_with_session,
        test_without_session
    ]

    for test in tests:
        init_db()
        print 'Testing ' + test.__name__ + '='*70

        t = TimeLogger()
        test()
        numrecords = db.engine.execute('select count(*) from occurrences').scalar()
        t.log("Finished {0} records in".format(numrecords), NUM_RECORDS)

    print db.engine.execute('select count(*) from occurrences').scalar()
    db.engine.dispose()
