(If on Ubuntu, use this to install postgis: http://trac.osgeo.org/postgis/wiki/UsersWikiPostGIS20Ubuntu1210)

Postgres Database - climatebird1.qern.qcif.edu.au (preferred - postgres 9.2 with postgis 2)
==============================================================

This install guide is for <code>yum</code>, tested with CentOS 6.2. Installation also confirmed working with Ubuntu <code>apt-get</code> packages.

Update postgres to use 9.2 packages. This section is based on the guide
provided by postgresql available at: http://yum.postgresql.org/

Specifically, check out: http://wiki.postgresql.org/wiki/YUM_Installation

Locate and edit your distributions .repo file, located:

    /etc/yum.repos.d/CentOS-Base.repo

Add the following line to the [base] and [updates] sections:

    exclude=postgresql*

Get the RPM:

    curl -O http://yum.postgresql.org/9.2/redhat/rhel-6-x86_64/pgdg-centos92-9.2-6.noarch.rpm

Install the RPM distribution:

    rpm -ivh pgdg-centos92-9.2-6.noarch.rpm

Install PostgreSQL 9.2 with contrib modules:

    sudo yum install postgresql postgresql-server postgresql-contrib


(Optional) Change the Postgres data directory by creating/editing the
file `/etc/sysconfig/pgsql/postgresql-9.2` to contain this:

    PGDATA=/opt/pgsql/data
    PGLOG=/opt/pgsql/pgstartup.log

Install PostGIS 2

    curl -O http://mirror.aarnet.edu.au/pub/epel/6/i386/epel-release-6-8.noarch.rpm
    sudo rpm -ivh epel-release-6-8.noarch.rpm
    sudo yum install postgis2_92

Install proj 4.8

    yum install proj

init the DB

    sudo service postgresql-9.2 initdb

start the DB

    sudo service postgresql-9.2 start

Create the Edgar database:

    sudo -u postgres createdb edgar

Setup the DB

    sudo -u postgres psql -d edgar

    CREATE EXTENSION postgis;
    create role edgar_backend with login password 'make_up_password_here';
    create role edgar_frontend with login password 'make_up_password_here';

Fetch a copy of Edgar. In this case, we will fetch it to `~/Edgar`:

    sudo yum install git
    cd ~
    git clone "git://github.com/jcu-eresearch/Edgar.git"

Initialise the database:

    sudo -u postgres psql edgar < ~/Edgar/database_structure.sql

Edit the `pg\_hba.conf` file in the Postgresql data directory. The
default data directory is `/var/lib/pgsql/9.2/data/` on CentOS. The
following config will allow access from `localhost` only. 
Note: If you changed the PGDATA path above, then this config file's location
will move relative to the path you specified.

    local  edgar  edgar_frontend                md5
    local  edgar  edgar_backend                 md5
    host   edgar  edgar_frontend  127.0.0.1/32  md5
    host   edgar  edgar_backend   127.0.0.1/32  md5

Edit the `postgresql.conf` file in the Postgresql data directory. The
default data directory is `/var/lib/pgsql/9.2/data/` on CentOS.
Note: If you changed the PGDATA path above, then this config file's location
will move relative to the path you specified.
Find the line:

    #listen_addresses = 'localhost'

and change it to:

    listen_addresses = '*'

Restart Postgres:

    sudo service postgresql-9.2 restart

Add to auto-start processes:

    sudo chkconfig --add  postgresql-9.2
    sudo chkconfig --level 345 postgresql-9.2 on


Postgres Database - climatebird1.qern.qcif.edu.au (8.4)
==============================================================

This install guide is for <code>yum</code>, tested with CentOS 6.2. Installation also confirmed working with Ubuntu <code>apt-get</code> packages.

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
