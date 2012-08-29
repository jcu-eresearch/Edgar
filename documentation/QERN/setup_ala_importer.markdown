ALA importer
============

This assumes you have a copy of Edgar in the directory `~/Edgar`, and
have a database named `edgar`.

Install packges required by importer Python modules:

    sudo yum install postgresql-devel python-devel

Run buildout in the `importing` directory with Python 2.6:

    cd ~/Edgar/importing/
    python2.6 setup.py
    bin/buildout

Add the ALA row to the sources table:

    sudo -u postgres psql edgar
    insert into sources(name) values('ALA');

Copy the example config and change the settings:

    cp config.example.json config.json
    vim config.json

Run the importer:

    bin/ala_db_update config.json

The importer should be run often (e.g. weekly) to fetch new data from
ALA. The easiest way to do this is to set up a cron job. See the file
`importing/bin/ala_cron.sh` for an example cron script.
