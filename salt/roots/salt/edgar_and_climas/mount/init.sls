mount requirements:
  pkg.installed:
    - pkgs:
      - nfs-utils
      - autofs

/etc/sysconfig/network-scripts/ifcfg-eth1:
  file.managed:
    - source:
      - salt://edgar/mount/ifcfg-eth1

ifup eth1:
  cmd.run:
    - name: ifdown eth1 && sleep 10 && ifup eth1 && sleep 10
    - require:
      - file: /etc/sysconfig/network-scripts/ifcfg-eth1

nectar_mount_user:
  group.present:
    - gid: {{ pillar['mount']['uid_gid'] }}
  user.present:
    - uid: {{ pillar['mount']['uid_gid'] }}
    - groups:
      - nectar_mount_user
    - require:
      - group: nectar_mount_user
      - pkg: mount requirements

# Note the file contents are COMMENTED OUT
#
# i.e. this file DOES NOTHING
/etc/auto.master:
  file.managed:
    - contents: "#Set the timeout to 10 minutes for the auto.rdsi mount point\n#/mnt\tfile:/etc/auto.rdsi\t--timeout=600"
    - require:
      - pkg: mount requirements

# This file is ignored, as the file contents above are commented out
/etc/auto.rdsi:
  file.managed:
    - contents: "edgar_and_climas\t-rw,nfsvers=3,hard,intr,nosuid,nodev,timeo=100,retrans=5\t{{pillar['mount']['collection_path']}}"
    - require:
      - pkg: mount requirements

autofs:
  service:
    - running
    - enable: True
    - require:
      - user: nectar_mount_user
      - file: /etc/auto.master
      - file: /etc/auto.rdsi
      - cmd: ifup eth1
      - service: rpcbind

rpcbind:
  service:
    - running
    - enable: True
    - require:
      - user: nectar_mount_user
      - file: /etc/auto.master
      - file: /etc/auto.rdsi
      - cmd: ifup eth1
