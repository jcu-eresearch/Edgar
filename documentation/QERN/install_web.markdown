climatebird2.qern.qcif.edu.au (Web)
====================================

Install apache:

```bash

sudo yum install httpd mod_ssl
```

Start apache:

```bash

sudo /etc/init.d/httpd start
```

Install php:

```bash

sudo yum install php
```

Install php postgresql driver:

```bash

sudo yum install php-pgsql
```

Install php xml support (needed for cakephp):

```bash

sudo yum install php-xml
```

Install git:

```bash

sudo yum install git
```

Change dir to www (not html dir):

```bash

cd /var/www
```

Fetch the git repo (read only):

```bash

sudo git fetch "git://github.com/jcu-eresearch/Edgar.git"
```

Update the tmp directory of the web app so that cake can read and write to the tmp dir.

```bash

sudo chmod ugo+wrX -R /var/www/Edgar/webapplication/app/tmp/
```

Change dir to html, and create link to webapplication component of git repo in www dir

```bash

cd /var/www/html
sudo ln -s /var/www/Edgar/webapplication/ Edgar
```

Update httpd conf to allow cakephp to perform re-writes

Add the following to the httpd.conf (/etc/httpd/conf/httpd.conf).
This should be added after the default directory settings (&lt;Directory "/var/www/html"&gt;&hellip;&lt;/Directory&gt;).

```conf

<Directory "/var/www/html/Edgar">
    Options Indexes FollowSymLinks MultiViews
    AllowOverride All
    Order allow,deny
    Allow from all
</Directory>
```
Update the database config settings:

```bash

sudo cp /var/www/Edgar/webapplication/app/Config/database.php.default /var/www/Edgar/webapplication/app/Config/database.php
sudo vim /var/www/Edgar/webapplication/app/Config/database.php
```

Restart apache:

```bash

sudo /etc/init.d/httpd restart
```

Add apache to the "on boot" services:

```bash

sudo chkconfig --add httpd
sudo chkconfig --level 345 httpd on
```

Confirm that it's added by looking at:

```bash

sudo chkconfig --list
```

You may need to open port 80 of your firewall.
You can check your firewall settings via:


```bash

sudo iptables -L -v
```

You can add the rule to open port 80 by doing the following.
Note: Don't follow this part blindly, you should have at least a basic understanding of firewalls before you do this.

```bash

sudo iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
sudo service iptables save
```

At this point, everything should be working. Go to http://localhost/Edgar and enjoy



Postgres Database - climatebird1.qern.qcif.edu.au
==============================================================

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

    create role edgar_backend with password 'make_up_password_here';
    create role edgar_frontend with password 'make_up_password_here';

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

TODO: allow access to postgres port through firewall


ALA importer
============

Add the ALA row to the sources table:

    sudo -u postgres psql edgar
    insert into sources(name) values('ALA');

Copy the example config and change the settings:

    cd ~/Edgar/importing/
    cp config.example.json config.json
    vim config.json
