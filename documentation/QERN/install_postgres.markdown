Postgres Database - climatebird1.qern.qcif.edu.au
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
