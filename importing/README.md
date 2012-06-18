This directory contains the Python egg edga\_importing.  edgar\_importing
imports/synchronises data from external sources (such as ALA) into the
local database. It follows the standard egg/zc.buildout structure.

## Setup ##

You may need a couple of yum packages installed before running buildout:

sudo yum install python-devel
sudo yum install mysql-devel
sudo yum install postgresql-devel

Run the standard buildout setup using Python2.6 (this will install all
dependencies):

    python2.6 bootstrap.py
    bin/buildout

Next, you need to create a config file with the database
host/user/password. See `config.example.json`. This file is passed into
the scripts as a command line argument.


## Usage ##

Most commands can be run with the `-h` flag to show documentation.

`bin/test` - Runs all the unit tests. Outputs jUnit formatted xml.

`bin/ala_db_update` - Syncs local database with ALA data

`bin/ala_cron.sh` - An example cron script for `ala_db_update`.

`bin/db_wipe` - Wipes all occurrences and species in the db with test data.
