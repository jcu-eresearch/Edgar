include:
  - jcu.apache
  - jcu.postgresql
  - jcu.postgresql.php
  - jcu.postgis
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
