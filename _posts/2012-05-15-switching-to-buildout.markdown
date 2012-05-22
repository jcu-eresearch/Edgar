---
title:   Switching To Buildout
layout:  post
author:  tom
summary: The costs, benefits, and reasoning behind switching to zc.buildout
excerpt:
categories: [Development]
tags:    [importing, python]
---

Recently, the python scripts under the `importing` directory were
restructured to work with [zc.buildout](http://www.buildout.org/). I
switched to Buildout because:

- **Buildout automatically installs (almost) all of the dependencies**.
  With Jenkins running unit tests, the scripts are now running on three
  different computers. I didn't have access the the server running Jenkins
  so I couldn't install all the dependencies by hand. With build out,
  that's not a problem.
- **Buildout is a well-known standard in the Python community**. Many
  Python developers already have experience with Buildout due to its
  wide use, so the structure should be easier for them to understand.
- **Buildout easily generates jUnit xml test reports**. In order to
  integrate the existing unit tests with Jenkins, jUnit xml formatted
  reports need to be generated. Buildout already has a recipe for this
  called `collective.xmltestreport`.
- **Buildout can use a specific version of Python for all executables**.
  Incompatibility bugs were being introduced occasionally because I was
  using Python version 2.7 for development, but the production servers
  only have version 2.6 installed. With Buildout I can easily switch to
  Python 2.6 locally for development to avoid the problem.

The costs of switching to Buildout are:

- The time taken to learn it and restructure the code. I had never used
  Buildout before, so this took about 8 hours all up. The 8 hours
  includes the Jenkins integration which would have taken time regardless
  of whether Buildout was used. The time spent switching will be
  be offset by the benefits like faster setup and debugging.
- Added complexity. Buildout is light-weight, but it's still a bit more
  complex than a bunch of `.py` files. Although, you could argue that
  using a non-standard structure for a bunch of `.py` files is more
  complicated than using a standard structure.
