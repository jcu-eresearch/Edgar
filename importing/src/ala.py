import time
import re
import math
import urllib
import urllib2
import json
import pdb
import tempfile
import os
import os.path
import csv
import shutil
import zipfile
import time
import logging
import uuid
from datetime import datetime


PAGE_SIZE = 1000  # occurrence records per request
BIE = 'http://bie.ala.org.au/'
BIOCACHE = 'http://biocache.ala.org.au/'

log = logging.getLogger(__name__)


class OccurrenceRecord(object):
    '''Plain old data structure for an occurrence record'''

    def __init__(self):
        self.latitude = None
        self.longitude = None
        self.uuid = None
        self.is_geospatial_kosher = False

    def __repr__(self):
        return '<record uuid="{uuid}" latLong="{lat}, {lng}" />'.format(
            uuid=self.uuid,
            lat=self.latitude,
            lng=self.longitude)


class Species(object):
    '''Plain old data structure for a species'''

    def __init__(self):
        self.common_name = None
        self.scientific_name = None
        self.lsid = None

    def __repr__(self):
        # might be None, or contain wierd unicode
        _asc = lambda s: None if s is None else s.encode('ascii', 'ignore')

        return '<species common="{com}" scientific="{sci}" lsid="{lsid}" />'.\
            format(com=_asc(self.common_name),
                   sci=_asc(self.scientific_name),
                   lsid=self.lsid)


def records_for_species(species_lsid, changed_since=None):
    '''A generator for OccurrenceRecord objects fetched from ALA'''

    q = q_param_for_lsid(species_lsid, changed_since=changed_since)
    url = BIOCACHE + 'ws/occurrences/search'
    params = {
        'q': q,
        'fl': 'id,latitude,longitude,geospatial_kosher',
        'facet': 'off',
    }

    for page in _json_pages(url, params, ('totalRecords',), 'startIndex'):
        for occ in page['occurrences']:
            record = OccurrenceRecord()
            record.latitude = occ['decimalLatitude']
            record.longitude = occ['decimalLongitude']
            record.uuid = uuid.UUID(occ['uuid'])
            record.is_geospatial_kosher = occ['geospatialKosher']
            yield record


def species_for_lsid(species_lsid):
    '''Fetches a Species object by its LSID

    Can return None if no species is found. A species' LSID tends to change
    over time, so watch out for this. Will also return None if the lsid
    is not a species (for example, it might be a genus or subspecies)

    Also, the species common name can be None. Apparently some species don't
    have common names.
    '''

    escaped_lsid = urllib.quote(species_lsid.encode('utf-8'))
    url = BIE + 'species/shortProfile/{0}.json'.format(escaped_lsid)
    info = _fetch_json(create_request(url), check_not_empty=False)
    if not info or len(info) == 0:
        return None

    if info['rank'] == 'species':
        s = Species()
        s.scientific_name = info['scientificName'].strip()
        s.lsid = species_lsid
        if 'commonName' in info:
            s.common_name = info['commonName'].strip()
        return s
    else:
        log.warning('lsid is for "%s", not "species": %s',
                info['rank'], species_lsid)
        return None


def species_for_scientific_name(scientific_name):
    '''Fetches a Species object by its scientific name.

    scientific_name is in the format "genus (subgenus) species" where the
    subgenus is optional. For example "Falco (heirofalco) hypoleucos" or just
    "Falco hypoleucos".

    The Species object returned may not have the same scientific_name as the
    argument passed into this function. This is because species names can
    change and ALA will convert old incorrect names into new correct names.
    '''

    url = BIE + 'ws/guid/' + urllib.quote(scientific_name.encode('utf-8'))
    info = _fetch_json(create_request(url), check_not_empty=False)
    if not info or len(info) == 0:
        return None
    else:
        return species_for_lsid(info[0]['identifier'])


def all_bird_species():
    '''Generator for Species objects'''

    url = BIE + 'search.json'
    params = (('fq', 'speciesGroup:Birds'),
              ('fq', 'rank:species'),
              ('fq', 'idxtype:TAXON'))
    total_key_path = ('searchResults', 'totalRecords')

    for page in _json_pages(url, params, total_key_path, 'start'):
        for result in page['searchResults']['results']:
            s = Species()
            s.lsid = result['guid']
            s.scientific_name = result['nameComplete'].strip()
            if result['commonNameSingle'] is not None:
                s.common_name = result['commonNameSingle'].strip()

            yield s


def num_records_for_lsid(lsid):
    j = _fetch_json(create_request(BIOCACHE + 'ws/occurrences/search', {
            'q': q_param_for_lsid(lsid),
            'facet': 'off',
            'pageSize': 0}))
    return j['totalRecords']


def create_request(url, params=None, use_get=True):
    '''URL encodes params and into a GET or POST request'''
    if params is not None:
        params = urllib.urlencode(params)
        if use_get:
            url += '?' + params
            params = None

    log.debug('Created request for: ' + url)
    return urllib2.Request(url, params)


def q_param_for_lsid(species_lsid, changed_since=None):
    '''The 'q' parameter for ALA web service queries

    `changed_since` allows you to only get records that have changed between a
    certain date range.

    TODO: mark geospatial_kosher:false records as 'assumed invalid'

    TODO: remove occurrences that happened before 1950?
          'occurrence_year:' + _q_date_range(1950_utc_datetime, None)
    '''

    if changed_since is None:
        changed_since = ''
    else:
        daterange = _q_date_range(changed_since, None)
        changed_since = '''
            (last_processed_date:{0} OR last_assertion_date:{0}) AND
            '''.format(daterange)

    return _strip_n_squeeze('''
        lsid:{lsid} AND
        (rank:species OR subspecies_name:[* TO *]) AND
        longitude:[* TO *]
        {changed}
        (
            basis_of_record:HumanObservation OR
            basis_of_record:MachineObservation
        )
        '''.format(lsid=species_lsid, changed=changed_since))


# 10 sec * 2^5 == over 5 minutes of retrying
def _retry(retries=5, delay=10, backoff=2):
    '''A decorator that retries a function or method until it succeeds (success
    is when the function completes and no exception is raised).

    delay sets the initial delay in seconds, and backoff sets the factor by
    which the delay should lengthen after each failure. backoff must be greater
    than 1, or else it isn't really a backoff. retries must be greater than 0, and
    delay greater than 0.'''

    if backoff <= 1:
        raise ValueError('backoff must be greater than 1')

    retries = math.floor(retries)
    if retries < 1:
        raise ValueError('retries must be >= 1')

    if delay <= 0:
        raise ValueError('delay must be >= 0')

    def deco_retry(f):
        def f_retry(*args, **kwargs):
            mtries, mdelay = retries + 1, delay

            while True:
                try:
                    return f(*args, **kwargs)
                except:
                    mtries -= 1
                    if mtries > 0:
                        time.sleep(mdelay)
                        mdelay *= backoff
                    else:
                        raise
        return f_retry
    return deco_retry


@_retry()
def _fetch_json(request, check_not_empty=True):
    '''Fetches and parses the JSON at the given url.

    Returns the object parsed from the JSON, and the size (in bytes) of the
    JSON text that was fetched'''

    start_time = time.time()
    response = urllib2.urlopen(request)
    response_time = time.time()
    response_str = response.read()
    end_time = time.time()

    log.debug('Loaded JSON at %f kb/s. %f before response + %f download time.',
            (len(response_str) / 1024.0) / (end_time - start_time),
            response_time - start_time,
            end_time - response_time)

    return_value = json.loads(response_str)
    if check_not_empty and len(return_value) == 0:
        raise RuntimeError('ALA returned empty response')
    else:
        return return_value


def _q_date_range(from_date, to_date):
    '''Formats a start and end date into a date range string for use in ALA
    queries

    >>> _q_date_range(datetime(2012, 12, 14, 13, 33, 2), None)
    '[2012-12-14T13:33:02Z TO *]'
    '''

    return '[{0} TO {1}]'.format(_q_date(from_date), _q_date(to_date))


def _q_date(d):
    '''Formats a datetime into a string for use in an ALA date range

    The datetime must be naive (without a tzinfo) and represent a UTC time. It
    can also be None, indicating 'any date'.

    >>> _q_date(datetime(2012, 12, 14, 13, 33, 2))
    '2012-12-14T13:33:02Z'
    >>> _q_date(None)
    '*'
    '''

    if d is None:
        return '*'
    else:
        assert d.tzinfo is None
        return d.replace(microsecond=0).isoformat('T') + 'Z'


def _strip_n_squeeze(q):
    r'''Strips and squeezes whitespace. Completely G rated, I'll have you know.

    >>> _strip_n_squeeze('    hello   \n   there my \r\n  \t  friend    \n')
    'hello there my friend'
    '''

    return re.sub(r'[\s]+', r' ', q.strip())


def _json_pages_params_filter(params, offset_key):
    '''Returns filtered_params, page_size

    If 'pageSize' is not present in params, adds it with value = PAGE_SIZE.
    Strips out any offset_key ('startIndex') params. Turns params into a list.

    >>> params = {'q':'query', 'pageSize': 100, 'startIndex': 10}
    >>> _json_pages_params_filter(params, 'startIndex')
    ([('q', 'query'), ('pageSize', 100)], 100)

    >>> params = (('fq', 'filter1'), ('fq', 'filter2'))
    >>> _json_pages_params_filter(params, 'start')
    ([('fq', 'filter1'), ('fq', 'filter2'), ('pageSize', 1000)], 1000)
    '''

    # convert to iterable
    if isinstance(params, dict):
        params = params.iteritems()

    # filter out 'startIndex' and see if 'pageSize' is set
    filtered_params = []
    page_size = None
    for name, value in params:
        if name == offset_key:
            continue
        if name == 'pageSize':
            if page_size is None:
                page_size = value
            else:
                raise RuntimeError('"pageSize" param defined twice (or more)')
        filtered_params.append((name, value))

    # add 'pageSize' if not present
    if page_size is None:
        filtered_params.append(('pageSize', PAGE_SIZE))
        page_size = PAGE_SIZE

    return filtered_params, int(page_size);



def _json_pages(url, params, total_key_path, offset_key):
    assert len(total_key_path) > 0

    params, page_size = _json_pages_params_filter(params, offset_key)

    page_idx = 0
    total_pages = None
    while True:
        params.append((offset_key, page_idx * page_size))
        response = _fetch_json(create_request(url, params))
        yield response


        # calculate total num pages from response (only once)
        if total_pages is None:
            total_results = response
            for key in total_key_path:
                total_results = total_results[key]
            total_pages = math.ceil(float(total_results) / float(page_size))

        page_idx += 1
        if page_idx >= total_pages:
            break
        else:
            params.pop()  # remove offset_key param


if __name__ == "__main__":
    print 'Doctesting...'
    import doctest
    doctest.testmod()
