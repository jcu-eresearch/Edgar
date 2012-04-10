This directory contains python scripts to import/synchronise data from ALA into the local database.

Executable scripts are in the 'bin' directory. Non-executable scripts are in
the 'src' directory.

Run the scripts in the 'bin' directory with the '-h' option for usage documentation. There is also code documentation in docstrings inside the python files themselves.

## Setup ##

You might need to run these to install dependencies:

    sudo yum install python-setuptools
    sudo yum install MySQL-python
    sudo easy_install argparse
    sudo easy_install http://pypi.python.org/packages/source/S/SQLAlchemy/SQLAlchemy-0.7.6.tar.gz#md5=6383cade61ecff1a236708fae066447a

Next, you need to create a config file with the database host/user/password. See `config.example.json`. This file is passed into the scripts as a command line argument.
