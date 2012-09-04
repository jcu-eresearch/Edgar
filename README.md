Edgar is a website where visitors can explore the future impact of climate change on Australian birds.

Edgar, running in all its glory:
http://spatialecology.jcu.edu.au/Edgar/

Edgar's developer blog:
http://jcu-eresearch.github.com/Edgar/

The code running the Edgar website is [available from github](http://github.com/jcu-eresearch/Edgar).  When completed, Edgar source code will be well suited to other projects that want to display and vet species occurrences, and show projections of future climate change and its effects.

Structure
---------
There are a few parts to Edgar.

An importing section, mostly written in Python, handles importing data from the [Atlas of Living Australia](http://www.ala.org.au) into a local database.

A modelling section, also mostly Python, handles the ~~[fancy science magic](http://xkcd.com/54/)~~ climate modelling with the imported data and climate information, which deployed Edgar runs on [JCU's HPC facility](https://plone.jcu.edu.au/hpc).

A mapping section uses [MapServer](http://mapserver.org) to take all the numeric data maps that the modelling creates, and deliver it in pretty map form to the UI.

A web application section written in [CakePHP](http://cakephp.org) and JavaScript does the UI and whatnot, using [OpenLayers](http://openlayers.org) for showing the map.

Credits
-------

Edgar is being developed by [a team](http://jcu-eresearch.github.com/Edgar/2012/03/22/the-team) at [JCU](http://www.jcu.edu.au/)'s [eResearch Centre](http://eresearch.jcu.edu.au/).

The principal researcher and project advisor is [Dr Jeremy VanDerWal](http://www.jjvanderwal.com/).

Edgar is supported by [the Australian National Data Service (ANDS)](http://www.ands.org.au/) through the National Collaborative Research Infrastructure Strategy Program and the Education Investment Fund (EIF) Super Science Initiative, as well as through the [Queensland Cyber Infrastructure Foundation (QCIF)](http://www.qcif.edu.au/).

License
-------

See `license.txt`.
