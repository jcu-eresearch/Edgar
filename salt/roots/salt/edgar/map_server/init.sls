{% set edgar_db_password = 'password' %}

include:
  - jcu.apache
  - jcu.php
  - jcu.mapserver
  - jcu.git
  - jcu.postgresql.postgresql92
  - jcu.postgis.postgis2_92

extend:
  /var/lib/pgsql/9.2/data/pg_hba.conf:
    file.managed:
      - name: /tmp/pg_data/pg_hba.conf
      - source:
        - salt://edgar/map_server/pg_hba.conf

/etc/sysconfig/pgsql/postgresql-9.2:
  file.managed:
    - source:
      - salt://edgar/map_server/postgresql-9.2.conf
    - user: root
    - group: root
    - mode: 744
    - require_in:
      - cmd: PostgreSQL92 Init DB


map_server:
  user.present:
    - fullname: Map Server
    - shell: /bin/bash
    - createhome: true
    - gid_from_name: true

map_server clone edgar:
  git.latest:
    - name: https://github.com/jcu-eresearch/Edgar.git
    - target: /home/map_server/Edgar
    - user: map_server
    - rev: Edgar_On_Rails
    - require:
      - user: map_server
      - pkg: git

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
      - git: map_server clone edgar

/var/www/html/Edgar:
  file.symlink:
    - target: /home/map_server/Edgar/mapping
    - require:
      - git: map_server clone edgar

edgar_on_rails:
  postgres_user.present:
    - user: postgres
    - password: {{edgar_db_password}}
    - require:
      - pkg: Install PostGIS2_92 Packages
      - cmd: PostgreSQL92 Init DB
      - service: postgresql-9.2

{% for db in 'edgar_on_rails_dev_db','edgar_on_rails_test_db','edgar_on_rails_prod_db' %}

touch /var/lib/pgsql/.pgpass {{db}}:
  file.managed:
      - name: /var/lib/pgsql/.pgpass
      - owner: postgres
      - mode: 600

/var/lib/pgsql/.pgpass {{db}}:
  file.append:
      - name: /var/lib/pgsql/.pgpass
      - text: 127.0.0.1:5432:{{db}}:edgar_on_rails:{{edgar_db_password}}
      - require:
        - file: touch /var/lib/pgsql/.pgpass {{db}}

{{ db }}:
  postgres_database.present:
    - user: postgres
    - owner: edgar_on_rails
    - require:
      - postgres_user: edgar_on_rails
      - file: /var/lib/pgsql/.pgpass {{db}}

psql -U edgar_on_rails -h 127.0.0.1 -d {{ db }} -c "CREATE EXTENSION postgis;":
  cmd.wait:
    - user: postgres
    - watch:
      - cmd: PostgreSQL92 Init DB
    - require:
      - pkg: Install PostGIS2_92 Packages
      - postgres_database: {{ db }}

psql -U edgar_on_rails -h 127.0.0.1 -d {{ db }} -c "CREATE EXTENSION postgis_topology;":
  cmd.wait:
    - user: postgres
    - watch:
      - cmd: PostgreSQL92 Init DB
    - require:
      - pkg: Install PostGIS2_92 Packages
      - postgres_database: {{ db }}

psql -U edgar_on_rails -h 127.0.0.1 -d {{ db }} < /home/map_server/Edgar/webapplication/db/development_structure.sql:
  cmd.wait:
    - user: postgres
    - cwd: /home/map_server/Edgar/webapplication
    - watch:
      - cmd: PostgreSQL92 Init DB
    - require:
      - pkg: Install PostGIS2_92 Packages
      - postgres_database: {{ db }}
      - cmd: psql -U edgar_on_rails -h 127.0.0.1 -d {{ db }} -c "CREATE EXTENSION postgis_topology;"
      - cmd: psql -U edgar_on_rails -h 127.0.0.1 -d {{ db }} -c "CREATE EXTENSION postgis;"
      - git: map_server clone edgar
      - file: /home/map_server

{% endfor %}

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

/tmp/pg_data/postgresql.conf:
  file.append:
    - text: "listen_addresses='*'"
    - watch_in:
      - service: postgresql-9.2
