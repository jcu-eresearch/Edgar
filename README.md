
Edgar is a website where visitors can explore the future impact of climate change on Australian birds.

Edgar, running in all its glory:
(url not confirmed yet)

Edgar's developer blog:
http://jcu-eresearch.github.com/Edgar/

The code running the Edgar website is <a href="http://github.com/jcu-eresearch/Edgar">available from github</a>.

Structure
---------
There are a few parts to Edgar.

An importing section, mostly written in Python, handles importing data from the [Atlas of Living Australia](http://www.ala.org.au) into a local database.

A modelling section, also mostly Python, handles the ~~[fancy science magic](http://xkcd.com/54/)~~ climate modelling with the imported data and climate information, which deployed Edgar runs on [JCU's HPC facility](https://plone.jcu.edu.au/hpc).

A mapping section uses [MapServer](http://mapserver.org) to take all the numeric data maps that the modelling creates, and deliver it in pretty map form to the UI.

A web application section written in [CakePHP](http://cakephp.org) does the UI and whatnot, using [OpenLayers](http://openlayers.org) for showing the map.

Credits
-------
(credits go here)
