include:
  - jcu.apache
  - jcu.php
  - jcu.mapserver
  - jcu.git
  - jcu.postgresql.postgresql92
  - jcu.postgis.postgis2_92

##############################
# EXTENSIONS
##############################

# Update the pg_hba.conf file to be our own
# We define the database connection permissions in the pg_hba.conf

extend:
  /var/lib/pgsql/9.2/data/pg_hba.conf:
    file.managed:
      - name: /var/lib/pgsql/9.2/data/pg_hba.conf
      - user: postgres
      - group: postgres
      - source:
        - salt://edgar_and_climas/map_server/pg_hba.conf
      - require:
        - file: /var/lib/pgsql/9.2/data
        - user: postgres

##############################
# USERS/GROUPS
##############################

# Define the apache user/group before installing the httpd package.
# This gives us an oppurtunity to add the apache user to other groups (if needed).

apache:
  group:
    - present
  user.present:
    - groups:
      - apache
    - require:
      - group: apache
    - require_in:
      - pkg: httpd


# Define the postgres user/group before installing the postgres packages.
# This gives us an oppurtunity to add the postgres user to other groups (if needed).

postgres:
  group:
    - present
  user.present:
    - groups:
      - postgres
    - require:
      - group: postgres
    - require_in:
      - pkg: Install PostgreSQL92 Server Packages


# This is our custom user which will own the repos etc.

map_server:
  group:
    - present
    - gid: {{ pillar['map_server']['uid_gid'] }}
  user.present:
    - fullname: Map Server
    - shell: /bin/bash
    - createhome: true
    - uid: {{ pillar['map_server']['uid_gid'] }}
    - groups:
      - map_server
    - require:
      - group: map_server



##############################
# SET UP DATABASES
##############################

# Ensure our pg_data directory exists, and has the right permissions.
# This dir is needed before we init the database

/var/lib/pgsql/9.2/data:
  file.directory:
    - user: postgres
    - group: postgres
    - mode: 700
    - require_in:
      - cmd: PostgreSQL92 Init DB
      - service: postgresql-9.2
    - require:
      - pkg: Install PostgreSQL92 Server Packages
    - recurse:
      - user
      - group
      - mode

# Copy into place our postgres global settings
# This overrides the default PGDATA directory

/etc/sysconfig/pgsql/postgresql-9.2:
  file.managed:
    - source:
      - salt://edgar_and_climas/map_server/postgresql-9.2.conf
    - user: root
    - group: root
    - mode: 744
    - require_in:
      - cmd: PostgreSQL92 Init DB
#    - require:
#      - service: autofs


# Ensure the .pgpass file exists (we need to do this before we can use
# the append state)

touch /var/lib/pgsql/.pgpass:
  file.managed:
      - name: /var/lib/pgsql/.pgpass
      - owner: postgres
      - mode: 600
      - require:
        - service: postgresql-9.2


# Create the edgar_on_rails postgres user

edgar_on_rails:
  postgres_user.present:
    - user: postgres
    - password: {{pillar['database']['edgar_password']}}
    - require:
      - pkg: Install PostGIS2_92 Packages
      - cmd: PostgreSQL92 Init DB
      - pkg: Install PostGIS2_92 Packages
      - service: postgresql-9.2


# Add climas to postgres

climas:
  postgres_user.present:
    - user: postgres
    - password: {{pillar['database']['climas_password']}}
    - require:
      - pkg: Install PostGIS2_92 Packages
      - pkg: Install PostGIS2_92 Packages
      - cmd: PostgreSQL92 Init DB
      - service: postgresql-9.2


# Add climas database to postgres

climas_production:
  postgres_database.present:
    - user: postgres
    - owner: climas
    - require:
      - postgres_user: climas
      - file: /var/lib/pgsql/.pgpass climas_production

# Set up each of our edgar databases

{% for db in 'edgar_on_rails_dev_db','edgar_on_rails_test_db','edgar_on_rails_prod_db' %}


# Add each user/database/password combo t the pgpass file.
# This makes these databases passwordless for local connections.

/var/lib/pgsql/.pgpass {{db}}:
  file.append:
      - name: /var/lib/pgsql/.pgpass
      - text: 127.0.0.1:5432:{{db}}:edgar_on_rails:{{pillar['database']['edgar_password']}}
      - require:
        - file: touch /var/lib/pgsql/.pgpass


# Create the database

{{ db }}:
  postgres_database.present:
    - user: postgres
    - owner: edgar_on_rails
    - require:
      - postgres_user: edgar_on_rails
      - file: /var/lib/pgsql/.pgpass {{db}}


# Install the postgis extension

psql -d {{ db }} -c "CREATE EXTENSION postgis;":
  cmd.wait:
    - user: postgres
    - watch:
      - cmd: PostgreSQL92 Init DB
    - require:
      - pkg: Install PostGIS2_92 Packages
      - postgres_database: {{ db }}


# Install the topology extension

psql -d {{ db }} -c "CREATE EXTENSION postgis_topology;":
  cmd.wait:
    - user: postgres
    - watch:
      - cmd: PostgreSQL92 Init DB
    - require:
      - cmd: psql -d {{ db }} -c "CREATE EXTENSION postgis;"

# Don't install the database structure ourself, let the applications VM install
# process migrate the database into place.

#psql -U edgar_on_rails -h 127.0.0.1 -d {{ db }} < /home/map_server/Edgar/webapplication/db/development_structure.sql:
#  cmd.wait:
#    - user: postgres
#    - cwd: /home/map_server/Edgar/webapplication
#    - watch:
#      - cmd: PostgreSQL92 Init DB
#    - require:
#      - pkg: Install PostGIS2_92 Packages
#      - postgres_database: {{ db }}
#      - cmd: psql -d {{ db }} -c "CREATE EXTENSION postgis_topology;"
#      - cmd: psql -d {{ db }} -c "CREATE EXTENSION postgis;"
#      - file: /home/map_server/Edgar
#      - git: /home/map_server/Edgar
#      - file: /home/map_server

{% endfor %}


# Add password for climas database to pgpass

/var/lib/pgsql/.pgpass climas_production:
  file.append:
      - name: /var/lib/pgsql/.pgpass
      - text: 127.0.0.1:5432:climas_production:climas:{{pillar['database']['climas_password']}}
      - require:
        - file: touch /var/lib/pgsql/.pgpass


# Copy the climas DB init script to tmp

copy /tmp/init_climas_db_file:
  file.copy:
    - name: /tmp/init_climas_db_file
    - source: /home/map_server/climas/applications/DB/init_db.sql
    - force: true
    - require:
      - pkg: Install PostGIS2_92 Packages
      - git: climas_www /home/map_server/climas


# Make postgres the owner of the climas DB init script

/tmp/init_climas_db_file:
  file.managed:
    - owner: postgres
    - mode: 700
    - required:
      - file: copy /tmp/init_climas_db_file


# Init the climas_production databse
# Only do this when we first init the postgresql db
# (i.e. watch for the PostgreSQL92 Init DB state)

psql climas_production < /tmp/init_climas_db_file:
  cmd.wait:
    - user: postgres
    - watch:
      - cmd: PostgreSQL92 Init DB
    - require:
      - postgres_user: climas
      - postgres_database: climas_production
      - file: /tmp/init_climas_db_file


# Add postgres to our firewall

postgres add to firewall:
  module.run:
    - name: iptables.insert
    - table: filter
    - chain: INPUT
    - position: 3
    - rule: -p tcp --dport 5432 -j ACCEPT
    - watch_in:
      - module: save postgres iptables


# Save the firewall changes

save postgres iptables:
  module.run:
    - name: iptables.save
    - filename: /etc/sysconfig/iptables


# Make sure postgres listens on all interfaces
# (i.e. listen for external requests)

/var/lib/pgsql/9.2/data/postgresql.conf:
  file.append:
    - text: "listen_addresses='*'"
    - watch_in:
      - service: postgresql-9.2
    - require:
      - file: /var/lib/pgsql/9.2/data
      - cmd: PostgreSQL92 Init DB


#########################
# END DATABASE SECTION
#########################


#########################
# Install Edgar
#########################

/home/map_server/Edgar:
  git.latest:
    - name: https://github.com/jcu-eresearch/Edgar.git
    - rev: Edgar_On_Rails
    - target: /home/map_server/Edgar
    - user: map_server
    - require:
      - user: map_server
      - pkg: git

#/home/map_server:
#  file.directory:
#    - user: map_server
#    - group: map_server
#    - dir_mode: 751
#    - file_mode: "640"
#    - recurse:
#      - user
#      - group
#      - mode
#    - require:
#      - user: map_server
#      - git: /home/map_server/Edgar


# Link MapServer mapping into apache

/var/www/html/edgar_mapping:
  file.symlink:
    - target: /home/map_server/Edgar/mapping
    - require:
      - git: /home/map_server/Edgar

#/var/www/html/Edgar:
#  file.symlink:
#    - target: /home/map_server/Edgar/mapping
#    - require:
#      - git: /home/map_server/Edgar


#########################
# Install CLIMAS
#########################

# Clone TDH-Tools
climas_www /home/map_server/climas:
  git.latest:
    - name: https://github.com/jcu-eresearch/TDH-Tools.git
    - target: /home/map_server/climas
    - user: map_server
    - require:
      - user: map_server
      - pkg: git


# Link climas applications into place

/var/www/html/climas:
  file.symlink:
    - target: /home/map_server/climas/applications
    - require:
      - git: climas_www /home/map_server/climas

# Link climas reportdata into place

/var/www/html/climas/reportdata:
  file.symlink:
    - target: /home/map_server/sync_dir/reports
    - require:
      - git: climas_www /home/map_server/climas
      - file: /var/www/html/climas



/var/www/html/data:
  file.symlink:
    - target: /home/map_server/sync_dir
    - require:
      - git: climas_www /home/map_server/climas
      - service: httpd

/var/www/html/images:
  file.symlink:
    - target: /home/map_server/climas/images
    - require:
      - git: climas_www /home/map_server/climas
      - service: httpd

remove /var/www/icons:
  file.absent:
    - name: /var/www/icons

/var/www/icons:
  file.symlink:
    - target: /home/map_server/climas/Resources/icons
    - require:
      - file: remove /var/www/icons
      - git: climas_www /home/map_server/climas
      - service: httpd

/var/www/html/climas/MapserverImages:
  file.symlink:
    - target: /home/map_server/climas/tmp/MapserverImages
    - require:
      - git: climas_www /home/map_server/climas
      - service: httpd

copy /home/map_server/climas/applications/CONFIGURATION.cfg:
  file.copy:
    - name: /home/map_server/climas/applications/CONFIGURATION.cfg
    - source: /home/map_server/climas/applications/CONFIGURATION.cfg.default
    - force: true
    - require:
      - git: climas_www /home/map_server/climas

update file_paths /home/map_server/climas/applications/CONFIGURATION.cfg:
  file.replace:
    - name: /home/map_server/climas/applications/CONFIGURATION.cfg
    - pattern: '"/climas/'
    - repl: '"/home/map_server/climas/'
    - require:
      - file: copy /home/map_server/climas/applications/CONFIGURATION.cfg

update source_data_path /home/map_server/climas/applications/CONFIGURATION.cfg:
  file.replace:
    - name: /home/map_server/climas/applications/CONFIGURATION.cfg
    - pattern: '"/home/map_server/climas/data/'
    - repl: '"/home/map_server/sync_dir/'
    - require:
      - file: copy /home/map_server/climas/applications/CONFIGURATION.cfg

update sdm_path /home/map_server/climas/applications/CONFIGURATION.cfg:
  file.replace:
    - name: /home/map_server/climas/applications/CONFIGURATION.cfg
    - pattern: '"/home/map_server/climas/sdm/'
    - repl: '"/home/map_server/sync_dir/SDM/'
    - require:
      - file: copy /home/map_server/climas/applications/CONFIGURATION.cfg

update hostname /home/map_server/climas/applications/CONFIGURATION.cfg:
  file.replace:
    - name: /home/map_server/climas/applications/CONFIGURATION.cfg
    - pattern: localhost
    - repl: {{ pillar['applications']['edgar_ip'] }}
    - require:
      - file: copy /home/map_server/climas/applications/CONFIGURATION.cfg

update reports url /home/map_server/climas/applications/CONFIGURATION.cfg:
  file.replace:
    - name: /home/map_server/climas/applications/CONFIGURATION.cfg
    - pattern: bifocal
    - repl: climas/reports
    - require:
      - file: copy /home/map_server/climas/applications/CONFIGURATION.cfg

/home/map_server/climas/applications/CONFIGURATION.cfg:
  file.managed:
    - owner: map_server
    - mode: 640
    - required:
      - file: update file_paths /climas/source/applications/CONFIGURATION.cfg
      - file: update source_data_path /home/map_server/climas/applications/CONFIGURATION.cfg
      - file: update hostname /climas/source/applications/CONFIGURATION.cfg
      - file: update reports url /climas/source/applications/CONFIGURATION.cfg
      - file: update sdm_path /home/map_server/climas/applications/CONFIGURATION.cfg

/var/www/cgi-bin/mapserv:
  file.copy:
    - source: /usr/libexec/mapserver
    - force: true
    - require:
      - pkg: mapserver

/home/map_server/climas/output/MapserverImages:
  file.directory:
    - makedirs: true
    - recurse:
      - mode
      - user
      - group
    - dir_mode: 777
    - file_mode: 666
    - user: map_server
    - group: map_server
    - require:
#      - service: autofs
      - git: climas_www /home/map_server/climas

/var/www/html/climas/output:
  file.symlink:
    - target: /home/map_server/climas/output
    - require:
#      - service: autofs
      - git: climas_www /home/map_server/climas
      - file: /var/www/html/climas
      - file: /home/map_server/climas/output/MapserverImages

/home/TDH/data:
  file.directory:
    - makedirs: true
    - recurse:
      - mode
      - user
      - group
    - dir_mode: 751
    - file_mode: "640"
    - user: map_server
    - group: map_server

/home/TDH/data/SDM:
  file.symlink:
    - target: /home/map_server/sync_dir/SDM
    - user: map_server
    - group: map_server
    - require:
      - file: /home/TDH/data
#      - service: autofs

/home/map_server/Edgar/importing/bin/:
  file.directory:
    - user: map_server
    - group: map_server
    - dir_mode: 751
    - file_mode: 751
    - recurse:
      - user
      - group
      - mode
    - require:
#      - file: /home/map_server
      - git: /home/map_server/Edgar

/home/map_server/Edgar/modelling/bin/:
  file.directory:
    - user: map_server
    - group: map_server
    - dir_mode: 751
    - file_mode: 751
    - recurse:
      - user
      - group
      - mode
    - require:
#      - file: /home/map_server
      - git: /home/map_server/Edgar
