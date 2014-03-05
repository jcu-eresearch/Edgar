{% for key in pillar['ssh']['keys'] %}
? {{ key }}
:
  ssh_auth:
    - present
    - user: ec2-user
    - enc: ssh-rsa
{% endfor %}
