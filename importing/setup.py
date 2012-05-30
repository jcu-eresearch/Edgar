from setuptools import setup
setup(
    name='edgar_importing',
    install_requires=['sqlalchemy', 'argparse', 'mysql-python', 'setuptools'],
    entry_points=('''
        [console_scripts]
        ala_db_update = edgar_importing.ala_db_update:main
        costa_rica_db_wipe_and_import = edgar_importing.costa_rica_db_wipe_and_import:main
        costa_rica_threshold_processor = edgar_importing.costa_rica_threshold_processor:main
        db_wipe = edgar_importing.db_wipe:main
        fetch_occur_csv = edgar_importing.fetch_occur_csv:main
        ''')
)