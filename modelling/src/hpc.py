import os
from subprocess import Popen, PIPE
import time
from datetime import datetime
import urllib2
from datetime import datetime
import logging
import logging.handlers
import httplib, urllib

log = logging.getLogger()

# All time variables in UTC (not localtime)

class HPCConfig:
    #cakeAppBaseURL = "http://tdh-tools-2.hpc.jcu.edu.au/Edgar/webapplication"
    cakeAppBaseURL = "http://localhost/~robert/ap03"
    nextSpeciesURL= cakeAppBaseURL + "/species/next_job"


    # Determine the paths to the different files
    #workingDir = os.path.join('/', 'home', 'jc155857', 'ap03', 'modelling')
    workingDir = os.path.join('/', 'Users', 'robert', 'Git_WA', 'Edgar', 'modelling')
    binDir     = os.path.join(workingDir, 'bin')
    configDir  = os.path.join(workingDir, 'config')

    environmentConfigPath = os.path.join(configDir, 'environment.cfg')
    modelSppScriptPath    = os.path.join(binDir, 'modelspp.sh')

    queueJobScriptPath          = os.path.join(binDir, 'queueJob.sh')
    checkJobStatusScriptPath    = os.path.join(binDir, 'checkJobStatus.sh')

    @staticmethod
    def getSpeciesReportURL(speciesId):
        return HPCConfig.cakeAppBaseURL + "/species/job_status/" + speciesId

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

        except urllib2.HTTPError, e:
            log.warn("Error reading next species URL: %s", e)
            return None

    def __init__(self, speciesId):
        self.speciesId = speciesId
        self.jobId            = None
        self.jobStatus        = None
        self.jobStatusMsg     = None
        self.jobQueuedTime    = None
        self.jobFinishTime    = None

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

    def isExpired(self):
        return ( ( time.gmtime() - self.jobQueuedTime ) > HPCJob.expireJobAfterXSeconds )

    def isDone(self):
        return ( self.jobStatus == HPCJobStatus.finishedSuccess or
        self.jobStatus == HPCJobStatus.finishedFailure )

    def queue(self):
        log.debug("Queueing job for %s", self.speciesId)

        # Run the hpc queue script
        cmd = [HPCConfig.queueJobScriptPath, self.speciesId, HPCConfig.workingDir]
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

        except urllib2.HTTPError, e:
            log.warn("Error reporting job status: %s", e)
            return False
