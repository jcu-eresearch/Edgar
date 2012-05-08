import os
import os.path
from subprocess import Popen, PIPE
import time
from datetime import datetime
import socket
import httplib, urllib
import urllib2
from datetime import datetime
import logging
import logging.handlers
import db
import csv
import json
import tempfile
import ala

log = logging.getLogger()

# Set a default timeout for all socket requests
socketTimeout = 10
socket.setdefaulttimeout(socketTimeout)

# All time variables in UTC (not localtime)

class HPCConfig:
    #cakeAppBaseURL = "http://tdh-tools-2.hpc.jcu.edu.au/Edgar/webapplication"
    cakeAppBaseURL = "http://localhost/~robert/ap03"
    nextSpeciesURL= cakeAppBaseURL + "/species/next_job"


    # Determine the paths to the different files
    #workingDir = os.path.join('/', 'home', 'jc155857', 'ap03', 'modelling')
    workingDir = os.path.join('/', 'Users', 'robert', 'Git_WA', 'Edgar', 'modelling')
    importingWorkingDir = os.path.join(workingDir, '../', 'importing')

    importingConfigPath = os.path.join(importingWorkingDir, 'config.json')

    binDir     = os.path.join(workingDir, 'bin')

    modelSppScriptPath    = os.path.join(binDir, 'modelspp.sh')

    queueJobScriptPath          = os.path.join(binDir, 'queueJob.sh')
    checkJobStatusScriptPath    = os.path.join(binDir, 'checkJobStatus.sh')

    @staticmethod
    def getSpeciesReportURL(speciesId):
        return HPCConfig.cakeAppBaseURL + "/species/job_status/" + speciesId

    @staticmethod
    def connectDB():
        config = None
        with open(HPCConfig.importingConfigPath, 'rb') as f:
            config = json.load(f)

        db.connect(config)

        return db

# A container for our HPC Job Statuses
# Any job status not defined here is a qstat status
class HPCJobStatus:
    queued          = "QUEUED"
    finishedSuccess = "FINISHED_SUCCESS"
    finishedFailure = "FINISHED_FAILURE"

class HPCJob:

    # How long until a job should be considered failed
    expireJobAfterXSeconds = ( 3 * 60 * 60 ) # 3 hours

    @staticmethod
    def getNextSpeciesId():
        log.debug("Determining the next species Id, %s", HPCConfig.nextSpeciesURL)
        try:
            connection = urllib2.urlopen(HPCConfig.nextSpeciesURL)
            responseCode = connection.getcode()
            log.debug("Response code: %s", responseCode)

            if responseCode == 200:
                speciesToModel = connection.read()
                log.debug("Determined next species to model is: %s", speciesToModel)

                return speciesToModel

            elif responseCode == 204:
                log.debug("No species to model")
                return None

            else:
                log.warn("Unexpected response code. Response code should have been 200 or 204")
                return None

        except (urllib2.URLError, urllib2.HTTPError, socket.timeout) as e:
            log.warn("Error reading next species URL: %s", e)
            return None

    def __init__(self, speciesId):
        self.speciesId = speciesId
        self.jobId            = None
        self.jobStatus        = None
        self.jobStatusMsg     = None
        self.jobQueuedTime    = None
        self.jobFinishTime    = None
        self.tempfile         = None
        self.writeCSVSpeciesJobFile()

    def _setJobId(self, jobId):
        self.jobId = jobId
        return self.jobId

    def _setDirtyOccurrences(self, dirtyOccurrences):
        self.dirtyOccurrences = dirtyOccurrences
        return self.dirtyOccurrences

    def _setJobQueuedTimeToNow(self):
        self.jobQueuedTime = time.gmtime()
        return self.jobQueuedTime

    def _setJobFinishTimeToNow(self):
        self.jobFinishTime = time.gmtime()
        return self.jobFinishTime

    def _setJobStatus(self, status):
        self.jobStatus = status
        self._lastUpdatedJobStatus = time.gmtime()
        return self.jobStatus

    def _setJobExpired(self):
        self._setJobStatus(HPCJobStatus.finishedFailure)
        self.jobStatusMsg  = "Job took too long to complete (expired)"
        return None

    def _recordQueuedJob(self, jobId):
        self._setJobQueuedTimeToNow
        self._setJobId(jobId)
        self._setJobStatus(HPCJobStatus.queued)
        return True

    def _setTempfile(self, f):
        if self.tempfile == None:
            self.tempfile = f
        else:
            raise Exception("Can't set tempfile for a job more than once")
        return self.tempfile

    def writeCSVSpeciesJobFile(self):
        try:
            HPCConfig.connectDB()

            species_row = db.species.select()\
                    .where(db.species.c.id == self.speciesId)\
                    .execute().fetchone()
            if species_row == None:
                # This shouldn't happen...
               raise Exception("Couldn't find species with id " + self.speciesId + " in table. This shouldn't happen.")
            else:
                dirtyOccurrences = species_row['num_dirty_occurrences']
                self._setDirtyOccurrences(dirtyOccurrences)
                log.debug("Found %s dirtyOccurrences for species %s", dirtyOccurrences, self.speciesId)

                f = tempfile.NamedTemporaryFile(delete=False)
                self._setTempfile(f.name)
                log.debug("Writing csv to: %s", f.name)
                writer = csv.writer(f)
                writer.writerow(["SPECIES_ID", "LATITUDE", "LONGITUDE"])

                occurrence_rows = db.occurrences.select()\
                        .where(db.occurrences.c.species_id == self.speciesId)\
                        .execute()
                for occurrence_row in occurrence_rows:
                    # We found it, grab the species id
                    writer.writerow([self.speciesId, occurrence_row['latitude'], occurrence_row['longitude']])

                f.close()
        except Exception as e:
            log.warn("Exception while trying to write CSV file species. Exception: %s", e)
            raise

    def __enter__(self):
        return self

    def __exit__(self, type, value, traceback):
        self.cleanup()

    # If we had a tempfile, delete it
    def cleanup(self):
        if self.tempfile:
            try:
                os.unlink(self.tempfile)
                os.path.exists(self.tempfile)
            except Exception as e:
                log.warn("Exception while deleting tmpfile (%s) for job. Exception: %s", self.tempfile, e)

    def isExpired(self):
        return ( ( time.gmtime() - self.jobQueuedTime ) > HPCJob.expireJobAfterXSeconds )

    def isDone(self):
        return ( self.jobStatus == HPCJobStatus.finishedSuccess or
        self.jobStatus == HPCJobStatus.finishedFailure )

    def queue(self):
        log.debug("Queueing job for %s", self.speciesId)

        # Run the hpc queue script
        cmd = [HPCConfig.queueJobScriptPath, self.speciesId, HPCConfig.workingDir, self.tempfile]
        p = Popen(cmd, stdout=PIPE, stderr=PIPE)
        stdout, stderr = p.communicate()
        returnCode = p.returncode

        if returnCode == 0:
            self._recordQueuedJob(stdout)
            log.debug("Succesfully queued job (job_id: %s)", self.jobId)
            return True;
        else:
            log.error(
                (
                    "Failed to queue job.\n\t" +
                    "exit_code: %s\n\t" +
                    "stdout: %s\n\t" +
                    "stderr: %s"
                ), returnCode, stdout, stderr
            )
            return False;

    def checkStatus(self):
        log.debug("Checking status of job %s (%s)", self.jobId, self.speciesId)

        if self.isExpired():
            # The job is too old, expire it
            log.warn("Current job took too long to complete, expiring job.")
            self._setJobExpired()
            return True
        else:
            # Run the hpc queue script
            cmd = [HPCConfig.checkJobStatusScriptPath, self.jobId, HPCConfig.workingDir]
            p = Popen(cmd, stdout=PIPE, stderr=PIPE)
            stdout, stderr = p.communicate()
            returnCode = p.returncode

            if returnCode == 0:
                self._setJobStatus(stdout)
                log.debug("Succesfully checked job status %s (job_id: %s)", self.jobStatus, self.jobId)
                return True;
            else:
                log.error(
                    (
                        "Failed to check job status.\n\t" +
                        "exit_code: %s\n\t" +
                        "stdout: %s\n\t" +
                        "stderr: %s"
                    ), returnCode, stdout, stderr
                )
                return False;

    def reportStatusToCakeApp(self):
        try:
            url = HPCConfig.getSpeciesReportURL(self.speciesId)
            log.debug("url: %s", url)
            values = {
                'job_status': self.jobStatus,
                'job_status_message': self.jobStatusMsg,
                'dirty_occurrences': self.dirtyOccurrences
            }
            data = urllib.urlencode(values)
            req = urllib2.Request(url, data)
            connection = urllib2.urlopen(req)
            responseContent = connection.read()
            responseCode = connection.getCode()

            if responseCode == 200:
                log.debug("Reported job status, response: %s", responseContent)
                return True
            else:
                log.warn("Failed to report job status, response: %s", responseContent)
                return False

        except (urllib2.URLError, urllib2.HTTPError, socket.timeout) as e:
            log.warn("Error reporting job status: %s", e)
            return False
