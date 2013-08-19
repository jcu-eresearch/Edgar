include:
  - jcu.apache
  - jcu.php
  - jcu.mapserver
  - jcu.git

map_server:
  user.present:
    - fullname: Map Server
    - shell: /bin/bash
    - createhome: true
    - gid_from_name: true

map_server clone edgar:
  git.latest:
    - name: https://github.com/jcu-eresearch/Edgar.git
    - target: /home/map_server/Edgar
    - runas: map_server
    - require:
      - user: map_server
      - pkg: git

/home/map_server:
  file.directory:
    - user: map_server
    - group: map_server
    - dir_mode: 755
    - file_mode: 644
    - recurse:
      - user
      - group
      - mode
    - require:
      - user: map_server
      - git: map_server clone edgar

/var/www/html/Edgar:
  file.symlink:
    - target: /home/map_server/Edgar/mapping
    - require:
      - git: map_server clone edgar
