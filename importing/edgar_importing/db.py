import sys
from sqlalchemy import engine_from_config, MetaData, Table, \
    Column, ForeignKey, PrimaryKeyConstraint, Index
from sqlalchemy.types import SmallInteger, String, Integer, \
    DateTime, Float, Enum, BINARY, Text

engine = None
metadata = MetaData()


def connect(engine_config):
    '''Call this before trying to use anything else'''
    global engine
    engine = engine_from_config(engine_config, prefix='db.')
    metadata.bind = engine


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
    Column('latitude', Float(), nullable=False),
    Column('longitude', Float(), nullable=False),
    Column('rating', Enum(
        'known valid',
        'assumed valid',
        'known invalid',
        'assumed invalid'),
        nullable=False),
    Column('species_id', SmallInteger(), ForeignKey('species.id'),
        nullable=False),
    Column('source_id', SmallInteger(), ForeignKey('sources.id'),
        nullable=False),
    Column('source_record_id', BINARY(16), nullable=True),

    Index('idx_species_id', 'species_id'),

    mysql_engine='MyISAM'
)

# exact copy of `occurrences`
sensitive_occurrences = Table('sensitive_occurrences', metadata,
    Column('id', Integer(), primary_key=True),
    Column('latitude', Float(), nullable=False),
    Column('longitude', Float(), nullable=False),
    Column('rating', Enum(
        'known valid',
        'assumed valid',
        'known invalid',
        'assumed invalid'),
        nullable=False),
    Column('species_id', SmallInteger(), ForeignKey('species.id'),
        nullable=False),
    Column('source_id', SmallInteger(), ForeignKey('sources.id'),
        nullable=False),
    Column('source_record_id', BINARY(16), nullable=True),

    Index('idx_sensitive_species_id', 'species_id'),

    mysql_engine='MyISAM'
)

users = Table('users', metadata,
    Column('id', Integer(), primary_key=True),
    Column('email', String(256), nullable=False)
)

ratings = Table('ratings', metadata,
    Column('id', Integer(), primary_key=True),
    Column('user_id', Integer(), ForeignKey('users.id'),
        nullable=False),
    Column('comment', Text(), nullable=False),
    Column('rating', Enum(
        'known valid',
        'assumed valid',
        'known invalid',
        'assumed invalid'),
        nullable=False)
)

occurrences_ratings_bridge = Table('occurrences_ratings_bridge', metadata,
    Column('occurrence_id', Integer(), nullable=False),
    Column('rating_id', Integer(), nullable=False),

    PrimaryKeyConstraint('occurrence_id', 'rating_id')
)
