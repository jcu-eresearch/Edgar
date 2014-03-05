from sqlalchemy import (engine_from_config, MetaData, Table,
    Column, ForeignKey, PrimaryKeyConstraint, Index)
from sqlalchemy.types import (SmallInteger, String, Integer,
    DateTime, Float, Enum, BINARY, Text, Date)
from geoalchemy import (GeometryExtensionColumn, Point, GeometryDDL,
    MultiPolygon)


engine = None
metadata = MetaData()


def connect(engine_config):
    '''Call this before trying to use anything else'''
    global engine
    engine = engine_from_config(engine_config, prefix='db.')
    metadata.bind = engine


classification_enum = Enum('unknown', 'invalid', 'historic', 'vagrant',
    'irruptive', 'core', 'introduced');

basis_enum = Enum('Preserved specimen', 'Human observation',
    'Machine observation')



species = Table('species', metadata,
    Column('id', Integer(), primary_key=True),
    Column('scientific_name', String(256), nullable=False),
    Column('common_name', String(256), nullable=True),
    Column('num_dirty_occurrences', Integer(), nullable=False, default=0),
    Column('needs_vetting_since', DateTime(), nullable=True, default=None)
)


sources = Table('sources', metadata,
    Column('id', Integer(), primary_key=True),
    Column('name', String(256), nullable=False),
    Column('url', String(256), nullable=False),
    Column('last_import_time', DateTime(), nullable=True)
)


occurrences = Table('occurrences', metadata,
    Column('id', Integer(), primary_key=True),
    GeometryExtensionColumn('location', Point(2, srid=4326), nullable=False),
    Column('uncertainty', Integer(), nullable=False),
    Column('date', Date(), nullable=True),
    Column('classification', classification_enum, nullable=False),
    Column('basis', basis_enum, nullable=True),
    Column('species_id', SmallInteger(), ForeignKey('species.id'), nullable=False),
    Column('source_id', SmallInteger(), ForeignKey('sources.id'), nullable=False),
    Column('source_record_id', BINARY(16), nullable=True),
    Column('source_classification', classification_enum, nullable=False)
)
GeometryDDL(occurrences)


sensitive_occurrences = Table('sensitive_occurrences', metadata,
    Column('occurrence_id', Integer(), ForeignKey('occurrences.id'), nullable=False),
    GeometryExtensionColumn('sensitive_location', Point(2, srid=4326), nullable=False)
)
GeometryDDL(sensitive_occurrences)


vettings = Table('vettings', metadata,
    Column('id', Integer(), primary_key=True),
    Column('user_id', Integer(), ForeignKey('users.id'), nullable=False),
    Column('species_id', Integer(), ForeignKey('species.id'), nullable=False),
    Column('comment', Text(), nullable=False),
    Column('classification', classification_enum, nullable=False),
    GeometryExtensionColumn('area', MultiPolygon(2, srid=4326), nullable=False)
)
GeometryDDL(vettings)


# table only available after using shp2pgsql on BLA shapefile:
#     shp2pgsql TaxonPolys1.shp birdlife_import | sudo -u postgres psql edgar
birdlife_import = Table('birdlife_import', metadata,
    Column('spno', SmallInteger()),
    Column('rnge', Integer()),
    Column('brrnge', Integer()),
    GeometryExtensionColumn('the_geom', MultiPolygon(2, srid=-1))
)
GeometryDDL(birdlife_import)
