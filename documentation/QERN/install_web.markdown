climatebird2.qern.qcif.edu.au (Web)
====================================

This install guide is for <code>yum</code>, tested with CentOS 6.2. Installation also confirmed working with Ubuntu <code>apt-get</code> packages.

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

Install php xml support (needed for cakephp):

```bash

sudo yum install php-xml
```

Install git:

```bash

sudo yum install git
```

Change dir to www (not html dir):

```bash

cd /var/www
```

Clone the git repo (read only):

```bash

sudo git clone "git://github.com/jcu-eresearch/Edgar.git"
```

Update the tmp directory of the web app so that cake can read and write to the tmp dir.

```bash

sudo chmod ugo+wrX -R /var/www/Edgar/webapplication/app/tmp/
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

Add apache to the "on boot" services:

```bash

sudo chkconfig --add httpd
sudo chkconfig --level 345 httpd on
```

Confirm that it's added by looking at:

```bash

sudo chkconfig --list
```

You may need to open port 80 of your firewall.
You can check your firewall settings via:


```bash

sudo iptables -L -v
```

You can add the rule to open port 80 by doing the following.
Note: Don't follow this part blindly, you should have at least a basic understanding of firewalls before you do this.

```bash

sudo iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
sudo service iptables save
```

At this point, everything should be working. Go to http://localhost/Edgar and enjoy
