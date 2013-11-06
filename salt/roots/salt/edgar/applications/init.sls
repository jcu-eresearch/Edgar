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

applications requirements:
  pkg.installed:
    - pkgs:
      - geos-devel
      - v8-devel

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
      - pkg: applications requirements

applications clone edgar:
  git.latest:
    - name: https://github.com/jcu-eresearch/Edgar.git
    - rev: Edgar_On_Rails
    - target: /home/applications/Edgar
    - runas: applications
    - require:
      - user: applications
      - pkg: git

/home/applications/Edgar/webapplication/config/initializers/devise.rb:
  file.replace:
    - pattern: "config.secret_key = ''"
    - repl: "config.secret_key = '{{grains['applications.edgar_devise_secret_key']}}'"
    - require:
      - git: applications clone edgar

update database password:
  file.replace:
    - name: /home/applications/Edgar/webapplication/config/database.yml
    - pattern: "password: password"
    - repl: "password: '{{grains['database.password']}}'"
    - require:
      - git: applications clone edgar

update database host:
  file.replace:
    - name: /home/applications/Edgar/webapplication/config/database.yml
    - pattern: "host: 127.0.0.1"
    - repl: "host: '{{grains['database.host']}}'"
    - require:
      - git: applications clone edgar

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

sudo /home/rvm/.rvm/bin/rvm ruby-1.9.3 do gem install pg -- --with-pg-config=/usr/pgsql-9.2/bin/pg_config:
  cmd.run:
    - require:
      - gem: bundler
      - pkg: Install PostgreSQL92 Client Packages

bundle install --deployment:
  cmd.run:
    - name: sudo /home/rvm/.rvm/bin/rvm ruby-1.9.3 do bundle install --gemfile=/home/applications/Edgar/webapplication/Gemfile
    - require:
      - gem: bundler
      - git: applications clone edgar
      - file: /home/applications
      - pkg: Install PostgreSQL92 Client Packages
      - pkg: applications requirements
      - cmd: sudo /home/rvm/.rvm/bin/rvm ruby-1.9.3 do gem install pg -- --with-pg-config=/usr/pgsql-9.2/bin/pg_config

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

/home/applications/Edgar/webapplication/Gemfile:
  file.managed:
    - mode: 644
    - user: applications
    - group: applications
    - require:
      - user: applications
      - git: applications clone edgar

/home/applications/webapplications/edgar:
  file.symlink:
    - user: applications
    - group: rvm_applications
    - target: /home/applications/Edgar/webapplication/public
    - require:
      - file: /home/applications/webapplications
