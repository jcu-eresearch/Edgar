---
title:   Has Edgar succeeded? Our users response
layout:  post
author:  lauren
summary: ''
excerpt: 
categories: [Development]
tags:    [andsUserTesting, andsCustomers, testing, user]
---

Climate change impacts the geographic range within which species are able to persist.  Already, some species ranges across the globe and in Australia are shifting as a result of our warming climate.  In order to conserve species, we need to understand how their distributions are likely to shift in the future.

Edgar aims to show current and future species ranges for Australian birds under multiple climate change scenarios.  However, many steps must be completed before we can model future species distributions at a continental scale:

1. collect bird observations across Australia
2. collate the data into one big database
3. vet the data
4. model the relationship between bird occurrence records and the climate in which they were observed
5. project the model through space and time

Birdlife Australia, museums, research organisations and institutions, and individuals have been recording bird observations throughout time.  The [Atlas of Living Australia](http://www.ala.org.au/) (ALA) has provided the platform to collate observation data in one big continental-scale database.

Edgar displays the almost 18 million ALA bird observation records potentially suitable for modelling on a map.  In doing this, it provides an interface for users to vet these displayed records. Given the newly vetted records, Edgar then automatically models reclassified data each time records are modified, and creates maps of future projections of the species distribution.

We [showed a near completed version]({{ BASE_PATH }}/Development/2012/08/08/user-interface-testing/) of Edgar to researchers and bird enthusiasts to find out whether Edgar succeeded in these goals.

## Vetting the data

In 18 million records over some 900+ species, some records are bound to be inaccurate.  Inaccurate records suggest that areas of unsuitable climate are suitable, which creates inaccuracies in the model of the relationship between observations and climate.  There was a glaring gap in fast and easy ways to vet out these inaccurate records, which is necessary to generate informative climate suitability models.

Traditionally, a map of observation records was created for each species for the region of interest, and a few experts would take to the map with a pen.  With technological advances, very few specialist researchers have been able to digitally determine statistical outliers and generate polygons of the range edge.  However, with a changing range under climate change, these labour-intensive methods would need to be repeated to reflect the shifting distributions.

Edgar addresses this issue by dynamically importing new observation records from ALA and displaying them over a hidden layer of polygons developed by [Birdlife Australia](http://www.birdlife.org.au/) which classifies the new observations according to whether they are currently considered part of a bird’s core range.  If a new observation falls outside a classification polygon, it is marked as unclassified and is considered to be a valid record until otherwise stated.  Information about that observation such as date, coordinates, and positional accuracy can be viewed by clicking on the mapped observation point, which grants users access to enough information to classify the record.  We have used classification terms that are interesting and relevant to bird observers, such as core, vagrant, and introduced, and we have made the judgement of which classifications are useful for modelling behind the scenes.

Edgar also provides fast and easy mechanisms for vetting data, with simple tools such as drag-over selection boxes and drop-down classification menus.

#### Did the vetting tool succeed?

We showed this vetting tool to three experts in the field who had extensive experience in vetting bird observation records using all previously available technology (or lack-thereof).  The praise for the simplicity of the vetting process was resounding.  The evidence of the ease of use was clear as we, the development team, watched the target users save new classifications against multitudes of observation records.  The piece of news that perhaps pleased the vetting users the most was that their classifications would be saved not only within our system, but also to the centralised and familiar data store of ALA.

## Projecting climate suitability through space and time

As data is vetted through the online interface, Edgar sends commands to the High Performance Computing system at James Cook University to run the model again. The relationship between climate and observations is determined and mapped using current and future continental climate layers.  We use the median of 18 Global Climate Models to generate maps for 8 decadal time steps into the future.

Back at the online interface, Edger displays the current climate suitability layer as an intuitive gradient of least suitable (yellow) to most suitable (green).  It overlays the observation records, which shows how observations relate to climate suitability.  A button on the side bar allows users to view the median projection of future climate suitability for a species as an animation.

#### Did display of climate suitability succeed?

This was the aspect of the project that users of all backgrounds -- expert, bird-enthusiast, or not -- engaged with the most.  Each user selected a species of interest, reported an understanding of the relationship between the observations and the climate suitability model, and clicked ‘play’ to watch as the climate suitability of the species shifted (usually contracted) into the future.

This is a giant leap in communication of the value of models for projecting likely impacts of climate change.  When users can see a clear relationship between the data that is used to create the model, and the model itself, they clearly understood that climate change can impact on the available climate space of a species, and therefore the range of the species.  When users saw that suitability ranges not only shifted, but contracted substantially, the usual reaction was to find another species to see if the same pattern of contraction applied to that species. 

Edgar allows scientists, the public, and policy-makers to see what is likely to happen to climate suitability for a species into the future and can therefore assist them in making decisions regarding conservation and climate change action.  All users reported that display of these maps in the format displayed on Edgar can be very useful for those purposes.
