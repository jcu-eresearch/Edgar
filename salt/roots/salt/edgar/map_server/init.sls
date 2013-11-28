include:
  - jcu.apache
  - jcu.php
  - jcu.mapserver
  - jcu.git
  - jcu.postgresql.postgresql92
  - jcu.postgis.postgis2_92
  - edgar.mount

extend:
  /var/lib/pgsql/9.2/data/pg_hba.conf:
    file.managed:
      - name: /mnt/edgar_data/Edgar/pg_data/pg_hba.conf
      - user: postgres
      - group: postgres
      - source:
        - salt://edgar/map_server/pg_hba.conf
      - require:
        - file: /mnt/edgar_data/Edgar/pg_data
        - user: postgres

climas_www /mnt/edgar_data/climas:
  file.directory:
    - recurse:
      - mode
    - dir_mode: 751
    - file_mode: 640
    - name: /mnt/edgar_data/climas
    - user: map_server
    - group: map_server
    - require:
      - service: autofs
      - user: map_server

postgres:
  group:
    - present
  user.present:
    - groups:
      - nectar_mount_user
      - postgres
    - require:
      - group: nectar_mount_user
      - group: postgres
    - require_in:
      - pkg: Install PostgreSQL92 Server Packages

/mnt/edgar_data/Edgar/pg_data:
  file.directory:
    - user: postgres
    - group: postgres
    - mode: 700
    - require_in:
      - cmd: PostgreSQL92 Init DB
      - service: postgresql-9.2
    - require:
      - pkg: Install PostgreSQL92 Server Packages
      - file: map_server /mnt/edgar_data/Edgar
    - recurse:
      - user
      - group
      - mode

/etc/sysconfig/pgsql/postgresql-9.2:
  file.managed:
    - source:
      - salt://edgar/map_server/postgresql-9.2.conf
    - user: root
    - group: root
    - mode: 744
    - require_in:
      - cmd: PostgreSQL92 Init DB
    - require:
      - service: autofs

map_server /mnt/edgar_data/Edgar:
  file.directory:
    - name: /mnt/edgar_data/Edgar
    - user: map_server
    - group: map_server
    - mode: 771
    - require:
      - service: autofs
      - user: map_server
#      - file: root /mnt/edgar_data/Edgar

map_server clone edgar:
  git.latest:
    - name: https://github.com/jcu-eresearch/Edgar.git
    - rev: Edgar_On_Rails
    - target: /mnt/edgar_data/Edgar/repo
    - user: map_server
    - require:
      - user: map_server
      - pkg: git
      - file: map_server /mnt/edgar_data/Edgar

/home/map_server/Edgar:
  file.symlink:
    - target: /mnt/edgar_data/Edgar/repo
    - user: map_server
    - group: map_server
    - require:
      - service: autofs
      - git: map_server clone edgar

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
      - nectar_mount_user
    - require:
      - group: map_server
      - group: nectar_mount_user

/home/map_server:
  file.directory:
    - user: map_server
    - group: map_server
    - dir_mode: 755
    - file_mode: 644
    - recurse:
      - user
      - group
      - mode
    - require:
      - user: map_server
      - file: /home/map_server/Edgar
      - git: map_server clone edgar

/var/www/html/Edgar:
  file.symlink:
    - target: /home/map_server/Edgar/mapping
    - require:
      - file: /home/map_server/Edgar
      - git: map_server clone edgar

edgar_on_rails:
  postgres_user.present:
    - user: postgres
    - password: {{pillar['database']['edgar_password']}}
    - require:
      - pkg: Install PostGIS2_92 Packages
      - cmd: PostgreSQL92 Init DB
      - service: postgresql-9.2

yum update -y:
  cmd.run:
    - user: root

touch /var/lib/pgsql/.pgpass:
  file.managed:
      - name: /var/lib/pgsql/.pgpass
      - owner: postgres
      - mode: 600
      - prereq:
        - cmd: yum update -y
      - require:
        - service: postgresql-9.2

{% for db in 'edgar_on_rails_dev_db','edgar_on_rails_test_db','edgar_on_rails_prod_db' %}

/var/lib/pgsql/.pgpass {{db}}:
  file.append:
      - name: /var/lib/pgsql/.pgpass
      - text: 127.0.0.1:5432:{{db}}:edgar_on_rails:{{pillar['database']['edgar_password']}}
      - require:
        - file: touch /var/lib/pgsql/.pgpass

{{ db }}:
  postgres_database.present:
    - user: postgres
    - owner: edgar_on_rails
    - require:
      - postgres_user: edgar_on_rails
      - file: /var/lib/pgsql/.pgpass {{db}}

psql -d {{ db }} -c "CREATE EXTENSION postgis;":
  cmd.wait:
    - user: postgres
    - watch:
      - cmd: PostgreSQL92 Init DB
    - require:
      - pkg: Install PostGIS2_92 Packages
      - postgres_database: {{ db }}

psql -d {{ db }} -c "CREATE EXTENSION postgis_topology;":
  cmd.wait:
    - user: postgres
    - watch:
      - cmd: PostgreSQL92 Init DB
    - require:
      - pkg: Install PostGIS2_92 Packages
      - postgres_database: {{ db }}

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
#      - git: map_server clone edgar
#      - file: /home/map_server

{% endfor %}

# Add climas to postgres
climas:
  postgres_user.present:
    - user: postgres
    - password: {{pillar['database']['climas_password']}}
    - require:
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

# Add password for climas database to pgpass
/var/lib/pgsql/.pgpass climas_production:
  file.append:
      - name: /var/lib/pgsql/.pgpass
      - text: 127.0.0.1:5432:climas_production:climas:{{pillar['database']['climas_password']}}
      - require:
        - file: touch /var/lib/pgsql/.pgpass

# Clone TDH-Tools
climas_www clone tdh-tools:
  git.latest:
    - name: https://github.com/jcu-eresearch/TDH-Tools.git
    - target: /mnt/edgar_data/climas/source
    - user: map_server
    - require:
      - user: map_server
      - pkg: git
      - file: climas_www /mnt/edgar_data/climas

copy /tmp/init_climas_db_file:
  file.copy:
    - name: /tmp/init_climas_db_file
    - source: /mnt/edgar_data/climas/source/applications/DB/init_db.sql
    - force: true
    - require:
      - pkg: Install PostGIS2_92 Packages
      - git: climas_www clone tdh-tools

/tmp/init_climas_db_file:
  file.managed:
    - owner: postgres
    - mode: 700
    - required:
      - file: copy /tmp/init_climas_db_file

# Init the climas_production databse
# Only do this when we first init the postgresql db
psql climas_production < /tmp/init_climas_db_file:
  cmd.wait:
    - user: postgres
    - watch:
      - cmd: PostgreSQL92 Init DB
    - require:
      - postgres_user: climas
      - postgres_database: climas_production
      - file: /tmp/init_climas_db_file

postgres add to firewall:
  module.run:
    - name: iptables.insert
    - table: filter
    - chain: INPUT
    - position: 3
    - rule: -p tcp --dport 5432 -j ACCEPT
    - watch_in:
      - module: save postgres iptables

save postgres iptables:
  module.run:
    - name: iptables.save
    - filename: /etc/sysconfig/iptables

/mnt/edgar_data/Edgar/pg_data/postgresql.conf:
  file.append:
    - text: "listen_addresses='*'"
    - watch_in:
      - service: postgresql-9.2
    - require:
      - file: /mnt/edgar_data/Edgar/pg_data
      - cmd: PostgreSQL92 Init DB
