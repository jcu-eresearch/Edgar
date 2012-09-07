---
title:   Edgar Develop and Deploy Manual
layout:  page
author:  robert
summary: ''
excerpt: 
categories: [Documentation]
tags:    []
---

This install guide is for <code>yum</code>, tested with CentOS 6.2. Installation also confirmed working with Ubuntu <code>apt-get</code> packages.

#Install Database

Install PostgreSQL 8.4 with contrib modules:

    sudo yum install postgresql postgresql-server postgresql-contrib

(Optional) Change the Postgres data directory by creating/editing the
file `/etc/sysconfig/pgsql/postgresql` to contain this:

    PGDATA=/opt/pgsql/data
    PGLOG=/opt/pgsql/pgstartup.log

Install PostGIS 1.5

    #TODO: make this nicer
    cd /etc/pki/rpm-gpg/
    sudo wget http://elgis.argeo.org/RPM-GPG-KEY-ELGIS

    sudo yum install postgis

Create the Edgar database:

    sudo -u postgres createdb edgar

Find the Postgres contrib directory. It is `/usr/share/pgsql/contrib/`
on CentOS. Now install all the requried contrib modules:

    cd /usr/share/pgsql/contrib/
    sudo -u postgres createlang plpgsql edgar
    sudo -u postgres psql -d edgar -f postgis.sql
    sudo -u postgres psql -d edgar -f spatial_ref_sys.sql
    sudo -u postgres psql -d edgar -f pg_trgm.sql

Create the two database roles (a.k.a users) inside the psql console:

    sudo -u postgres psql edgar

    create role edgar_backend with login password 'make_up_password_here';
    create role edgar_frontend with login password 'make_up_password_here';

Fetch a copy of Edgar. In this case, we will fetch it to `~/Edgar`:

    sudo yum install git
    cd ~
    git clone "git://github.com/jcu-eresearch/Edgar.git"

Initialise the database:

    sudo -u postgres psql edgar < ~/Edgar/database_structure.sql

Edit the `pg\_hba.conf` file in the Postgresql data directory. The
default data directory is `/var/lib/pgsql/data/` on CentOS. The
following config will allow access from `localhost` only.

    local  edgar  edgar_frontend                md5
    local  edgar  edgar_backend                 md5
    host   edgar  edgar_frontend  127.0.0.1/32  md5
    host   edgar  edgar_backend   127.0.0.1/32  md5

Restart Postgres:

    sudo service postgresql restart

Add to auto-start processes:

    sudo chkconfig --add  postgresql 
    sudo chkconfig --level 345 postgresql on

#Setup ALA Importer

This install guide is for <code>yum</code>, tested with CentOS 6.2. Installation also confirmed working with Ubuntu <code>apt-get</code> packages.

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

#Install Web Application


Install apache:

    sudo yum install httpd mod_ssl

Start apache:

    sudo /etc/init.d/httpd start

Install php:

    sudo yum install php

Install php postgresql driver:

    sudo yum install php-pgsql

Install php xml support (needed for cakephp):

    sudo yum install php-xml

Install git:

    sudo yum install git

Change dir to www (not html dir):

    cd /var/www

Clone the git repo (read only):

    sudo git clone "git://github.com/jcu-eresearch/Edgar.git"

Update the tmp directory of the web app so that cake can read and write to the tmp dir.

    sudo chmod ugo+wrX -R /var/www/Edgar/webapplication/app/tmp/

Change dir to html, and create link to webapplication component of git repo in www dir

    cd /var/www/html
    sudo ln -s /var/www/Edgar/webapplication/ Edgar

Update httpd conf to allow cakephp to perform re-writes

Add the following to the httpd.conf (/etc/httpd/conf/httpd.conf).
This should be added after the default directory settings (&lt;Directory "/var/www/html"&gt;&hellip;&lt;/Directory&gt;).

    <Directory "/var/www/html/Edgar">
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        Allow from all
    </Directory>
Update the database config settings:

    sudo cp /var/www/Edgar/webapplication/app/Config/database.php.default /var/www/Edgar/webapplication/app/Config/database.php
    sudo vim /var/www/Edgar/webapplication/app/Config/database.php

Restart apache:

    sudo /etc/init.d/httpd restart

Add apache to the "on boot" services:

    sudo chkconfig --add httpd
    sudo chkconfig --level 345 httpd on

Confirm that it's added by looking at:

    sudo chkconfig --list

You may need to open port 80 of your firewall.
You can check your firewall settings via:


    sudo iptables -L -v

You can add the rule to open port 80 by doing the following.
Note: Don't follow this part blindly, you should have at least a basic understanding of firewalls before you do this.

    sudo iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
    sudo service iptables save

At this point, everything should be working. Go to http://localhost/Edgar and enjoy
