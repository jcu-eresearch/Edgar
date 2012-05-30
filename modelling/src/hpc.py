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
import paramiko
import ssh

log = logging.getLogger()

# Set a default timeout for all socket requests
socketTimeout = 10
socket.setdefaulttimeout(socketTimeout)

class HPCConfig:
    cakeAppBaseURL = "http://tdh-tools-2.hpc.jcu.edu.au/Edgar/webapplication"
    #cakeAppBaseURL = "http://localhost/~robert/ap03"
    nextSpeciesURL= cakeAppBaseURL + "/species/next_job"
    sshUser = "jc155857"
    sshHPCDestination = "login.hpc.jcu.edu.au"

    # Determine the paths to the different files
    workingDir = os.path.join('/', 'home', 'jc155857', 'scratch', 'Edgar', 'modelling')
    #workingDir = os.path.join('/', 'Users', 'robert', 'Git_WA', 'Edgar', 'modelling')
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
        self.jobStatusMsg     = ""
        self.jobQueuedTime    = None
        self.tempfile         = None
        self._writeCSVSpeciesJobFile()

    def _setJobId(self, jobId):
        self.jobId = jobId
        return self.jobId

    def _setDirtyOccurrences(self, dirtyOccurrences):
        self.dirtyOccurrences = dirtyOccurrences
        return self.dirtyOccurrences

    def _setJobQueuedTimeToNow(self):
        self.jobQueuedTime = time.time()
        return self.jobQueuedTime

    def _setJobStatus(self, status):
        self.jobStatus = status
        self._lastUpdatedJobStatus = time.time()
        return self.jobStatus

    def _setJobExpired(self):
        self._setJobStatus(HPCJobStatus.finishedFailure)
        self.jobStatusMsg  = "Job took too long to complete (expired)"
        return None

    def _recordQueuedJob(self, jobId):
        self._setJobQueuedTimeToNow()
        self._setJobId(jobId)
        self._setJobStatus(HPCJobStatus.queued)
        return True

    def _setTempfile(self, f):
        if self.tempfile == None:
            self.tempfile = f
        else:
            raise Exception("Can't set tempfile for a job more than once")
        return self.tempfile

    def _writeCSVSpeciesJobFile(self):
        try:
            # Connect the DB
            HPCConfig.connectDB()

            # Select the species row that matches this job's species
            species_row = db.species.select()\
                    .where(db.species.c.id == self.speciesId)\
                    .execute().fetchone()
            if species_row == None:
                # We didn't find the species in the table..
                # this shouldn't happen...
               raise Exception("Couldn't find species with id " + self.speciesId + " in table. This shouldn't happen.")
            else:
                # We foudn it
                # Now record the no. of dirtyOccurrences
                dirtyOccurrences = species_row['num_dirty_occurrences']
                self._setDirtyOccurrences(dirtyOccurrences)
                log.debug("Found %s dirtyOccurrences for species %s", dirtyOccurrences, self.speciesId)

                # Create a tempfile to write our csv file to
                f = tempfile.NamedTemporaryFile(delete=False)
                # Remember the path to the csv file
                self._setTempfile(f.name)
                log.debug("Writing csv to: %s", f.name)
                writer = csv.writer(f)
                # Write the header
                writer.writerow(["SPPCODE", "LATDEC", "LONGDEC"])

                # Select the occurrences for this species
                occurrence_rows = db.occurrences.select()\
                        .where(db.occurrences.c.species_id == self.speciesId)\
                        .execute()
                # Iterate over the occurrences, and write them to the csv
                for occurrence_row in occurrence_rows:
                    writer.writerow([self.speciesId, occurrence_row['latitude'], occurrence_row['longitude']])

                # Be a good file citizen, and close the file handle
                f.close()
        except Exception as e:
            log.warn("Exception while trying to write CSV file species. Exception: %s", e)
            raise

    # Allow someone to use this class with the *with* syntax
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

    # Has this job expired?
    def isExpired(self):
        return ( ( time.time() - self.jobQueuedTime ) > HPCJob.expireJobAfterXSeconds )

    # Is this job done?
    def isDone(self):
        return ( self.jobStatus == HPCJobStatus.finishedSuccess or
        self.jobStatus == HPCJobStatus.finishedFailure )

    # Queue this job on the HPC
    # Returns true if we queued the job
    # Returns false if we failed to queue the job
    def queue(self):
        log.debug("Queueing job for %s", self.speciesId)

        client_scp = ssh.Connection(HPCConfig.sshHPCDestination, username=HPCConfig.sshUser)

        client_scp.put(self.tempfile, self.tempfile)
        client_scp.close()

        # Connect to the HPC
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.WarningPolicy())
        client.connect(HPCConfig.sshHPCDestination, username=HPCConfig.sshUser)


        # Run the hpc queue script
        sshCmd = HPCConfig.queueJobScriptPath + " '" + self.speciesId + "' '" + HPCConfig.workingDir + "' '" + self.tempfile + "'"
        log.debug("ssh command: %s", sshCmd)
        chan = client.get_transport().open_session()
        chan.exec_command(sshCmd)
        returnCode = chan.recv_exit_status()
        # TODO remove magic numbers..
        stdout = chan.recv(1024)
        stderr = chan.recv_stderr(1024)
        log.debug("Queue Return Code: %s", returnCode)
        log.debug("Queue Output: %s", stdout)
        client.close()

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


    # Check the status of this job.
    # Returns true if we updated the status
    # Returns false otherise
    def checkStatus(self):
        log.debug("Checking status of job %s (%s)", self.jobId, self.speciesId)

        # TODO should check isDone before isExpired

        if self.isExpired():
            # The job is too old, expire it
            log.warn("Current job took too long to complete, expiring job.")
            self._setJobExpired()
            return True
        else:
            # Run the hpc check status script
            sshCmd = HPCConfig.checkJobStatusScriptPath + " '" + self.jobId + "' '" + HPCConfig.workingDir + "'"

            # Connect to the HPC
            client = paramiko.SSHClient()
            client.set_missing_host_key_policy(paramiko.WarningPolicy())
            client.connect(HPCConfig.sshHPCDestination, username=HPCConfig.sshUser)
            log.debug("ssh command: %s", sshCmd)
            chan = client.get_transport().open_session()
            chan.exec_command(sshCmd)
            returnCode = chan.recv_exit_status()
            # TODO remove magic numbers..
            stdout = chan.recv(1024)
            stderr = chan.recv_stderr(1024)

            log.debug("Check Status Return Code: %s", returnCode)
            log.debug("Check Status Output: %s", stdout)
            client.close()

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

    # Send the job's status to the cake app.
    # Returns true if we sent the status update correctly.
    # Returns false if we failed to send the status update.
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
            responseCode = connection.getcode()

            if responseCode == 200:
                log.debug("Reported job status, response: %s", responseContent)
                return True
            else:
                log.warn("Failed to report job status, response: %s", responseContent)
                return False

        except (urllib2.URLError, urllib2.HTTPError, socket.timeout) as e:
            log.warn("Error reporting job status: %s", e)
            return False      