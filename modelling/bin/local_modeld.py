#!/usr/bin/env python

import pathfix
import sys
import logging
import logging.handlers
import json
from time import sleep
import os
import random
from subprocess import Popen, PIPE
from hpc import Job, LocalHPCJob, HPCJobStatus
import urllib2
from datetime import datetime
import traceback
import subprocess
import commands

# Setup the logger
log = logging.getLogger()
log.setLevel(logging.DEBUG)
log.addHandler(logging.StreamHandler())

log.debug("Starting modeld.py")

currentJob = None
currentCycle = 0

minSleepTime = 10
maxSleepTime = 60

# The Main Loop
while True:

    # Sleep a time, then go round again
    # Inject randomness into the sleep time to reduce likelihood of multiple
    # scripts running against the same species (no longer an issue, the web request 
    # for next species will no longer return the same species multiple times, unless it needs remodelling).
    randSleepTime = random.randint(minSleepTime, maxSleepTime)
    log.debug("Sleeping %i seconds.", randSleepTime)
    sleep(randSleepTime)

    currentCycle += 1
    log.debug("Loop %i (%s). Current Job: %s", currentCycle, datetime.today(), currentJob)

    # Check if we are handling a current job
    if currentJob == None:
        try:
            log.debug("No current job...")

            # If we don't have a current job,
            # determine what the next species job would be.
            speciesId = LocalHPCJob.getNextSpeciesId()
            if speciesId:

                # We got the species, so try and queue HPC Job for it.
                    currentJob = LocalHPCJob(speciesId)
                    log.debug("Queuing a job for: %s", speciesId)
                    queued = currentJob.queue()

                    if queued:
                        # We were able to queue a job,
                        # so report the current status to the cake app
                        currentJob.reportStatusToCakeApp()
                    else:
                        # We couldn't queue a job for the species,
                        # so clear the current job
                        currentJob.cleanup()
                        currentJob = None
        except Exception:
            # swallow any exceptions
            log.error("Error while trying to queue a new job: %s", traceback.format_exc())

            # clear the current job var
            if currentJob:
                currentJob.cleanup()
                currentJob = None

    else:
        try:
            # If we have a current job...
            log.debug("Continuing current job...")

            # Check the status of the job
            checked = currentJob.checkStatus()

            if checked:
                # We were able to check the status of the job,
                # so report the status to the cake app
                reported = currentJob.reportStatusToCakeApp()
                if reported and currentJob.isDone():
                    currentJob.cleanup()
                    currentJob = None

            else:
                # We couldn't determine the status of the current job
                log.warn("Failed to determine the status of the current job")
        except Exception:
            # swallow any exceptions
            log.error("Error while trying to proccess an existing job: %s", traceback.format_exc())

