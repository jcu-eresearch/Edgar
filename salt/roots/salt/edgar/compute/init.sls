include:
  - jcu.git
  - jcu.supervisord
  - jcu.python.python_2_7
  - jcu.postgresql.postgresql92.client
  - edgar.mount

compute packages:
  pkg.installed:
    - pkgs:
      - R
    - watch_in:
      - service: supervisord

kill supervisord:
  service:
    - name: supervisord
    - dead
    - require:
      - pkg: supervisor

compute clone edgar:
  git.latest:
    - name: https://github.com/jcu-eresearch/Edgar.git
    - rev: Edgar_On_Rails
    - target: /mnt/edgar_data/Edgar/repo
    - user: compute
    - require:
      - user: compute
      - pkg: git
      - file: compute /mnt/edgar_data/Edgar

compute /mnt/edgar_data/Edgar:
  file.directory:
    - name: /mnt/edgar_data/Edgar
    - user: compute
    - group: compute
    - require:
      - service: autofs
      - user: compute
#      - file: root /mnt/edgar_data/Edgar

compute requirements:
  pkg.installed:
    - pkgs:
      - git
      - wget
      - geos
  require:
    - cmd: python_2_7 make && make altinstall

/home/compute/Edgar:
  file.symlink:
    - target: /mnt/edgar_data/Edgar/repo
    - makedirs: True
    - user: compute
    - group: compute
    - require:
      - service: autofs
      - git: compute clone edgar

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
      - nectar_mount_user
    - require:
      - group: compute
      - group: nectar_mount_user

/home/compute/tmp:
  file.directory:
    - user: compute
    - group: compute
    - makedirs: True
  require:
    - user: compute

/var/log/supervisord:
  file.directory

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
    - name: python2.7 /home/compute/tmp/virtualenv-{{ pillar['virtualenv']['version'] }}/virtualenv.py env
    - cwd: /home/compute/Edgar
    - user: compute
    - require:
      - file: /home/compute/Edgar
      - cmd: python_2_7 make && make altinstall
      - service: kill supervisord
      - git: compute clone edgar
    - watch:
      - cmd: compute extract virtual env

compute setup.py install:
  cmd.wait:
    - cwd: /home/compute/Edgar/importing/
    - name: ../env/bin/python setup.py install
    - user: compute
    - require:
      - cmd: install compute virtual env
      - file: /home/compute/Edgar
      - git: compute clone edgar

compute bootstrap:
  cmd.run:
    - cwd: /home/compute/Edgar/importing
    - user: compute
    - name: ../env/bin/python bootstrap.py
    - require:
      - cmd: install compute virtual env
      - file: /home/compute/Edgar
      - git: compute clone edgar

compute install GeoAlchemy:
  cmd.run:
    - cwd: /home/compute/Edgar/importing
    - user: compute
    - name: ../env/bin/pip install GeoAlchemy
    - require:
      - cmd: install compute virtual env
      - file: /home/compute/Edgar
      - git: compute clone edgar

compute install psycopg2:
  cmd.run:
    - cwd: /home/compute/Edgar/importing
    - user: compute
    - name: ../env/bin/pip install psycopg2
    - require:
      - cmd: install compute virtual env
      - file: /home/compute/Edgar
      - git: compute clone edgar
      - pkg: Install PostgreSQL92 Client Packages

compute buildout:
  cmd.run:
    - cwd: /home/compute/Edgar/importing
    - user: compute
    - name: ./bin/buildout
    - require:
      - cmd: compute bootstrap
      - file: /home/compute/Edgar
      - file: /etc/supervisord.conf
      - pkg: Install PostgreSQL92 Client Packages
      - git: compute clone edgar
      - cmd: compute install GeoAlchemy
      - cmd: compute install psycopg2
    - watch_in:
      - service: supervisord


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
      - file: /home/compute/Edgar
      - cmd: compute bootstrap
      - file: /var/log/supervisord
      - git: compute clone edgar

save iptables:
  module.run:
    - name: iptables.save
    - filename: /etc/sysconfig/iptables

iptables 9001:
  module.run:
    - name: iptables.insert
    - table: filter
    - chain: INPUT
    - position: 3
    - rule: -p tcp -m state --state NEW -m tcp --dport 9001 -j ACCEPT
    - require_in:
      - module: save iptables

update hpc_config base url:
  file.replace:
    - name: /home/compute/Edgar/modelling/src/hpc_config.py
    - pattern: cakeAppBaseURL = "http://climatebird2.qern.qcif.edu.au/Edgar"
    - repl: cakeAppBaseURL = "{{pillar['applications']['edgar_base_url']}}"
    - require:
      - file: /home/compute/Edgar
      - git: compute clone edgar
    - watch_in:
      - service: supervisord

copy importing config:
  file.copy:
    - name: /home/compute/Edgar/importing/config.json
    - source: /home/compute/Edgar/importing/config.example.json
    - user: compute
    - group: compute
    - mode: 640
    - require:
      - file: /home/compute/Edgar
      - git: compute clone edgar

update importing database:
  file.replace:
    - name: /home/compute/Edgar/importing/config.json
    - pattern: '"db.url": "postgresql\+psycopg2://edgar_backend:backend_password_here@/edgar"'
    - repl: '"db.url": "postgresql+psycopg2://edgar_on_rails:{{pillar['database']['edgar_password']}}@{{pillar['database']['host']}}:5432/edgar_on_rails_prod_db"'
    - require:
      - file: copy importing config
    - watch_in:
      - service: supervisord

#update importing api_key:
#  file.replace:
#    - name: /home/compute/Edgar/importing/config.json
#    - pattern: '"alaApiKey": null'
#    - repl: '"alaApiKey": "{{pillar['ala']['api_key']}}"'
#    - require:
#      - file: copy importing config
#    - watch_in:
#      - service: supervisord

#update importing ala_sync_url:
#  file.replace:
#    - name: /home/compute/Edgar/importing/config.json
#    - pattern: '"alaVettingSyncUrl": null'
#    - repl: '"alaVettingSyncUrl": "{{pillar['ala']['vetting_sync_url']}}"'
#    - require:
#      - file: copy importing config
#    - watch_in:
#      - service: supervisord

update importing cron:
  file.replace:
    - name: /home/compute/Edgar/importing/bin/ala_cron.sh
    - pattern: 'IMPORTER_DIR="/home/jc171154/Edgar/importing"'
    - repl: 'IMPORTER_DIR="/home/compute/Edgar/importing"'
    - require:
      - file: /home/compute/Edgar
      - git: compute clone edgar

/home/compute/Edgar/importing/bin/ala_cron.sh:
  file.replace:
    - name: /home/compute/Edgar/importing/bin/ala_cron.sh
    - pattern: 'IMPORTER_DIR="/home/jc171154/Edgar/importing"'
    - repl: 'IMPORTER_DIR="/home/compute/Edgar/importing"'
    - require:
      - file: /home/compute/Edgar
      - git: compute clone edgar
  cron.present:
    - user: compute
    # weekly
    - dayweek: 0
    - minute: 0
    - hour: 0
    - require:
      - file: /home/compute/Edgar/importing/bin/ala_cron.sh

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
      - file: /home/compute
      - file: /home/compute/Edgar

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
      - file: /home/compute
      - file: /home/compute/Edgar

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
      - file: /home/compute
      - file: /home/compute/Edgar
