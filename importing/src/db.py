import sys
from sqlalchemy import \
    engine_from_config, MetaData, Table, Column, ForeignKey, \
    PrimaryKeyConstraint, Index
from sqlalchemy.dialects.mysql import \
    SMALLINT, TINYINT, ENUM, VARCHAR, DATETIME, FLOAT, BINARY, TEXT, \
    INTEGER

engine = None
metadata = MetaData()


def connect(engine_config):
    '''Call this before trying to use anything else'''
    global engine
    engine = engine_from_config(engine_config, prefix='db.')
    metadata.bind = engine


species = Table('species', metadata,
    Column('id', SMALLINT(unsigned=True), primary_key=True),
    Column('scientific_name', VARCHAR(256), nullable=False),
    Column('common_name', VARCHAR(256), nullable=True),

    mysql_charset='utf8'
)

sources = Table('sources', metadata,
    Column('id', TINYINT(unsigned=True), primary_key=True),
    Column('name', VARCHAR(256), nullable=False),
    Column('last_import_time', DATETIME(), nullable=True)
)

occurrences = Table('occurrences', metadata,
    Column('id', INTEGER(unsigned=True), primary_key=True),
    Column('latitude', FLOAT(), nullable=False),
    Column('longitude', FLOAT(), nullable=False),
    Column('rating', ENUM('known valid', 'assumed valid', 'known invalid',
        'assumed invalid'), nullable=False),
    Column('species_id', SMALLINT(unsigned=True), ForeignKey('species.id'),
        nullable=False),
    Column('source_id', TINYINT(unsigned=True), ForeignKey('sources.id'),
        nullable=False),
    Column('source_record_id', BINARY(16), nullable=True),

    Index('idx_species_id', 'species_id'),

    mysql_engine='MyISAM'
)

users = Table('users', metadata,
    Column('id', INTEGER(unsigned=True), primary_key=True),
    Column('email', VARCHAR(256), nullable=False)
)

ratings = Table('ratings', metadata,
    Column('id', INTEGER(unsigned=True), primary_key=True),
    Column('user_id', INTEGER(unsigned=True), ForeignKey('users.id'),
        nullable=False),
    Column('comment', TEXT(), nullable=False),
    Column('rating', ENUM('known valid', 'assumed valid', 'known invalid',
        'assumed invalid'), nullable=False)
)

occurrences_ratings_bridge = Table('occurrences_ratings_bridge', metadata,
    Column('occurrence_id', INTEGER(unsigned=True), nullable=False),
    Column('rating_id', INTEGER(unsigned=True), nullable=False),

    PrimaryKeyConstraint('occurrence_id', 'rating_id')
)
