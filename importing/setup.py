from setuptools import setup
setup(
    name='edgar_importing',
    install_requires=['pyshp', 'shapely', 'GeoAlchemy', 'sqlalchemy', 'argparse', 'psycopg2', 'setuptools'],
    entry_points=('''
        [console_scripts]
        ala_db_update = edgar_importing.ala_db_update:main
        ala_db_update_sensitive = edgar_importing.ala_db_update_sensitive:main
        costa_rica_db_wipe_and_import = edgar_importing.costa_rica_db_wipe_and_import:main
        costa_rica_threshold_processor = edgar_importing.costa_rica_threshold_processor:main
        db_wipe = edgar_importing.db_wipe:main
        fetch_occur_csv = edgar_importing.fetch_occur_csv:main
        birdlife_shapefile_import = edgar_importing.birdlife_shapefile_import:main
        csvs_from_db = edgar_importing.csvs_from_db:main
        dbtest = edgar_importing.dbtest:main
        ''')
)
