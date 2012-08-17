from edgar_importing import db
import socket
import datetime
import time
import sqlalchemy
import argparse
import logging
import json
import urllib2

def parse_args():
    parser = argparse.ArgumentParser(description='''Sends vettings to ALA
        when they are added, modified, or deleted.''')

    parser.add_argument('config', type=str, help='''The JSON config file''')

    return parser.parse_args()


def main():
    args = parse_args()

    logging.basicConfig()
    logging.root.setLevel(logging.INFO)

    with open(args.config, 'rb') as f:
        config = json.load(f)
        db.connect(config)

    if 'alaVettingSyncUrl' not in config:
        logging.critical('The "alaVettingSyncUrl" must be present in the config')
        return

    while True:
        next_vetting = next_vetting_to_sync()
        if next_vetting is None:
            log_info('=========== No vettings to send. Sleeping for a while.')
            time.sleep(5 * 60)
        else:
            send_vetting(next_vetting, config['alaVettingSyncUrl'])
            db.engine.dispose()
            time.sleep(5)


def next_vetting_to_sync():
    return db.engine.execute('''
        SELECT
            vettings.id as id,
            vettings.created as created,
            vettings.modified as modified,
            vettings.deleted as deleted,
            vettings.ignored as ignored,
            vettings.last_ala_sync as last_ala_sync,
            vettings.comment as comment,
            vettings.classification as classification,
            ST_AsText(vettings.area) as area,
            species.scientific_name as scientific_name,
            users.email as email,
            users.authority as authority,
            users.is_admin as is_admin
        FROM vettings
            INNER JOIN users ON vettings.user_id = users.id
            INNER JOIN species ON vettings.species_id = species.id
        WHERE
            users.email IS NOT NULL AND  -- ignores non-ALA users
            (
                vettings.last_ala_sync IS NULL  -- new vettings
                OR vettings.modified > vettings.last_ala_sync  -- modified vettings
                OR vettings.deleted IS NOT NULL  -- deleted vettings
            )
        LIMIT 1
        ''').fetchone()


def send_vetting(vetting, ala_url):
    log_info('>>>>>>>>>>> Sending vetting %d, by "%s" for species "%s"',
            vetting['id'],
            vetting['email'],
            vetting['scientific_name'])

    # new vettings
    if vetting['last_ala_sync'] is None:
        if send_existing_vetting(vetting, 'new', ala_url):
            update_sync_date_on_vetting(vetting['id'])

    # deleted vettings
    elif vetting['deleted'] is not None:
        if send_deleted_vetting(vetting, ala_url):
            delete_vetting(vetting['id'])

    # modified vettings
    else:
        if send_existing_vetting(vetting, 'modified', ala_url):
            update_sync_date_on_vetting(vetting['id'])


    log_info('<<<<<<<<<<< Finished')


def send_existing_vetting(vetting, status, ala_url):
    log_info('Sending status="%s" message', status)

    lastModified = vetting['modified']
    if lastModified is None:
        lastModified = vetting['created']
    assert lastModified is not None


    if lastModified.microsecond > 0:
        lastModified -= datetime.timedelta(microseconds=lastModified.microsecond)

    return send_json(ala_url, {
        'id': vetting['id'],
        'status': status,
        'lastModified': lastModified.isoformat(),
        'ignored': (False if vetting['ignored'] is None else True),
        'species': vetting['scientific_name'],
        'classification': vetting['classification'],
        'comment': vetting['comment'],
        'user':{
            'email': vetting['email'],
            'authority': vetting['authority'],
            'isAdmin': vetting['is_admin']
            },
        'area': vetting['area']
        })


def send_deleted_vetting(vetting, ala_url):
    log_info('Sending status="deleted" message')

    if vetting['last_ala_sync'] is None:
        # never sent to ALA in the first place, so don't need to send deletion
        # message
        return True

    return send_json(ala_url, {
        'id': vetting['id'],
        'status': 'deleted',
        'lastModified': vetting['deleted'].isoformat()
        })


def send_json(ala_url, json_object):
    assert ala_url is not None
    assert 'id' in json_object
    assert 'status' in json_object
    assert 'lastModified' in json_object

    request = urllib2.Request(ala_url, json.dumps(json_object), {
        'Content-Type': 'application/json',
        'User-Agent': 'Edgar/Python-urllib2'
        })

    try:
        response = urllib2.urlopen(request, timeout=20.0)
        return response.getcode() == 200
    except urllib2.HTTPError as e:
        logging.warning('Failed to send vetting. HTTP response code = %d', e.code)
    except Exception as e:
        logging.warning('Failed to send vetting due to exception: %s', str(e))

    return False


def delete_vetting(vetting_id):
    log_info('Deleting vetting from local database')

    db.vettings.delete().where(db.vettings.c.id == vetting_id).execute()


def update_sync_date_on_vetting(vetting_id):
    log_info('Updating last_ala_sync for vetting')

    db.engine.execute('''
        UPDATE vettings
        SET last_ala_sync = NOW()
        WHERE id = {vid};
        '''.format(vid=int(vetting_id)))


def log_info(msg, *args, **kwargs):
    logging.info(datetime.datetime.today().strftime('%H:%M:%S: ') + msg, *args,
        **kwargs)
