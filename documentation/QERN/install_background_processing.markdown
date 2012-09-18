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

The following is a general description of how to setup the modelling to work on a HPC.
The modelling process will need to be customized to your specific needs.

## Setup Vetting
