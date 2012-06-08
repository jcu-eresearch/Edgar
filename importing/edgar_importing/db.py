import sys
from sqlalchemy import (engine_from_config, MetaData, Table,
    Column, ForeignKey, PrimaryKeyConstraint, Index)
from sqlalchemy.types import (SmallInteger, String, Integer,
    DateTime, Float, Enum, BINARY, Text)
from geoalchemy import (GeometryExtensionColumn, Point, GeometryDDL,
    MultiPolygon)

engine = None
metadata = MetaData()

def connect(engine_config):
    '''Call this before trying to use anything else'''
    global engine
    engine = engine_from_config(engine_config, prefix='db.')
    metadata.bind = engine

ratings_enum = Enum('unknown', 'invalid', 'historic', 'vagrant', 'irruptive',
    'non-breeding', 'introduced non-breeding', 'breeding',
    'introduced breeding');

species = Table('species', metadata,
    Column('id', Integer(), primary_key=True),
    Column('scientific_name', String(256), nullable=False),
    Column('common_name', String(256), nullable=True),
    Column('num_dirty_occurrences', Integer(), nullable=False,
        default=0),
    Column('distribution_threshold', Float(), nullable=False,
        default=0),

    mysql_charset='utf8'
)

sources = Table('sources', metadata,
    Column('id', Integer(), primary_key=True),
    Column('name', String(256), nullable=False),
    Column('last_import_time', DateTime(), nullable=True)
)

occurrences = Table('occurrences', metadata,
    Column('id', Integer(), primary_key=True),
    GeometryExtensionColumn('location', Point(2, srid=4326), nullable=False),
    Column('rating', ratings_enum, nullable=False),
    Column('species_id', SmallInteger(), ForeignKey('species.id'),
        nullable=False),
    Column('source_id', SmallInteger(), ForeignKey('sources.id'),
        nullable=False),
    Column('source_record_id', BINARY(16), nullable=True),

    Index('idx_species_id', 'species_id'),

    mysql_engine='MyISAM'
)
GeometryDDL(occurrences)

users = Table('users', metadata,
    Column('id', Integer(), primary_key=True),
    Column('email', String(256), nullable=False)
)

ratings = Table('ratings', metadata,
    Column('id', Integer(), primary_key=True),
    Column('user_id', Integer(), ForeignKey('users.id'),
        nullable=False),
    Column('species_id', Integer(), ForeignKey('species.id'),
        nullable=False),
    Column('comment', Text(), nullable=False),
    Column('rating', ratings_enum, nullable=False),
    GeometryExtensionColumn('area', MultiPolygon(2, srid=4326), nullable=False)
)
GeometryDDL(ratings)

