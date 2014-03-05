include:
  - jcu.git
  - jcu.ruby.rvm.ruby_1_9_3.passenger
  - jcu.postgresql.postgresql92.client

extend:
  rvm:
    user:
      - groups:
        - applications
        - wheel
        - rvm
      - require:
        - group: applications

applications requirements:
  pkg.installed:
    - pkgs:
      - geos-devel
      - v8-devel

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
    - require:
      - group: applications
      - pkg: applications requirements

{% for dir in 'sdm','data' %}
/home/applications/climas/{{dir}}:
  file.directory:
    - user: applications
    - group: applications
    - require:
      - user: applications
      - git: /home/applications/climas
    - recurse:
      - user
      - group
{% endfor %}

{% for dir in 'tmp', 'tmp/MapserverImages' %}
/home/applications/climas/{{dir}}:
  file.directory:
    - user: applications
    - group: applications
    - dir_mode: 777
    - file_mode: 666
    - recurse:
      - user
      - group
      - mode
    - require:
      - user: applications
      - git: /home/applications/climas
{% endfor %}

/home/applications/Edgar:
  git.latest:
    - name: https://github.com/jcu-eresearch/Edgar.git
    - rev: Edgar_On_Rails
    - target: /home/applications/Edgar
    - user: applications
    - require:
      - user: applications
      - pkg: git

# Clone TDH-Tools
/home/applications/climas:
  git.latest:
    - name: https://github.com/jcu-eresearch/TDH-Tools.git
    - target: /home/applications/climas
    - user: applications
    - require:
      - user: applications
      - pkg: git

# Update the database information
update climas database password:
  file.replace:
    - name: /home/applications/climas/applications/DB/ToolsData.configuration.class.php
    - pattern: return "asdf"
    - repl: return "{{pillar['database']['climas_password']}}"
    - require:
      - git: /home/applications/climas

update climas database hostname:
  file.replace:
    - name: /home/applications/climas/applications/DB/ToolsData.configuration.class.php
    - pattern: return "localhost"
    - repl: return "{{pillar['database']['host']}}"
    - require:
      - git: /home/applications/climas

# Update the climas config file

# Clone CliMAS Reports
/home/applications/climas/reports:
  git.latest:
    - name: https://github.com/jcu-eresearch/CliMAS-Reports.git
    - target: /home/applications/climas/reports
    - user: applications
    - require:
      - user: applications
      - pkg: git
      - git: /home/applications/climas

update /home/applications/Edgar/webapplication/config/initializers/devise.rb:
  file.replace:
    - name: /home/applications/Edgar/webapplication/config/initializers/devise.rb
    - pattern: "config.secret_key = ''"
    - repl: "config.secret_key = '{{pillar['applications']['edgar_devise_secret_key']}}'"
    - require:
      - git: /home/applications/Edgar

/home/applications/Edgar/webapplication/config/initializers/devise.rb:
  file.managed:
    - user: applications
    - group: applications
    - mode: 640
    - require:
      - file: update /home/applications/Edgar/webapplication/config/initializers/devise.rb

update database password:
  file.replace:
    - name: /home/applications/Edgar/webapplication/config/database.yml
    - pattern: "password: password"
    - repl: "password: '{{pillar['database']['edgar_password']}}'"
    - require:
      - git: /home/applications/Edgar

update database host:
  file.replace:
    - name: /home/applications/Edgar/webapplication/config/database.yml
    - pattern: "host: 127.0.0.1"
    - repl: "host: '{{pillar['database']['host']}}'"
    - require:
      - git: /home/applications/Edgar

/home/applications/Edgar/webapplication/config/database.yml:
  file.managed:
    - user: applications
    - group: applications
    - mode: 640
    - require:
      - file: update database host
      - file: update database password

update action_mailer host:
  file.replace:
    - name: /home/applications/Edgar/webapplication/config/environments/production.rb
    - pattern: config.action_mailer.default_url_options.*''.*}
    - repl: config.action_mailer.default_url_options = { :host => '{{pillar['applications']['edgar_ip']}}' }
    - require:
      - git: /home/applications/Edgar

update assets compile:
  file.replace:
    - name: /home/applications/Edgar/webapplication/config/environments/production.rb
    - pattern: config.assets.compile = false
    - repl: config.assets.compile = true
    - require:
      - git: /home/applications/Edgar

/home/applications/Edgar/webapplication/config/environments/production.rb:
  file.managed:
    - user: applications
    - group: applications
    - mode: 640
    - require:
      - file: update action_mailer host
      - file: update assets compile

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
      - git: /home/applications/Edgar
      - pkg: Install PostgreSQL92 Client Packages
      - pkg: applications requirements
      - cmd: sudo /home/rvm/.rvm/bin/rvm ruby-1.9.3 do gem install pg -- --with-pg-config=/usr/pgsql-9.2/bin/pg_config

bundle install climas:
  cmd.run:
    - name: sudo /home/rvm/.rvm/bin/rvm ruby-1.9.3 do bundle install --gemfile=/home/applications/climas/reports/webapplication/Gemfile
    - require:
      - gem: bundler
      - git: /home/applications/climas/reports
      - pkg: applications requirements

db migrate:
  cmd.run:
    - name: "sudo /home/rvm/.rvm/bin/rvm ruby-1.9.3 do rake db:migrate RAILS_ENV=production"
    - cwd: /home/applications/Edgar/webapplication/
    - require:
      - cmd: bundle install edgar
      - git: /home/applications/Edgar

seed db:
  cmd.run:
    - name: "sudo /home/rvm/.rvm/bin/rvm ruby-1.9.3 do rake db:seed RAILS_ENV=production"
    - cwd: /home/applications/Edgar/webapplication/
    - require:
      - git: /home/applications/Edgar
      - cmd: db migrate

copy /home/applications/climas/reports/webapplication/settings.rb:
  file.copy:
    - name: /home/applications/climas/reports/webapplication/settings.rb
    - source: /home/applications/climas/reports/webapplication/settings.rb.example
    - force: true
    - require:
      - git: /home/applications/climas/reports

update DataFilePrefix /home/applications/climas/reports/webapplication/settings.rb:
  file.replace:
    - name: /home/applications/climas/reports/webapplication/settings.rb
    - pattern: DataFilePrefix = '/climas/reportdata/'
    - repl: DataFilePrefix = '/home/applications/sync_dir/reports/'
    - require:
      - file: copy /home/applications/climas/reports/webapplication/settings.rb

update DataUrlPrefix /home/applications/climas/reports/webapplication/settings.rb:
  file.replace:
    - name: /home/applications/climas/reports/webapplication/settings.rb
    - pattern: DataUrlPrefix = '/climas/reportdata/'
    - repl: DataUrlPrefix = 'http://{{pillar['applications']['edgar_ip']}}/climas/reportdata/'
    - require:
      - file: copy /home/applications/climas/reports/webapplication/settings.rb

update SiteUrlPrefix /home/applications/climas/reports/webapplication/settings.rb:
  file.replace:
    - name: /home/applications/climas/reports/webapplication/settings.rb
    - pattern: SiteUrlPrefix = '/climas/reports/'
    - repl: SiteUrlPrefix = 'http://{{pillar['applications']['edgar_ip']}}/climas/reports/'
    - require:
      - file: copy /home/applications/climas/reports/webapplication/settings.rb

update ParentSiteUrl /home/applications/climas/reports/webapplication/settings.rb:
  file.replace:
    - name: /home/applications/climas/reports/webapplication/settings.rb
    - pattern: ParentSiteUrl = '/climas/'
    - repl: ParentSiteUrl = 'http://{{pillar['applications']['edgar_ip']}}/climas/'
    - require:
      - file: copy /home/applications/climas/reports/webapplication/settings.rb

/home/applications/climas/reports/webapplication/settings.rb:
  file.managed:
    - user: applications
    - group: applications
    - mode: 660
    - require:
      - file: update DataFilePrefix /home/applications/climas/reports/webapplication/settings.rb
      - file: update SiteUrlPrefix /home/applications/climas/reports/webapplication/settings.rb
      - file: update ParentSiteUrl /home/applications/climas/reports/webapplication/settings.rb
    - watch_in:
      - service: nginx

/usr/local/nginx/conf/conf.d/edgar_and_climas.conf:
  file.managed:
    - source:
      - salt://edgar_and_climas/applications/edgar_and_climas_nginx_config.conf
    - user: rvm
    - group: rvm
    - mode: 740
    - template: jinja
    - defaults:
        map_server_ip: {{ pillar['database']['host'] }}
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
      - git: /home/applications/Edgar

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
      - git: /home/applications/Edgar
    - watch_in:
      - service: nginx

#/home/applications/Edgar/env/bin:
#  file.directory:
#    - user: applications
#    - group: applications
#    - dir_mode: 751
#    - file_mode: 751
#    - recurse:
#      - user
#      - group
#      - mode
#    - require:
#      - user: applications
#      - git: /home/applications/Edgar
#      - file: /home/applications

/home/applications/Edgar/importing/bin/:
  file.directory:
    - user: applications
    - group: applications
    - dir_mode: 751
    - file_mode: 751
    - recurse:
      - user
      - group
      - mode
    - require:
      - user: applications
      - git: /home/applications/Edgar
      - file: /home/applications

/home/applications/Edgar/modelling/bin/:
  file.directory:
    - user: applications
    - group: applications
    - dir_mode: 751
    - file_mode: 751
    - recurse:
      - user
      - group
      - mode
    - require:
      - user: applications
      - git: /home/applications/Edgar
      - file: /home/applications
