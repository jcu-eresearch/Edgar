from setuptools import setup
setup(
    name='edgar_importing',
    install_requires=['pyshp', 'shapely', 'GeoAlchemy', 'sqlalchemy', 'argparse', 'psycopg2', 'setuptools'],
    entry_points=('''
        [console_scripts]
        ala_db_update = edgar_importing.ala_db_update:main
        costa_rica_db_wipe_and_import = edgar_importing.costa_rica_db_wipe_and_import:main
        costa_rica_threshold_processor = edgar_importing.costa_rica_threshold_processor:main
        db_wipe = edgar_importing.db_wipe:main
        birdlife_shapefile_import = edgar_importing.birdlife_shapefile_import:main
        csvs_from_db = edgar_importing.csvs_from_db:main
        vettingd = edgar_importing.vettingd:main
        vetting_syncd = edgar_importing.vetting_syncd:main
        ''')
)
