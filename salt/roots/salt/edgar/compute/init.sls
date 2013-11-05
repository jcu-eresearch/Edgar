include:
  - jcu.git
  - jcu.supervisord
  - jcu.python.python_2_7
  - jcu.postgresql.postgresql92.client

compute requirements:
  pkg.installed:
    - pkgs:
      - git
      - wget
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
    - watch_in:
      - service: supervisord

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
