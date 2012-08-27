climatebird2.qern.qcif.edu.au (Web)
====================================

Install apache:

```bash

sudo yum install httpd mod_ssl

```

Start apache:

```bash

sudo /etc/init.d/httpd start

```

Install php:

```bash

sudo yum install php

```

Install php postgresql driver:

```bash

sudo yum install php-pgsql

```

Restart apache:

```bash

sudo /etc/init.d/httpd restart

```

Install git:

```bash

sudo yum install git

```

Change dir to www:

```bash

cd /var/www/html

```

Fetch the git repo (read only):

```bash

git fetch "git://github.com/jcu-eresearch/Edgar.git"

```
