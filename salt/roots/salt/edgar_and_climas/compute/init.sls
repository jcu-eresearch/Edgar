include:
  - jcu.git
  - jcu.supervisord
  - jcu.postgresql.postgresql92.client
  - jcu.repositories.pgdg.pgdg92
  - jcu.repositories.epel

#########################
# Dependencies
#########################

compute requirements:
  pkg.installed:
    - pkgs:
      - git
      - wget
      - geos
      - gdal
      - python
      - python-devel
      - postgresql-libs
    - require:
      - pkg: epel
      - pkg: pgdg-92

#########################
# Users / Groups
#########################

compute:
  group:
    - present
    - gid: {{ pillar['compute']['uid_gid'] }}
  user.present:
    - fullname: Compute
    - shell: /bin/bash
    - createhome: true
    - uid: {{ pillar['compute']['uid_gid'] }}
    - groups:
      - compute
    - require:
      - group: compute

#########################
# Set up Directories
#########################

/home/compute/tmp:
  file.directory:
    - user: compute
    - group: compute
    - makedirs: True
  require:
    - user: compute

/var/log/supervisord:
  file.directory

#########################
# Get the Code
#########################

/home/compute/Edgar:
  git.latest:
    - name: https://github.com/jcu-eresearch/Edgar.git
    - rev: Edgar_On_Rails
    - target: /home/compute/Edgar
    - user: compute
    - require:
      - user: compute
      - pkg: git

#########################
# Set up the Virt. Env.
#########################

compute get virtual env:
  cmd.run:
    - name: wget https://pypi.python.org/packages/source/v/virtualenv/virtualenv-{{ pillar['virtualenv']['version'] }}.tar.gz {{ pillar['python']['wget_flags'] }}
    - user: compute
    - group: compute
    - cwd: /home/compute/tmp/
    - require:
      - user: compute
      - pkg: compute requirements
      - file: /home/compute/tmp
    - unless: test -d /home/compute/Edgar/tmp/env

compute extract virtual env:
  cmd.wait:
    - name: tar xvfz virtualenv-{{ pillar['virtualenv']['version'] }}.tar.gz
    - cwd: /home/compute/tmp/
    - user: compute
    - watch:
      - cmd: compute get virtual env

install compute virtual env:
  cmd.wait:
    - name: python /home/compute/tmp/virtualenv-{{ pillar['virtualenv']['version'] }}/virtualenv.py env
    - cwd: /home/compute/Edgar
    - user: compute
    - require:
      - service: kill supervisord
      - git: /home/compute/Edgar
    - watch:
      - cmd: compute extract virtual env

#########################
# Install importing code
#########################

compute setup.py install:
  cmd.wait:
    - cwd: /home/compute/Edgar/importing/
    - name: ../env/bin/python setup.py install
    - user: compute
    - require:
      - cmd: install compute virtual env
      - git: /home/compute/Edgar

compute bootstrap:
  cmd.run:
    - cwd: /home/compute/Edgar/importing
    - user: compute
    - name: ../env/bin/python bootstrap.py
    - require:
      - cmd: install compute virtual env
      - git: /home/compute/Edgar

# Install several eggs manually...
#
# Ideally these would happen as part of the buildout process.
# Due to the split in the modelling and importing processes,
# these eggs need to be installed priort to the importing buildout.
#
# If you remove these egg installs, the modelling won't be able to
# find the eggs (as they will be in the buildout, but not in the virt. env)
compute install psycopg2:
  cmd.run:
    - cwd: /home/compute/Edgar/importing
    - user: compute
    - name: ../env/bin/pip install psycopg2
    - require:
      - cmd: install compute virtual env
      - git: /home/compute/Edgar

compute install SQLAlchemy:
  cmd.run:
    - cwd: /home/compute/Edgar/importing
    - user: compute
    - name: ../env/bin/pip install SQLAlchemy==0.8.4
    - require:
      - cmd: compute install psycopg2

compute install GeoAlchemy:
  cmd.run:
    - cwd: /home/compute/Edgar/importing
    - user: compute
    - name: ../env/bin/pip install GeoAlchemy==0.7.2
    - require:
      - cmd: compute install SQLAlchemy

compute buildout:
  cmd.run:
    - cwd: /home/compute/Edgar/importing
    - user: compute
    - name: ./bin/buildout
    - require:
      - cmd: compute bootstrap
      - file: /etc/supervisord.conf
      - pkg: Install PostgreSQL92 Client Packages
      - git: /home/compute/Edgar
      - cmd: compute install GeoAlchemy
    - watch_in:
      - service: supervisord

#########################
# Install supervisor
#########################

yum install supervisor -y:
  cmd.run:
    - user: root
    - require_in:
      - pkg: supervisor
    - require:
      - pkgrepo: jcu-eresearch

/etc/supervisord.conf:
  file.symlink:
    - target: /home/compute/Edgar/modelling/supervisord/supervisord.conf
    - force: true
    - require:
      - cmd: compute bootstrap
      - file: /var/log/supervisord
      - git: /home/compute/Edgar

#########################
# Open up port 9001
#########################

iptables 9001:
  module.run:
    - name: iptables.insert
    - table: filter
    - chain: INPUT
    - position: 3
    - rule: -p tcp -m state --state NEW -m tcp --dport 9001 -j ACCEPT
    - require_in:
      - module: save iptables

save iptables:
  module.run:
    - name: iptables.save
    - filename: /etc/sysconfig/iptables

#########################
# Update modelling config
#########################

update hpc_config base url:
  file.replace:
    - name: /home/compute/Edgar/modelling/src/hpc_config.py
    - pattern: cakeAppBaseURL = "http://130.102.155.18/edgar"
    - repl: cakeAppBaseURL = "{{pillar['applications']['edgar_base_url']}}"
    - require:
      - git: /home/compute/Edgar
    - watch_in:
      - service: supervisord

#########################
# Update importing config
#########################

copy importing config:
  file.copy:
    - name: /home/compute/Edgar/importing/config.json
    - source: /home/compute/Edgar/importing/config.example.json
    - user: compute
    - group: compute
    - mode: 640
    - require:
      - git: /home/compute/Edgar

update importing database:
  file.replace:
    - name: /home/compute/Edgar/importing/config.json
    - pattern: '"db.url": "postgresql\+psycopg2://edgar_backend:backend_password_here@/edgar"'
    - repl: '"db.url": "postgresql+psycopg2://edgar_on_rails:{{pillar['database']['edgar_password']}}@{{pillar['database']['host']}}:5432/edgar_on_rails_prod_db"'
    - require:
      - file: copy importing config
    - watch_in:
      - service: supervisord

update importing api_key:
  file.replace:
    - name: /home/compute/Edgar/importing/config.json
    - pattern: '"alaApiKey": null'
    - repl: '"alaApiKey": "{{pillar['ala']['api_key']}}"'
    - require:
      - file: copy importing config
    - watch_in:
      - service: supervisord

#update importing ala_sync_url:
#  file.replace:
#    - name: /home/compute/Edgar/importing/config.json
#    - pattern: '"alaVettingSyncUrl": null'
#    - repl: '"alaVettingSyncUrl": "{{pillar['ala']['vetting_sync_url']}}"'
#    - require:
#      - file: copy importing config
#    - watch_in:
#      - service: supervisord

/home/compute/Edgar/importing/bin/ala_cron.sh:
  file.replace:
    - name: /home/compute/Edgar/importing/bin/ala_cron.sh
    - pattern: 'IMPORTER_DIR="/home/compute/Edgar/importing"'
    - repl: 'IMPORTER_DIR="/home/compute/Edgar/importing"'
    - require:
      - git: /home/compute/Edgar
  cron.present:
    - user: compute
    # this is weekly
    - dayweek: 0
    - minute: 0
    - hour: 0
    - require:
      - file: /home/compute/Edgar/importing/bin/ala_cron.sh

#########################
# Update file perm's
#########################

/home/compute/Edgar/env/bin:
  file.directory:
    - user: compute
    - group: compute
    - dir_mode: 751
    - file_mode: 751
    - recurse:
      - user
      - group
      - mode
    - require:
      - git: /home/compute/Edgar

/home/compute/Edgar/importing/bin/:
  file.directory:
    - user: compute
    - group: compute
    - dir_mode: 751
    - file_mode: 751
    - recurse:
      - user
      - group
      - mode
    - require:
      - git: /home/compute/Edgar

/home/compute/Edgar/modelling/bin/:
  file.directory:
    - user: compute
    - group: compute
    - dir_mode: 751
    - file_mode: 751
    - recurse:
      - user
      - group
      - mode
    - require:
      - git: /home/compute/Edgar

#########################
# Helper Actions
#########################

kill supervisord:
  service:
    - name: supervisord
    - dead
    - require:
      - pkg: supervisor

