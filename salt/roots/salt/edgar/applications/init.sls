include:
  - jcu.postgresql.postgresql92
  - jcu.postgis.postgis2_92
  - jcu.git
  - jcu.ruby.rvm.ruby_1_9_3.passenger

applications:
  user.present:
    - fullname: Applications
    - shell: /bin/bash
    - createhome: true
    - gid_from_name: true

applications clone edgar:
  git.latest:
    - name: https://github.com/jcu-eresearch/Edgar.git
    - rev: Edgar_On_Rails
    - target: /home/applications/Edgar
    - runas: applications
    - require:
      - user: applications
      - pkg: git

/home/applications:
  file.directory:
    - user: applications
    - group: applications
    - dir_mode: 755
    - file_mode: 644
    - recurse:
      - user
      - group
      - mode
    - require:
      - user: applications
      - git: applications clone edgar

bundle install --deployment:
  module.run:
    - name: rvm.do
    - ruby: ruby-1.9.3
    - runas: rvm
    - command: bundle install --gemfile=/home/applications/Edgar/webapplication/Gemfile
    - require:
      - gem: bundler
      - git: applications clone edgar
      - file: /home/applications

/usr/local/nginx/conf/conf.d/edgar.conf:
  file.managed:
    - source:
      - salt://edgar/applications/edgar_nginx_config.conf
    - user: rvm
    - group: rvm
    - mode: 740
    - require:
      - file: /usr/local/nginx/conf/conf.d
    - watch_in:
      - service: nginx

/home/applications/webapplications:
  file.directory:
    - user: applications
    - group: applications
    - dir_mode: 755
    - file_mode: 644
    - require:
      - user: applications

/home/applications/webapplications/edgar:
  file.symlink:
    - target: /home/applications/Edgar/webapplication/public
    - require:
      - file: /home/applications/webapplications

edgar_on_rails:
  postgres_user.present:
    - runas: postgres
    - password: password
    - require:
      - pkg: Install PostGIS2_92 Packages
      - cmd: PostgreSQL92 Init DB
      - service: postgresql-9.2

{% for db in 'edgar_on_rails_dev_db','edgar_on_rails_test_db','edgar_on_rails_prod_db' %}

{{ db }}:
  postgres_database.present:
    - runas: postgres
    - owner: edgar_on_rails
    - require:
      - postgres_user: edgar_on_rails

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

psql -d {{ db }} < /home/applications/Edgar/webapplication/db/development_structure.sql:
  cmd.wait:
    - user: postgres
    - cwd: /home/applications/Edgar/webapplication
    - watch:
      - cmd: PostgreSQL92 Init DB
    - require:
      - pkg: Install PostGIS2_92 Packages
      - postgres_database: {{ db }}
      - cmd: psql -d {{ db }} -c "CREATE EXTENSION postgis_topology;"
      - cmd: psql -d {{ db }} -c "CREATE EXTENSION postgis;"
      - git: applications clone edgar
      - file: /home/applications

{% endfor %}
