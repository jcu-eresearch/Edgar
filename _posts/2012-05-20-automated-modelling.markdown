---
title:   Automated Modelling
layout:  post
author:  robert
summary: A description of the automated modelling process
excerpt:
categories: [Development]
tags:    [modelling, HPC, distribution maps]
---

Introduction
==============

One of the requirements of AP03 is that the species distribution maps (under
various climate change scenarios), be automatically generated. The following is
a brief explanation of how we achieve this goal.

We decided to implement the automated modelling process in two parts. The
first part was a web service. We built the web service directly into the cake
app. The web service can provide a requester with information about what species
should be modelled next, and can receive updates recording the current job
status for a species.
The second part was a HPC script. The HPC script interacts with the web service,
and starts jobs to model the species indicated by the web service. It also
monitors the state of jobs, and sends modelling status updates to the web
service.

What To Model?
==============

The first thing to consider is how do we determine what needs to be modelled.

The order in which to model different species is determined by two factors:

1. has a user specifically requested the model, and
2. how many dirty (out of date) occurrences are there for this species.

A model that has been requested by a user is considered an interactive level
priority model. Other models are considered to have a background priority. All
interactive level models are ran before background priority models.

Within the given priority level, model priority is determined by the number of
dirty occurrences. The model with the most dirty occurrences is ran first.

What To Model? - Web Service Interaction
----------------------------------------

The web service provides the following URI: <code>/species/next_job/</code>.
The web service either returns the species id of the species to model next,
or a 204 (no content) page.

The HPC script performs a GET request on this URI to determine what to run next.
If it receives a 204, it knows that there is nothing to run at the moment.

The URI will continue to return the same species id (the highest priority species)
until it receives a HTTP POST indicating that a HPC job has been queued.

Modelling the Species
========================

The HPC script determines what species to model using the aforementioned URI.
Assuming there is a species in need of remodelling, the HPC script would
receive a species id to model in response to its request. The HPC script
accesses the database containing the private occurrence data for the species, and notes the
current number of dirty occurrences for the species. It does this because, when it finishes modelling,
it will be necessary to inform the cake app of how many dirty occurrences there 
were when it started modelling. I'll explain why the cake app needs this 
information later. Now that it has noted the number of dirty occurrences for the
species, it generates an input CSV from the occurrence data that is compatible
with Jeremy's (our client's) species distribution modelling scripts. Once
the input CSV is generated, the modelling job is submitted to the HPC. This is
done using the <code>qsub</code> command.
Assuming the job was successfully queued on the HPC, the cake app is provided
a status update via a POST to the URI: <code>/species/job_status/SPECIES_ID</code>.
The status update includes the fact that the species was **QUEUED**.

At this point, the species distribution has been queued on the HPC, and the
cake app has been informed that the job is queued. As soon as the cake app
received the update for the species saying that its job is underway, it stops
returning that species in response to the <code>/species/next_job/</code> request.

The HPC script will continue to monitor the state of the job, and will
post job status updates to the cake app. These status updates are the result
of the <code>qstat</code> command.

If the HPC script detects that the job successfully completes, it will send a status
update of **FINISHED_SUCCESS** to the cake app, along with the number of
dirty occurrences there were when the job started. If instead the HPC script detects 
that the job has failed, or has been running for an excessively long period of 
time, it will abort the job, and send a status update of **FINISHED_FAILURE** 
to the cake app.

Finishing Modelling
========================

The HPC script operates as a simple loop, so when it completes a species 
distribution map job, it simply moves on to the next species to model. When there 
is nothing to model, it simply sleeps, and then loops again.

When the cake app receives a **FINISHED_SUCCESS** status update, it subtracts
the number of dirty occurrences indicated by the HPC model status update from the
number of dirty occurrences against the associated species. If no changes were
made to the occurrence data during the model, then this would result in the
number of dirty occurrences going to zero for the species, indicating that the 
species was up to date. If however during the modelling
a species did receive occurrence updates, then the number of dirty occurrences
would be above zero after the subtraction, meaning that the species distribution 
model is still out of date.

Benefits
=============

By separating the automated modelling into two sections, we can get the 
following benefits:

* Managing priority, what to model next, is entirely handled through the cake
app.
* The cake app controls the updating of state, and is the only part that needs
write access to the database (of these two parts).
* The cake app doesn't need access to the private occurrence data, only the
modelling script does. This increases the security of the private occurrence data,
and makes it less likely it will be inadvertently leaked through the web app.
* The modular nature of the solution means that should someone else
want to use the AP03 software at another institute, they only need to modify 
the HPC script to work with their HPC. They don't need to modify the web
service code. Similarly, if we wanted to run our models on another HPC, for example
Amazon's EC2, we only need modify the HPC script.
