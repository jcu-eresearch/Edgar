---
title:   ALA Data Importing
layout:  post
author:  tom
summary: A description of the ALA importer
excerpt:
categories: [Development]
tags:    [ALA, importing]
---

Edgar (a.k.a the AP03 project) exists to visualize bird occurrence
records and distribution maps. Occurrence records are basically
coordinates where a specific species of bird was seen, and these
coordinates are used to generate the distribution maps. Therefor, the
quantity and quality of the occurrence records is very important to the
usefulness of the project. To obtain a large number of quality
occurrences, Edgar will be using the data from the [Atlas of Living
Australia (ALA)](http://www.ala.org.au/). It was decided that we will
keep a local copy of all bird occurrence records from ALA, because using
all of the data live (i.e. straight from the ALA servers) isn't feasible
for a few reasons:

- Edgar needs to handle occurrence records from multiple sources.
- Using ALA directly would make Edgar more difficult for other people to
  set up and use with different occurrence record sources.
- The rating/vetting categories in Edgar (`assumed valid`, `known
  valid`, `assumed invalid`, and `known invalid`) do not correspond very
  well with the ALA system of assertions.
- Server-side clustering of records is required for performance reasons.
  ALA provides clustering in the form of map layers, but does not
  provide the ability to colour the layers depending on our specific
  vetting categories. If Edgar performed the clustering itself using
  live records from ALA servers, it would not run fast enough to display
  to the user (could take in excess of five minutes for a single map).

Keeping a local copy of the occurrence records poses its own problems,
however.

### Disk Size

Initial testing indicates that we can keep each record under 100 bytes
in a MySQL database. ALA has around 18 million occurrence records for
birds, so this means that storing all of the occurrences will require
less than two gigabytes of storage on disk. The size itself shouldn't be
a problem in this case, but the performance of database that size
remains untested.

### Speed

Importing 18 million records at once will take a considerable amount of
time. Instead of repeatedly downloading all records when Edgar needs an
update, we plan on doing incremental updates. This means that there will
be an initial import of all 18 million records, but subsequent imports
will only download records that have been added, deleted, or modified.
This will allow Edgar to synchronise its data with ALA more frequently.

Initial testing indicates that we can download records from ALA at
roughly 500 to 2000 records per second using a concurrent architecture
for HTTP requests. This means the initial import of 18 million records
should take between 3 and 10 hours.

### Species Changes

The list of bird species will change as new species are found, and
existing species are merged together or split apart. As part of the ALA
syncing process, these additions, splits and merges will be incorporated
into the local database.

### Connectivity and Availability Problems

Because an import can run for hours, it's highly likely that ALA web
services may become unavailable while an import is running. This could
happen for many reasons, including ALA servers being restarted or
temporary network connectivity problems. The importer must accomodate
these disruptions without producing incorrect results.

When a request to ALA fails for any reason, the request is retried using
an exponential back off algorithm. With the current settings, if a
request fails it will wait 10 seconds before retrying the request. If
the retry fails, then the wait duration is doubled before performing the
next retry. The fifth and last retry will happen over five minutes after
the first try, and if that fails then the import will stop running and
log an error.

Five retries over five minutes should be sufficient to overcome common
availability problems, but if there are recurring import failures it may
require more sophisticated error handling.

### Data Quality

ALA aggregates occurrence records from many different sources, so the
data quality varies. Some occurrences are too old to be reliable, such
as the 158 records for the extinct Tasmanian Tiger. Some occurrences
contain inaccurate coordinates, or no coordinates at all. Some
occurrences have been obfuscated (made inaccurate on purpose) to hide
the location of endangered species. ALA also keeps records of preserved
specimens, images, sounds, and genetic information, which are not
relevant to Edgar.

ALA has a comprehensive system of assertions that indicate known
problems with each occurrence record. For instance, there are assertions
for the latitude and longitude being swapped, and for coordinates of
terrestrial animals that appear in the ocean. Most of the assertions
come from the data cleaning efforts of ALA, but some of them also come
from users reporting issues with individual records.

The import will ignore irrelevant records, and try to assign `assumed
valid` or `assumed invalid` ratings to each occurrence based on the ALA
assertions that are present. The exact combination of assertions that
will cause a record to be marked as "assumed invalid" has not been
decided upon yet, but we are currently using reasonable defaults.

We hope to get access to the accurate coordinates for obfuscated
occurrences. The obfuscated occurrences may or may not be shown on the
map, but the accurate coordinates will not be display. The accurate
coordinates will only be used to generate distribution maps, which will
not contain any individual occurrence coordinates when displayed.

## Implementation

The syncing will be performed by python scripts. These are currently
available from
<https://github.com/jcu-eresearch/Edgar/tree/master/importing>

A cron job will be set up to run a single script, which is currently
called `ala_db_update.py`. There is a configuration file that contains
database connection settings and options to control minor behaviours of
the importer, such as how much information is logged while it runs.

The syncing process roughly involves these steps:

1. Record the start time for the import
2. Get the last import time from the database
3. Query ALA for a list of all bird species
4. Update the species in the database
5. Query ALA for occurrence records that have been changed or added
   since the last import time
6. Add and update occurrences in the database
7. Delete occurrences from the database that no longer exist at ALA
8. Check that the number of occurrences in the local database matches
   the number of occurrences at ALA
9. Update the last import time in the database to the time that the
   import started

If the import fails, the last import time will not be updated in the
database. This will ensure that the next run of the importer will get
all of the occurrences that the failed run did not.
