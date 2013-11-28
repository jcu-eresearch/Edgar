include:
  - jcu.git
  - jcu.ruby.rvm.ruby_1_9_3.passenger
  - jcu.postgresql.postgresql92.client
  - edgar.mount

extend:
  rvm:
    user:
      - groups:
        - applications
        - nectar_mount_user
        - wheel
        - rvm
      - require:
        - group: applications
        - group: nectar_mount_user

applications requirements:
  pkg.installed:
    - pkgs:
      - geos-devel
      - v8-devel

/home/applications/Edgar:
  file.symlink:
    - target: /mnt/edgar_data/Edgar/repo
    - user: applications
    - group: applications
    - require:
      - git: applications clone edgar
      - service: autofs

/home/applications/climas:
  file.symlink:
    - target: /mnt/edgar_data/climas
    - user: applications
    - group: applications
    - require:
      - file: climas_www /mnt/edgar_data/climas
      - service: autofs

applications:
  group:
    - present
    - gid: {{ pillar['applications']['uid_gid'] }}
  user.present:
    - fullname: Applications
    - shell: /bin/bash
    - createhome: true
    - uid: {{ pillar['applications']['uid_gid'] }}
    - groups:
      - applications
      - nectar_mount_user
    - require:
      - group: applications
      - group: nectar_mount_user
      - pkg: applications requirements

#root /mnt/edgar_data/Edgar:
#  file.directory:
#    - name: /mnt/edgar_data/Edgar
#    - user: root
#    - group: root
#    - require:
#      - service: autofs

applications /mnt/edgar_data/Edgar:
  file.directory:
    - name: /mnt/edgar_data/Edgar
    - user: applications
    - group: applications
    - mode: 751
    - require:
      - service: autofs
      - user: applications

applications /mnt/edgar_data/Edgar/repo:
  file.directory:
    - name: /mnt/edgar_data/Edgar/repo
    - user: applications
    - group: applications
    - dir_mode: 751
    - file_mode: 640
    - recurse:
      - user
      - group
      - mode
    - require:
      - file: applications /mnt/edgar_data/Edgar

climas_www /mnt/edgar_data/climas:
  file.directory:
    - name: /mnt/edgar_data/climas
    - user: applications
    - group: applications
    - dir_mode: 751
    - file_mode: 640
    - recurse:
      - user
      - group
      - mode
    - require:
      - service: autofs
      - user: applications

{% for dir in 'sdm','data','reportdata','reportdata/regions', 'tmp', 'tmp/MapserverImages' %}
/mnt/edgar_data/climas/{{dir}}:
  file.directory:
    - user: applications
    - group: applications
    - require:
      - service: autofs
      - user: applications
{% endfor %}

applications clone edgar:
  git.latest:
    - name: https://github.com/jcu-eresearch/Edgar.git
    - rev: Edgar_On_Rails
    - target: /mnt/edgar_data/Edgar/repo
    - user: applications
    - require:
      - user: applications
      - pkg: git
      - file: applications /mnt/edgar_data/Edgar

# Clone TDH-Tools
climas_www clone tdh-tools:
  git.latest:
    - name: https://github.com/jcu-eresearch/TDH-Tools.git
    - target: /mnt/edgar_data/climas/source
    - user: applications
    - require:
      - user: applications
      - pkg: git
      - file: climas_www /mnt/edgar_data/climas

# Update the databse information
update climas database password:
  file.replace:
    - name: /mnt/edgar_data/climas/source/applications/DB/ToolsData.configuration.class.php
    - pattern: return "asdf"
    - repl: return "{{pillar['database']['climas_password']}}"
    - require:
      - git: climas_www clone tdh-tools

update climas database hostname:
  file.replace:
    - name: /mnt/edgar_data/climas/source/applications/DB/ToolsData.configuration.class.php
    - pattern: return "localhost"
    - repl: return "{{pillar['database']['host']}}"
    - require:
      - git: climas_www clone tdh-tools

# Update the climas config file

# Clone CliMAS Reports
climas_www clone climas-reports:
  git.latest:
    - name: https://github.com/jcu-eresearch/CliMAS-Reports.git
    - target: /mnt/edgar_data/climas/reports
    - user: applications
    - require:
      - user: applications
      - pkg: git
      - file: climas_www /mnt/edgar_data/climas

/home/applications/Edgar/webapplication/config/initializers/devise.rb:
  file.replace:
    - pattern: "config.secret_key = ''"
    - repl: "config.secret_key = '{{pillar['applications']['edgar_devise_secret_key']}}'"
    - require:
      - git: applications clone edgar
      - file: /home/applications/Edgar

update database password:
  file.replace:
    - name: /home/applications/Edgar/webapplication/config/database.yml
    - pattern: "password: password"
    - repl: "password: '{{pillar['database']['edgar_password']}}'"
    - require:
      - git: applications clone edgar
      - file: /home/applications/Edgar

update database host:
  file.replace:
    - name: /home/applications/Edgar/webapplication/config/database.yml
    - pattern: "host: 127.0.0.1"
    - repl: "host: '{{pillar['database']['host']}}'"
    - require:
      - git: applications clone edgar
      - file: /home/applications/Edgar

update action_mailer host:
  file.replace:
    - name: /home/applications/Edgar/webapplication/config/environments/production.rb
    - pattern: config.action_mailer.default_url_options.*''.*}
    - repl: config.action_mailer.default_url_options = { :host => '{{pillar['applications']['edgar_ip']}}' }
    - require:
      - git: applications clone edgar
      - file: /home/applications/Edgar

update assets compile:
  file.replace:
    - name: /home/applications/Edgar/webapplication/config/environments/production.rb
    - pattern: config.assets.compile = false
    - repl: config.assets.compile = true
    - require:
      - git: applications clone edgar
      - file: /home/applications/Edgar

sudo /home/rvm/.rvm/bin/rvm ruby-1.9.3 do gem install pg -- --with-pg-config=/usr/pgsql-9.2/bin/pg_config:
  cmd.run:
    - require:
      - gem: bundler
      - pkg: Install PostgreSQL92 Client Packages

bundle install edgar:
  cmd.run:
    - name: sudo /home/rvm/.rvm/bin/rvm ruby-1.9.3 do bundle install --gemfile=/home/applications/Edgar/webapplication/Gemfile
    - require:
      - gem: bundler
      - git: applications clone edgar
      - file: /home/applications/Edgar
      - pkg: Install PostgreSQL92 Client Packages
      - pkg: applications requirements
      - cmd: sudo /home/rvm/.rvm/bin/rvm ruby-1.9.3 do gem install pg -- --with-pg-config=/usr/pgsql-9.2/bin/pg_config

bundle install climas:
  cmd.run:
    - name: sudo /home/rvm/.rvm/bin/rvm ruby-1.9.3 do bundle install --gemfile=/mnt/edgar_data/climas/reports/webapplication/Gemfile
    - require:
      - gem: bundler
      - git: climas_www clone tdh-tools
      - pkg: applications requirements

db migrate:
  cmd.run:
    - name: "sudo /home/rvm/.rvm/bin/rvm ruby-1.9.3 do rake db:migrate RAILS_ENV=production"
    - cwd: /home/applications/Edgar/webapplication/
    - require:
      - cmd: bundle install edgar
      - git: applications clone edgar
      - file: /home/applications/Edgar

seed db:
  cmd.run:
    - name: "sudo /home/rvm/.rvm/bin/rvm ruby-1.9.3 do rake db:seed RAILS_ENV=production"
    - cwd: /home/applications/Edgar/webapplication/
    - require:
      - git: applications clone edgar
      - cmd: db migrate
      - file: /home/applications/Edgar

copy /mnt/edgar_data/climas/reports/webapplication/settings.rb:
  file.copy:
    - name: /mnt/edgar_data/climas/reports/webapplication/settings.rb
    - source: /mnt/edgar_data/climas/reports/webapplication/settings.rb.example
    - force: true
    - require:
      - git: climas_www clone tdh-tools

/mnt/edgar_data/climas/reports/webapplication/settings.rb:
  file.managed:
    - user: applications
    - group: applications
    - mode: 660
    - require:
      - file: copy /mnt/edgar_data/climas/reports/webapplication/settings.rb
    - watch_in:
      - service: nginx

/usr/local/nginx/conf/conf.d/edgar_and_climas.conf:
  file.managed:
    - source:
      - salt://edgar/applications/edgar_and_climas_nginx_config.conf
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
      - file: /home/applications/Edgar

/home/applications/webapplications/edgar:
  file.symlink:
    - user: applications
    - group: applications
    - target: /home/applications/Edgar/webapplication/public
    - require:
      - file: /home/applications/webapplications

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
    - watch_in:
      - service: nginx


