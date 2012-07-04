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
import datetime


OCC_PAGE_SIZE = 1000  # occurrence records per biocache request
SPECIES_PAGE_SIZE = 500  # species per BIE request
BIE = 'http://bie.ala.org.au/'
BIOCACHE = 'http://biocache.ala.org.au/'

_log = logging.getLogger(__name__)
_max_retry_secs = 300 # 5 minutes by default
_api_key = None # don't use any api key by default


class Coord(object):

    def __init__(self, lati, longi):
        self.lati = float(lati)
        self.longi = float(longi)

    def __repr__(self):
        return '({0}, {1})'.format(self.lati, self.longi)

    def __eq__(self, other):
        return (type(other) is type(self) and
                self.lati == other.lati and
                self.longi == other.longi)

    def __ne__(self, other):
        return not self.__eq__(other)

    @classmethod
    def from_dict(cls, d, latKey, longKey):
        if latKey in d and longKey in d:
            return Coord(d[latKey], d[longKey])
        else:
            return None


class Occurrence(object):
    '''Plain old data structure for an occurrence record'''

    def __init__(self, coord=None, sens_coord=None, uuid_in=None,
            assertions=[], uncertainty=None, date=None):
        self.coord = coord
        self.sensitive_coord = sens_coord
        self.assertions = set(assertions)
        self.uncertainty = uncertainty # in meters (not sure if radius, or AABB)
        self.date = date # datetime.date or None

        if uuid_in is None:
            self.uuid = None
        elif isinstance(uuid_in, uuid.UUID):
            self.uuid = uuid_in
        else:
            self.uuid = uuid.UUID(uuid_in)

    def __repr__(self):
        return '<record uuid="{uuid}" coord="{coord}" />'.format(
            uuid=self.uuid,
            coord=self.coord)

    def __eq__(self, other):
        if type(other) is type(self):
            return (self.uuid == other.uuid and
                    self.coord == other.coord and
                    self.sensitive_coord == other.sensitive_coord)
        else:
            return False

    def __ne__(self, other):
        return not self.__eq__(other)


class Species(object):
    '''Plain old data structure for a species'''

    def __init__(self, common_name=None, scientific_name=None, lsid=None):
        self.common_name = common_name
        self.scientific_name = scientific_name
        self.lsid = lsid

    def __repr__(self):
        # might be None, or contain wierd unicode
        _asc = lambda s: None if s is None else s.encode('ascii', 'ignore')

        return '<species common="{com}" scientific="{sci}" lsid="{lsid}" />'.\
            format(com=_asc(self.common_name),
                   sci=_asc(self.scientific_name),
                   lsid=self.lsid)

    def __eq__(self, other):
        if type(other) is type(self):
            return (self.common_name == other.common_name and
                    self.scientific_name == other.scientific_name and
                    self.lsid == other.lsid)
        else:
            return False

    def __ne__(self, other):
        return not self.__eq__(other)


def set_api_key(api_key):
    global _api_key
    _api_key = api_key

def set_max_retry_secs(max_retry_secs):
    global _max_retry_secs;
    _max_retry_secs = max_retry_secs;


def occurrences_for_species(species_lsid, changed_since=None, sensitive_only=False):
    '''A generator for Occurrenceobjects fetched from ALA'''

    url = BIOCACHE + 'ws/occurrences/search'
    params = {
        'q': q_param(species_lsid, changed_since),
        'fl': ','.join(('id', 'latitude', 'longitude', 'sensitive_longitude',
            'sensitive_latitude', 'assertions', 'coordinate_uncertainty',
            'sensitive_coordinate_uncertainty', 'occurrence_date')),
        'facet': 'off',
        'pageSize': OCC_PAGE_SIZE
    }

    if sensitive_only:
        params['fq'] = 'sensitive:generalised'
        if _api_key is None:
            raise RuntimeError("Can't fetch sensitive coords without API key")

    for page in _json_pages(url, params, ('totalRecords',), 'startIndex', use_api_key=True):
        for occ in page['occurrences']:

            uncertainty = None
            if 'sensitiveCoordinateUncertaintyInMeters' in occ:
                uncertainty = occ['sensitiveCoordinateUncertaintyInMeters']
            else:
                uncertainty = occ['coordinateUncertaintyInMeters']

            date = None
            if 'eventDate' in occ:
                # unix timestamp, but in milliseconds instead of seconds
                ts = occ['eventDate'] / 1000
                date = datetime.date.fromtimestamp(ts)

            yield Occurrence(
                uuid_in=uuid.UUID(occ['uuid']),
                coord=Coord.from_dict(occ, 'decimalLatitude', 'decimalLongitude'),
                sens_coord=Coord.from_dict(occ, 'sensitiveDecimalLatitude', 'sensitiveDecimalLongitude'),
                assertions=(occ['assertions'] if 'assertions' in occ else set()),
                uncertainty=int(uncertainty),
                date=date
            )


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
        _log.warning('lsid is for "%s", not "species": %s',
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
    '''Generator for Species objects '''

    return _fetch_species_list(
        (('fq', 'speciesGroup:Birds'),
         ('fq', 'rank:species'),
         ('fq', 'idxtype:TAXON'),
         ('pageSize', SPECIES_PAGE_SIZE))
    )


def all_vertebrate_species():
    '''Generator for Species objects under subphylum Vertebrata'''

    j = _fetch_json(create_request(BIE + 'species/VERTEBRATA.json'))
    assert j['taxonConcept']['rankString'] == 'subphylum'
    left = j['taxonConcept']['left']
    right = j['taxonConcept']['right']

    return _fetch_species_list(
        (('fq', 'rank:species'),
         ('fq', 'idxtype:TAXON'),
         ('fq', 'left:[{0} TO {1}]'.format(left, right)),
         ('pageSize', SPECIES_PAGE_SIZE))
    )


def num_occurrences_for_lsid(lsid):
    j = _fetch_json(create_request(BIOCACHE + 'ws/occurrences/search', {
            'q': q_param(lsid),
            'facet': 'off',
            'pageSize': 0}))
    return j['totalRecords']


def create_request(url, params=None, use_get=True, use_api_key=False):
    '''URL encodes params and into a GET or POST request.

    Also adds ALA api key to request, if set.'''

    if params is not None:
        # convert to list
        if isinstance(params, dict):
            params = list(params.items())
        else:
            params = list(params) # makes a copy before modifying

        # add api key
        if use_api_key and _api_key is not None:
            params.append(('apiKey', _api_key))

        # encode params
        params = urllib.urlencode(params)

        # append params to url if using GET instead of POST
        if use_get:
            url += '?' + params
            params = None

    _log.debug('Created request for: ' + url)
    return urllib2.Request(url, params, {'User-Agent': 'Edgar/Python-urllib2'})


def q_param(species_lsid=None, changed_since=None):
    '''The 'q' parameter for ALA web service queries

    `changed_since` allows you to only get records that have changed between a
    certain date range.'''

    if species_lsid is None:
        species_lsid = ''
    else:
        species_lsid = 'lsid:' + species_lsid + ' AND '

    if changed_since is None:
        changed_since = ''
    else:
        daterange = _q_date_range(changed_since, None)
        changed_since = '''
            (last_processed_date:{0} OR last_assertion_date:{0}) AND
            '''.format(daterange)

    return _strip_n_squeeze(''.join((
        #limit by species and/or date modified
        '''
        {lsid}
        {changed}
        '''.format(lsid=species_lsid, changed=changed_since),

        # aggregate subspecies records into species
        '''
        (rank:species OR subspecies_name:[* TO *]) AND
        ''',

        # bounding box of australia
        '''
        longitude:[112.60412597657 TO 154.44006347657] AND
        latitude:[-43.734590478689 TO -9.9190742304658] AND
        ''',

        # filters (assertions, uncertainty, etc)
        '''
        coordinate_uncertainty:[* TO 25000] AND
        NOT assertions:zeroCoordinates AND
        NOT assertions:coordinatesCentreOfStateProvince AND
        NOT assertions:uncertaintyNotSpecified AND
        NOT assertions:coordinatesCentreOfCountry AND
        NOT assertions:invalidGeodeticDatum AND
        NOT assertions:invalidScientificName AND
        NOT assertions:unknownKingdom AND
        NOT assertions:ambiguousName AND
        NOT assertions:inferredDuplicateRecord AND
        (
            basis_of_record:HumanObservation OR
            basis_of_record:MachineObservation OR
            assertions:missingBasisOfRecord
        )
        ''')))


def _fetch_species_list(params):
    '''Generator for Species objects'''

    url = BIE + 'search.json'
    total_key_path = ('searchResults', 'totalRecords')

    for page in _json_pages(url, params, total_key_path, 'start'):
        for result in page['searchResults']['results']:
            if result['occCount'] > 0:
                s = Species()
                s.lsid = result['guid']
                s.scientific_name = result['nameComplete'].strip()
                if result['commonNameSingle'] is not None:
                    s.common_name = result['commonNameSingle'].strip()

                yield s


def _retry(delay=5.0):
    '''A decorator that retries a function or method until it succeeds (success
    is when the function completes and no exception is raised).

    Waits `delay` seconds between retries. Reraises the failure exception if
    more than `_max_retry_secs` has elapsed.'''

    def deco_retry(f):
        def f_retry(*args, **kwargs):
            startTime = time.time();

            while True:
                try:
                    return f(*args, **kwargs)
                except Exception, e:
                    if time.time() - startTime < _max_retry_secs:
                        _log.warning('Retrying fetch due to exception: %s', str(e))
                        time.sleep(delay)
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
    response = urllib2.urlopen(request, timeout=20.0)
    response_time = time.time()
    response_str = response.read()
    end_time = time.time()

    _log.debug('Loaded JSON at %f kb/s. %f before response + %f download time.',
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

    >>> _q_date_range(datetime.datetime(2012, 12, 14, 13, 33, 2), None)
    '[2012-12-14T13:33:02Z TO *]'
    '''

    return '[{0} TO {1}]'.format(_q_date(from_date), _q_date(to_date))


def _q_date(d):
    '''Formats a datetime into a string for use in an ALA date range

    The datetime must be naive (without a tzinfo) and represent a UTC time. It
    can also be None, indicating 'any date'.

    >>> _q_date(datetime.datetime(2012, 12, 14, 13, 33, 2))
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

    'pageSize' must be present in the params.
    Strips out any offset_key ('startIndex') params. Turns params into a list.

    >>> params = {'q':'query', 'pageSize': 666, 'startIndex': 10}
    >>> _json_pages_params_filter(params, 'startIndex')
    ([('q', 'query'), ('pageSize', 666)], 100)

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
            page_size = value
        filtered_params.append((name, value))

    # add 'pageSize' if not present
    assert page_size is not None

    return filtered_params, int(page_size);



def _json_pages(url, params, total_key_path, offset_key, use_api_key=False):
    assert len(total_key_path) > 0

    params, page_size = _json_pages_params_filter(params, offset_key)

    page_idx = 0
    total_pages = None
    while True:
        params.append((offset_key, page_idx * page_size))
        req = create_request(url, params, use_api_key=use_api_key)
        response = _fetch_json(req)
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
