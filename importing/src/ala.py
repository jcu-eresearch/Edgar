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

#occurrence records per request for 'search' strategy
PAGE_SIZE = 1000
BIE = 'http://bie.ala.org.au/'
BIOCACHE = 'http://biocache.ala.org.au/'


log = logging.getLogger(__name__)


class OccurrenceRecord(object):
    '''Plain old data structure for an occurrence record'''

    def __init__(self):
        self.latitude = None
        self.longitude = None
        self.uuid = None

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


def records_for_species(species_lsid, strategy, changed_since=None,
        unchanged_since=None):
    '''A generator for OccurrenceRecord objects fetched from ALA'''

    q = q_param_for_lsid(
            species_lsid,
            changed_since=changed_since,
            unchanged_since=unchanged_since)

    if strategy == 'search':
        return _search_records_for_species(q)
    elif strategy == 'download':
        return _downloadzip_records_for_species(q)
    elif strategy == 'facet':
        return _facet_records_for_species(q)
    else:
        raise ValueError('Invalid strategy: ' + strategy)


def species_for_lsid(species_lsid):
    '''Fetches a Species object by its LSID

    Can return None if no species is found. A species' LSID tends to change
    over time, so watch out for this. Will also return None if the lsid
    is not a species (for example, it might be a genus or subspecies)

    Also, the species common name can be None. Apparently some species don't
    have common names.
    '''

    escaped_lsid = urllib.quote(species_lsid)
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

    # the web service behaviour changed (frowny face). Might need a to use
    # a different web service that acceps the genus/species separately instead
    # of as one string. The fix for now is just stripping the parenthesis off
    # the subgenus
    scientific_name = scientific_name.replace('(', '');
    scientific_name = scientific_name.replace(')', '');

    url = BIE + 'ws/guid/' + urllib.quote(scientific_name)
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


def q_param_for_lsid(species_lsid, kosher_only=True, changed_since=None,
        unchanged_since=None):
    '''The 'q' parameter for ALA web service queries

    `changed_since` and `unchanged_since` allow you to only get records that
    have changed between a certain date range, for example:

        now = datetime.datetime.now()
        yesterday = ...
        q_param_for_lsid(..., changed_since=yesterday, unchanged_since=now)

    The `unchanged_since` parameter is specified in case records are changed
    during the query, in which case they may not be present. If that happens,
    then you can get the newly changed records the next time:

       old_now = now
       now = datetime.datetime.now()
       q_param_for_lsid(..., changed_since=old_now, unchanged_since=now)

    Maybe use a list of specific assertions instead of geospatial_kosher.

    Fields possibly useful in incremental updates:
        modified_date
        last_processed_date
        first_loaded_date
        last_load_date
        last_assertion_date

    TODO: remove occurrences that happened before 1950?
    '''

    kosher = ''
    if kosher_only:
        kosher = 'geospatial_kosher:true AND'

    changed_between = ''
    if changed_since is not None or unchanged_since is not None:
        daterange = _q_date_range(changed_since, unchanged_since)
        changed_between = 'last_processed_date:' + daterange + ' AND'

    return _strip_n_squeeze('''
        lsid:{lsid} AND
        (rank:species OR subspecies_name:[* TO *])
        {kosher}
        {changed}
        (
            basis_of_record:HumanObservation OR
            basis_of_record:MachineObservation
        )
        '''.format(lsid=species_lsid, kosher=kosher, changed=changed_between))


def _retry(tries=3, delay=2, backoff=2):
    '''A decorator that retries a function or method until it succeeds (success
    is when the function completes and no exception is raised).

    delay sets the initial delay in seconds, and backoff sets the factor by
    which the delay should lengthen after each failure. backoff must be greater
    than 1, or else it isn't really a backoff. tries must be at least 1, and
    delay greater than 0.'''

    if backoff <= 1:
        raise ValueError('backoff must be greater than 1')

    tries = math.floor(tries)
    if tries < 1:
        raise ValueError('tries must be >= 1')

    if delay <= 0:
        raise ValueError('delay must be >= 0')

    def deco_retry(f):
        def f_retry(*args, **kwargs):
            mtries, mdelay = tries, delay

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


@_retry()
def _fetch(request):
    '''Opens the url and returns the result of urllib2.urlopen'''
    return urllib2.urlopen(request)


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


def _chunked_read_and_write(infile, outfile):
    '''Reads from infile and writes to outfile in chunks, while logging speed
    info'''

    chunk_size = 4096
    report_interval = 5.0
    last_report_time = time.time()
    bytes_read = 0
    bytes_read_this_interval = 0

    while True:
        chunk = infile.read(chunk_size)
        if len(chunk) > 0:
            outfile.write(chunk)
            bytes_read += len(chunk)
            bytes_read_this_interval += len(chunk)
        else:
            break

        now = time.time()
        if now - last_report_time > report_interval:
            kbdown = float(bytes_read_this_interval) / 1024.0
            log.info('Read %0.0fkb total (at about %0.2f kb/s)',
                    float(bytes_read) / 1024.0,
                     kbdown / (now - last_report_time))
            last_report_time = now
            bytes_read_this_interval = 0


def _downloadzip_records_for_species(q):
    '''This strategy is too slow. The requested file size is small, but ALA
    can't generate the file fast enough so the download speed won't go above
    8kb/s'''

    file_name = 'data'

    #need to write zip file to a temp file
    log.info('Requesting zip file from ALA...')
    t = time.time()
    response = _fetch(create_request(
        BIOCACHE + 'ws/occurrences/download',
        {
            'q': q,
            'fields': 'decimalLatitude.p,decimalLongitude.p',
            'email': 'tom.dalling@gmail.au',
            'reason': 'AP03 project for James Cook University',
            'file': file_name
        }))
    log.info('Response headers received after %0.2f seconds', time.time() - t)

    log.info('Downloading zip file...')
    log.debug('Response headers: %s', dict(response.info()))
    temp_zip_file = tempfile.TemporaryFile()
    t = time.time()
    _chunked_read_and_write(response, temp_zip_file)
    t = time.time() - t
    zip_file_size_kb = float(temp_zip_file.tell()) / 1024.0
    log.info('Fetched %0.2fkb zip file in %0.2f seconds (%0.2f kb/s)',
            zip_file_size_kb, t, zip_file_size_kb / t)

    #grab the csv inside
    log.info('Reading csv from zip file...')
    t = time.time()
    zip_file = zipfile.ZipFile(temp_zip_file)
    reader = csv.DictReader(zip_file.open(file_name + '.csv'))
    num_records = 0
    for row in reader:
        record = OccurrenceRecord()
        record.latitude = float(row['Latitude - processed'])
        record.longitude = float(row['Longitude - processed'])
        yield record
        num_records += 1
    t = time.time() - t
    log.info('Read %d records in %0.2f seconds (%0.2f records/sec)',
             num_records, t, float(num_records) / t)

    zip_file.close()
    temp_zip_file.close()


def _facet_records_for_species(q):
    '''Fastest strategy, but each record only contains latitude and longitude.

    Using the '/occurrences/faces/download' web service, there is no way to get
    other info about the record, like assertions and the record uuid. If
    bandwidth wasn't an issue, the 'search' strategy may be just as fast as
    this one.'''

    log.info('Requesting csv..')
    t = time.time()
    response = _fetch(create_request(
        BIOCACHE + 'ws/occurrences/facets/download',
        {
            'q': q,
            'facets': 'lat_long',
            'count': 'true'
        }))
    log.info('Received response headers after %0.2f seconds', time.time() - t)

    reader = csv.reader(response)
    lat_long_heading, count_heading = reader.next()
    if lat_long_heading != 'lat_long':
        raise RuntimeError('Unexpected heading for lat_long facet')
    if count_heading != 'Count':
        raise RuntimeError('Unexpected heading for count')

    num_records = 0
    for row in reader:
        record = OccurrenceRecord()
        record.latitude = float(row[0])
        record.longitude = float(row[1])
        count = int(row[2])
        for i in range(count):
            yield record
            num_records += 1
            if num_records % 1000 == 0:
                log.info('%d records done...', num_records)


def _search_records_for_species(q):
    '''Currently the best strategy.

    Faster than 'download' strategy. More info about each record than 'facet'
    strategy.

    Speed could maybe be improved by fetching every page concurrently, instead
    of serially.'''

    url = BIOCACHE + 'ws/occurrences/search'
    params = {
        'q': q,
        'fl': 'id,latitude,longitude',
        'facet': 'off',
    }

    for page in _json_pages(url, params, ('totalRecords',), 'startIndex'):
        for occ in page['occurrences']:
            record = OccurrenceRecord()
            record.latitude = occ['decimalLatitude']
            record.longitude = occ['decimalLongitude']
            record.uuid = uuid.UUID(occ['uuid'])
            yield record

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
