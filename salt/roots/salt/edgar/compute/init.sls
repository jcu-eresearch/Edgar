include:
  - jcu.git
  - jcu.supervisord
  - jcu.python.python_2_7
  - jcu.postgresql.postgresql92.client

kill supervisord:
  service:
    - name: supervisord
    - dead
    - require:
      - pkg: supervisor

compute requirements:
  pkg.installed:
    - pkgs:
      - git
      - wget
      - geos
  require:
    - cmd: python_2_7 make && make altinstall

compute:
  user.present:
    - fullname: Compute
    - shell: /bin/bash
    - createhome: true
    - gid_from_name: true

/home/compute/tmp:
  file.directory:
    - user: compute
    - group: compute
    - makedirs: True
  require:
    - user: compute

/var/log/supervisord:
  file.directory

compute clone edgar:
  git.latest:
    - name: https://github.com/jcu-eresearch/Edgar.git
    - target: /home/compute/Edgar
    - runas: compute
    - rev: Edgar_On_Rails
    - require:
      - user: compute
      - pkg: git

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
      - git: compute clone edgar
      - cmd: python_2_7 make && make altinstall
    - watch:
      - cmd: compute extract virtual env
    - require:
      - service: kill supervisord

compute setup.py install:
  cmd.wait:
    - cwd: /home/compute/Edgar/importing/
    - name: ../env/bin/python setup.py install
    - user: compute
    - require:
      - cmd: install compute virtual env
    - watch:
      - git: compute clone edgar

compute bootstrap:
  cmd.run:
    - cwd: /home/compute/Edgar/importing
    - user: compute
    - name: ../env/bin/python bootstrap.py
    - watch:
      - git: compute clone edgar
    - require:
      - cmd: install compute virtual env

compute buildout:
  cmd.run:
    - cwd: /home/compute/Edgar/importing
    - user: compute
    - name: ./bin/buildout
    - require:
      - cmd: compute bootstrap
      - git: compute clone edgar
      - file: /etc/supervisord.conf
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
      - git: compute clone edgar
      - cmd: compute bootstrap
      - file: /var/log/supervisord

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
      - git: compute clone edgar

update importing database:
  file.replace:
    - name: /home/compute/Edgar/importing/config.json
    - pattern: '"db.url": "postgresql\+psycopg2://edgar_backend:backend_password_here@/edgar"'
    - repl: '"db.url": "postgresql+psycopg2://edgar_on_rails:{{pillar['database']['password']}}@{{pillar['database']['host']}}:5432/edgar_on_rails_prod_db"'
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

update importing ala_sync_url:
  file.replace:
    - name: /home/compute/Edgar/importing/config.json
    - pattern: '"alaVettingSyncUrl": null'
    - repl: '"alaVettingSyncUrl": "{{pillar['ala']['vetting_sync_url']}}"'
    - require:
      - file: copy importing config
    - watch_in:
      - service: supervisord

update importing cron:
  file.replace:
    - name: /home/compute/Edgar/importing/bin/ala_cron.sh
    - pattern: 'IMPORTER_DIR="/home/jc171154/Edgar/importing"'
    - repl: 'IMPORTER_DIR="/home/compute/Edgar/importing"'
    - require:
      - git: compute clone edgar

/home/compute/Edgar/importing/bin/ala_cron.sh:
  file.replace:
    - name: /home/compute/Edgar/importing/bin/ala_cron.sh
    - pattern: 'IMPORTER_DIR="/home/jc171154/Edgar/importing"'
    - repl: 'IMPORTER_DIR="/home/compute/Edgar/importing"'
    - require:
      - git: compute clone edgar
  cron.present:
    - user: compute
    # daily
    - minute: 0
    - hour: 0
    - require:
      - file: /home/compute/Edgar/importing/bin/ala_cron.sh
