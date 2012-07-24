---
title:   Sending Vettings to ALA
layout:  post
author:  tom
summary: 'How vetting information is propagated to ALA'
excerpt: 
categories: [Development]
tags:    [progress, vetting, ALA]
---

One of the requirements for the AP03 project was that vetting
information be sent back to ALA, the source of our occurrence and
species data. ALA will hopefully be able to use the vetting information
to improve their existing data cleaning processes.


## Detecting New, Modified and Deleted Vettings

Each vettings in the database contains these fields:

 - `modified`: When the vetting was last modified
 - `deleted`: When the vetting was deleted, or `NULL` if not deleted
 - `last_ala_sync`: When the vetting was last sent to ALA successfully,
   or `NULL` if the vetting has not been sent yet

New vettings are identified by having `last_ala_sync = NULL`. Modified
vettings are identified by having `last_ala_sync < modified`. Deleted
vettings are identified by having `deleted != NULL`.


## Sending The Data

A [daemon process][1] watches the database for vettings to synchronise.
This daemon is written in Python, and is named `vetting_syncd`. The
daemon wakes up every five minutes to check for vettings that have been
created, modified, or deleted since they were last synchronised.

The vetting information is sent to ALA by making a HTTP request to an
ALA web service. The body of the request contains JSON formatted
information about the vetting, including:

 - A unique identifier for the vetting.
 - Whether the vetting is new, modified, or has been deleted.
 - The classification and polygons of the vetting.
 - The user that created the vetting, along with the user's authority
   level.

If the HTTP response code is anything except 200, it is interpreted as
failure and `vetting_syncd` will keep retrying the request at five
second intervals until the request is successful.

If the sending of a _new_ or _modified_ vetting is successful,
`last_ala_sync` is set to the current time to prevent the record from
being sent again. If the sending of a _deleted_ vetting is successful,
then that row is simply deleted from the database.


## Development Status

The `vetting_syncd` program is finished as described above. Once ALA
has finished developing the web service at the receiving end, a URL will
be set in the `config.json` file and `vetting_syncd` will start
running.

[1]: http://en.wikipedia.org/wiki/Daemon_(computing)
