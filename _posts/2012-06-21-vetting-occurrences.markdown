---
title:   Vetting Occurrences
layout:  post
author:  tom
summary: 'An overview of the occurrence classification process in Edgar.'
excerpt: 
categories: [Development]
tags:    [progress, vetting, classification, occurrences]
---

Vetting is the process of putting occurrences records (a.k.a animal sightings) into certain classifications. Basically the aim of vetting is to say &ldquo;these records are correct&rdquo; and &ldquo;these other records are incorrect.&rdquo; This is important because records will be processed into distribution maps, so if the records are incorrect then the maps will also be incorrect. This post will be an overview of the vetting process in Edgar.

## What Is A Vetting Made Of?

In summary, each individual vetting is:

 - a single classification,
 - that applies to an area (a set of polygons),
 - by a single user,
 - for a single species.

Each vetting has a classification. Dan explains these categories in a previous post. Ultimately, this classification will be applied to individual records.

However, applying a classification to each record individually would be a horribly inconvenient task for users, considering that Edgar has around 18 million records. On top of this, records are added, deleted and changed every day. So, for convenience, a vetting is represented as a set of polygons on a map. If a record is within the polygons, then the vetting is applied to that record. As records are added or changed, they can be checked against existing vetting polygons automatically.

Each vetting belongs to a single user. This is useful when two different users provide vettings that disagree with each other. An administrator can see who provided both vettings, and use that information to decide which one is more correct.

Each vetting also belongs to a single species. Obviously, the breeding area polygons will be different for emus and penguins, for example.

## Authority

Vettings will come from multiple sources. This means that different sources are able to disagree with each other. One user says &ldquo;penguins live here&rdquo; and another user says &ldquo;no they don't.&rdquo;

To resolve these conflicts, Edgar administrators will be able to give users an authority level. When multiple vettings conflict with each other, users with higher authority will override users with lower authority. This only applies to the overlapping areas of vettings. No overriding will happen in areas that do not overlap.

The user with the highest authority is the Edgar administrator, allowing him/her to override any vetting on the site. Next on the scale of authority are the logged-in users of Edgar, who the administrator can assign different authority levels to.

The lowest level of authority comes from the source of the records. When records are fetched from ALA, each record is given a classification based on ALA's system of assertions. ALA's assertion system does not translate well into Edgar's classification system, which is why it is given the lowest level of authority. All logged in users are able to override these classifications translated from ALA.

## Applying Vettings To Records

Calculating the correct classification for each record is done using a custom (PL/pgSQL)]http://www.postgresql.org/docs/8.4/static/plpgsql.html] function in Postgres. The code for the function is in [database_structure.sql](https://github.com/jcu-eresearch/Edgar/blob/master/database_structure.sql). It uses a [painters algorithm](http://en.wikipedia.org/wiki/Painter's_algorithm) so that the higher-authority vettings are &ldquo;painted over&rdquo; the lower-authority vettings.

The algorithm works roughly like this:

1. For every record:
    1. Set the records classification to the one from the source (i.e., the classification translated from ALA's assertions)
2. For every vetting, <strong>ordered from lowest-authority to highest-authority</strong>:
    1. For every record inside the vetting area:
        1. Set the records classification to the vettings classification

Basically, the record classifications are reset to their original value. Then, every vetting is &ldquo;painted&rdquo; over the records by setting the classification for all records in the vettings polygons. Each vetting possibly &ldquo;paints over&rdquo; previous vettings, which is why they are applied in order from lowest-priority to highest-priority.