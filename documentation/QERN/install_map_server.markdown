#Setup Map Server

Install Map Server and PHP Map Script

    sudo yum install mapserver php-mapserver

    sudo /etc/init.d/httpd start

Install proj.4 epsg definitions

```bash

sudo yum install proj-epsg.x86_64
```

Install php:

```bash

sudo yum install php
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

Change dir to html, and create link to the map component of git repo in www dir

```bash

cd /var/www/html
sudo ln -s /var/www/Edgar/mapping/ Edgar
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

Get access to shared data directory

```bash

sudo chmod ugo+Xr /data
```

Create a new .map file

```bash

sudo cp /var/www/html/Edgar/edgar_master.map /var/www/html/Edgar/qern.map
```

Edit the qern.map file to have the correct path to the modelling output files, e.g.:

```bash

sudo vim /var/www/html/Edgar/qern.map

```

```bash

#define the working folder of this map file
SHAPEPATH "/data/modelling/outputs/"
```

Add an addition projection to the proj.4 file `/usr/share/proj/epsg`:

```bash

sudo vim /usr/share/proj/epsg
```

Add the to the bottom of the file:

```bash

# NOTE: Custom mod.
# Robert added support for the google maps epsg. (followed this guide: http://docs.openlayers.org/library/spherical_mercator.html)
<900913> +proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs
```

