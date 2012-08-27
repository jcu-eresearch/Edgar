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

Install git:

```bash

sudo yum install git
```

Change dir to www (not html dir):

```bash

cd /var/www
```

Fetch the git repo (read only):

```bash

sudo git fetch "git://github.com/jcu-eresearch/Edgar.git"
```

Change dir to html, and create link to webapplication component of git repo in www dir

```bash

cd /var/www/html
sudo ln -s /var/www/Edgar/webapplication/ Edgar
```

Update httpd conf to allow cakephp to perform re-writes

Add the following to the httpd.conf (/etc/httpd/conf/httpd.conf).
This should be added after the default directory settings (&lt;Directory "/var/www/html"&gt;&hellip;&lt;/Directory&gt;).

```conf

<Directory "/var/www/html/Edgar">
    Options Indexes FollowSymLinks MultiViews
    AllowOverride All
    Order allow,deny
    Allow from all
</Directory>
```
Update the database config settings:

```bash

sudo cp /var/www/Edgar/webapplication/app/Config/database.php.default /var/www/Edgar/webapplication/app/Config/database.php
sudo vim /var/www/Edgar/webapplication/app/Config/database.php
```

Restart apache:

```bash

sudo /etc/init.d/httpd restart
```

At this point, everything should be working. Go to http://localhost/Edgar and enjoy
