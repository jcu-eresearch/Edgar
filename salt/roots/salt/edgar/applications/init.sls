include:
  - jcu.git
  - jcu.ruby.rvm.ruby_1_9_3.passenger
  - jcu.postgresql.postgresql92.client

rvm_applications:
  group.present

extend:
  rvm:
    user:
      - groups:
        - rvm_applications
        - wheel
        - rvm
      - require:
        - group: rvm_applications

applications:
  group:
    - present
  user.present:
    - fullname: Applications
    - shell: /bin/bash
    - createhome: true
    - gid_from_name: true
    - groups:
      - applications
      - rvm_applications
    - require:
      - group: applications
      - group: rvm_applications

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
    - dir_mode: 751
    - file_mode: 640
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
      - pkg: Install PostgreSQL92 Client Packages

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
    - dir_mode: 751
    - file_mode: 640
    - require:
      - user: applications

/home/applications/webapplications/edgar:
  file.symlink:
    - user: applications
    - group: rvm_applications
    - target: /home/applications/Edgar/webapplication/public
    - require:
      - file: /home/applications/webapplications
