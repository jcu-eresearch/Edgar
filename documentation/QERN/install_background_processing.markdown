#Setup Background Modelling and Vetting Processing

## Install supervisord

Install python:

    sudo yum install python-devel

Install python easy_install (bundled with setuptools):

    sudo yum install python-setuptools

Install supervisord:

    sudo easy_install supervisor

Supervisor is used to manage our background running processes. It provides logging capabilities, and ensures that our processes are kept alive.
Supervisor is also used to control the number of concurrent models we run.

Install supervisord (full details available at: http://supervisord.org/installing.html):

    easy_install supervisor

Fetch a copy of Edgar. In this case, we will fetch it to `~/Edgar`:

    sudo yum install git
    cd ~
    git clone "git://github.com/jcu-eresearch/Edgar.git"

Link the supervisord config file from the Git repo to the appropriate config location for supervisord:

    cd /etc/
    sudo ln -s ~/Edgar/modelling/supervisord/supervisord.conf supervisord.conf

Update your config file as necessary:

    sudo vim /etc/supervisord.conf

You will need to, at a minimum, update file paths for the `user`, `command`, `environment` and `directory` settings of the various programs.

Make the log directory for supervisord (path specified in config file):

    sudo mkdir -p /var/log/supervisord

Add supervisord to the services:

    sudo ln -s ~/Edgar/modelling/supervisord/supervisord_init_service.sh /etc/init.d/supervisord
    sudo chkconfig --add supervisord
    sudo chkconfig --level 345 supervisord on

You may need to update the `supervisord_init_service.sh` script based on your system OS

Start the supervisord service:

    sudo service supervisord start

## Setup Modelling

The following is a general description of how to setup the modelling to run on a local machine.
The modelling process may need to be customized to your specific needs.

If you haven't already done so, fetch a copy of edgar, and put it in your
home directory `~/Edgar`:

    sudo yum install git
    cd ~
    git clone "git://github.com/jcu-eresearch/Edgar.git"

The modelling process makes use of the existing importing db access code.
This means that it is necessary to run the setup code for the importing:

    cd ~/Edgar/importing
    sudo yum install python-devel
    sudo yum install postgresql-devel
    sudo python setup.py install
    python bootstrap.py

Copy the example importing config and change the settings:

    cp ~/Edgar/importing/config.example.json ~/Edgar/importing/config.json
    vim ~/Edgar/importing/config.json

Note: You may need need to update the settings of your DB to permit the modelling machine to access
the DB:

    sudo vim /opt/pgsql/data/pg_hba.conf

and add a line like:

    host   edgar  edgar_backend   X.X.X.X/32  md5

Now install libraries specific to modelling:

    sudo yum install python-devel
    sudo easy_install supervisor
    sudo easy_install paramiko

Modify the hpc config file to reflect the location of your web server:
    vim ~/Edgar/modelling/src/hpc_config.py

Changes the line:

    cakeAppBaseURL = "http://tdh-tools-2.hpc.jcu.edu.au/Edgar/webapplication"

to accurately reflect the location of your web server.

e.g.:

    cakeAppBaseURL = "http://climatebird2.qern.qcif.edu.au/Edgar"


Note: You can ignore the ssh references, these are only used for remote modelling. This
guide is for local modelling.

Install R:

    sudo rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-7.noarch.rpm
    sudo yum install R

Install R Libraries:

    sudo R
    install.packages(c("SDMTools"))

(Note, the second line is run at the R prompt)

Install gdal (The GDAL library provides support to handle multiple GIS file formats):

    sudo yum install gdal
    sudo yum install gdal-python.x86_64

Install java:

    sudo yum install java

Install zip:

    sudo yum install java

You can now start the modelling process by running:

    ~/Edgar/modelling/bin/local_modeld.py

Once you've confirmed that your modelling process is running, you should update your
supervisord config to run your modelling scripts for you:

    sudo vim /etc/supervisord.conf

## Setup Vetting
