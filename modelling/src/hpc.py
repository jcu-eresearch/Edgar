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
import re
from hpc_config import HPCConfig
import sqlalchemy
from sqlalchemy import distinct
from sqlalchemy import or_

log = logging.getLogger()

# Set a default timeout for all socket requests
socketTimeout = 10
socket.setdefaulttimeout(socketTimeout)

# A container for our HPC Job Statuses
# Any job status not defined here is a qstat status
class HPCJobStatus:
    queued          = "QUEUED"
    finishedSuccess = "FINISHED_SUCCESS"
    finishedFailure = "FINISHED_FAILURE"

class HPCJob:

    # How long until a job should be considered failed
    # Note: Needs to take into consideration HPC may be full
    # and I may have to wait in the queue.
    expireJobAfterXSeconds = ( 24 * 60 * 60 ) # 24 hours

    @staticmethod
    def getNextSpeciesId():
        log.debug("Determining the next species Id, %s", HPCConfig.nextSpeciesURL)
        try:
            values = {}
            data = urllib.urlencode(values)
            req = urllib2.Request(HPCConfig.nextSpeciesURL, data)
            connection = urllib2.urlopen(req)
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
        self.speciesCommonName  = ""
        self.speciesSciName   = ""
        self.jobQueuedTime    = None
        self.metaDataTempfile = None
        self.privateTempfile  = None
        self.publicTempfile   = None
        self._writeCSVSpeciesJobFile()

    def getSafeSpeciesName(self):
        speciesName = self.speciesCommonName + " (" + self.speciesSciName + ")"
        cleanName = re.sub(r"[^A-Za-z0-9'_., ()-]", '_', speciesName)
        strippedCleanName = cleanName.strip()

        return strippedCleanName

    def getSpeciesNameForMetaData(self):
        speciesName = self.speciesCommonName + " (" + self.speciesSciName + ")"
        strippedCleanName = speciesName.strip()

        return strippedCleanName

    def getMetaDataSourceDict(self, sourceName, sourceHomePage):
        resultURL = None

        # Special handle the case where the source is the ALA
        # We can build a species specific URL for these guys
        if (sourceName == 'ALA') :
            speciesSciName = self.speciesSciName
            processedName = re.sub(r"[ ]", '+', speciesSciName)
            processedName = processedName.strip()
            resultURL = "http://bie.ala.org.au/species/" + processedName
            resultNotes = "ALA - Species page for " + self.getSpeciesNameForMetaData()
        # Else..
        # Just use the defined source home page URL
        else :
            resultURL = sourceHomePage
            resultNotes = "" + sourceName + " - home page"

        return { "identifier" : { "type": "uri", "value": resultURL }, "notes" : resultNotes }

    def _setJobId(self, jobId):
        self.jobId = jobId
        return self.jobId

    def _setSpeciesCommonName(self, speciesCommonName):
        self.speciesCommonName = speciesCommonName or ""
        return self.speciesCommonName

    def _setSpeciesSciName(self, speciesSciName):
        self.speciesSciName = speciesSciName or ""
        return self.speciesSciName

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

    def _setPublicTempfile(self, f):
        if self.publicTempfile == None:
            self.publicTempfile = f
        else:
            raise Exception("Can't set publicTempfile for a job more than once")
        return self.publicTempfile

    def _setPrivateTempfile(self, f):
        if self.privateTempfile == None:
            self.privateTempfile = f
        else:
            raise Exception("Can't set privateTempfile for a job more than once")
        return self.privateTempfile

    def _setMetaDataTempfile(self, f):
        if self.metaDataTempfile == None:
            self.metaDataTempfile = f
        else:
            raise Exception("Can't set metaDataTempfile for a job more than once")
        return self.metaDataTempfile

    def _writeCSVSpeciesJobFile(self):
        try:
            # Connect the DB
            HPCConfig.connectDB()
            try:
                # Select the species row that matches this job's species
                species_row = db.species.select()\
                        .where(db.species.c.id == self.speciesId)\
                        .execute().fetchone()
                if species_row == None:
                    # We didn't find the species in the table..
                    # this shouldn't happen...
                   raise Exception("Couldn't find species with id " + self.speciesId + " in table. This shouldn't happen.")
                else:
                    # We found it
                    # Now record the no. of dirtyOccurrences
                    dirtyOccurrences = species_row['num_dirty_occurrences']
                    self._setDirtyOccurrences(dirtyOccurrences)

                    self._setSpeciesCommonName(species_row['common_name'])
                    self._setSpeciesSciName(species_row['scientific_name'])
                    log.debug("Found %s dirtyOccurrences for species %s", dirtyOccurrences, self.speciesId)

                    # Create tempfiles to write our csv content to
                    priv_f     = tempfile.NamedTemporaryFile(delete=False)
                    pub_f      = tempfile.NamedTemporaryFile(delete=False)
                    metaData_f = tempfile.NamedTemporaryFile(delete=False)
                    try:
                        # Remember the path to the csv file
                        self._setPrivateTempfile(priv_f.name)
                        self._setPublicTempfile(pub_f.name)
                        self._setMetaDataTempfile(metaData_f.name)

                        log.debug("Writing public csv to: %s", pub_f.name)
                        log.debug("Writing private csv to: %s", priv_f.name)
                        log.debug("Writing meta data json to: %s", metaData_f.name)

                        # Write the metadata

                        # Get access to the sources for this species
                        # SELECT DISTINCT url, name, source_id FROM occurrences, sources WHERE occurrences.source_id=sources.id AND species_id=1;
                        source_rows = sqlalchemy.select(['url', 'name', 'source_id']).\
                            select_from(db.occurrences.join(db.sources)).\
                            where(db.occurrences.c.species_id == self.speciesId).\
                            distinct().\
                            execute()

                        meta_data_source_array = []

                        # Append to our meta data source array each source we found
                        for source_row in source_rows :
                            source_url  = source_row['url']
                            source_name = source_row['name']

                            meta_data_source_array.append(
                                self.getMetaDataSourceDict(source_name, source_url)
                            )

                        # Dump the source metadata
                        metaDataString = json.dumps({
                            "harvester": {
                                "type": "directory",
                                "metadata": {
                                    "occurrences": [{
                                        "species_name" : self.getSpeciesNameForMetaData(),
                                        "data_source_website" : meta_data_source_array
                                    }],
                                    "suitability": [{
                                        "species_name" : self.getSpeciesNameForMetaData(),
                                        "data_source_website" : meta_data_source_array
                                    }]
                                }
                            }
                        })

                        metaData_f.write(metaDataString)

                        pub_writer  = csv.writer(pub_f)
                        priv_writer = csv.writer(priv_f)

                        # Write the header
                        pub_writer.writerow(["LATDEC", "LONGDEC", "DATE", "BASIS", "CLASSIFICATION"])
                        priv_writer.writerow(["SPPCODE", "LATDEC", "LONGDEC"])

                        # Select the occurrences for this species
                        occurrence_rows = sqlalchemy.select([
                            'ST_X(location) as longitude',
                            'ST_Y(location) as latitude',
                            'ST_X(sensitive_location) as sensitive_longitude',
                            'ST_Y(sensitive_location) as sensitive_latitude',
                            'date',
                            'basis',
                            'classification']).\
                            select_from(db.occurrences.outerjoin(db.sensitive_occurrences)).\
                            where(db.occurrences.c.species_id == self.speciesId).\
                            where(or_(db.occurrences.c.classification == 'unknown', db.occurrences.c.classification >= 'core')).\
                            execute()

                        # Iterate over the occurrences, and write them to the csv
                        for occurrence_row in occurrence_rows:
                            pub_lat  = occurrence_row['latitude']
                            pub_lng  = occurrence_row['longitude']
                            pub_date = ('' if occurrence_row['date'] is None else occurrence_row['date'].isoformat())
                            pub_basis = ('' if occurrence_row['basis'] is None else occurrence_row['basis'])
                            pub_classi = ('' if occurrence_row['classification'] is None else occurrence_row['classification'])
                            pub_writer.writerow([pub_lat, pub_lng, pub_date, pub_basis, pub_classi])

                            if occurrence_row['sensitive_longitude'] is None:
                                priv_lat = occurrence_row['latitude']
                                priv_lon = occurrence_row['longitude']
                            else:
                                priv_lat = occurrence_row['sensitive_latitude']
                                priv_lon = occurrence_row['sensitive_longitude']
                            priv_writer.writerow([self.speciesId, priv_lat, priv_lon])

                    finally:
                        # Be a good file citizen, and close the file handle
                        pub_f.close()
                        priv_f.close()
                        metaData_f.close()
            finally:
                # Dispose the DB
                HPCConfig.disposeDB();
        except Exception as e:
            log.warn("Exception while trying to write CSV file species. Exception: %s", e)
            raise
    # Allow someone to use this class with the *with* syntax
    def __enter__(self):
        return self

    def __exit__(self, type, value, traceback):
        self.cleanup()

    # If we had tempfile/s, delete it
    def cleanup(self):
        if self.publicTempfile:
            try:
                os.unlink(self.publicTempfile)
                os.path.exists(self.publicTempfile)
            except Exception as e:
                log.warn("Exception while deleting public tmpfile (%s) for job. Exception: %s", self.publicTempfile, e)

        if self.privateTempfile:
            try:
                os.unlink(self.privateTempfile)
                os.path.exists(self.privateTempfile)
            except Exception as e:
                log.warn("Exception while deleting private tmpfile (%s) for job. Exception: %s", self.privateTempfile, e)

        if self.metaDataTempfile:
            try:
                os.unlink(self.metaDataTempfile)
                os.path.exists(self.metaDataTempfile)
            except Exception as e:
                log.warn("Exception while deleting meta data tmpfile (%s) for job. Exception: %s", self.metaDataTempfile, e)

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

        client_scp.put(self.privateTempfile, self.privateTempfile)
        client_scp.put(self.publicTempfile, self.publicTempfile)
        client_scp.put(self.metaDataTempfile, self.metaDataTempfile)

        client_scp.close()

        # Connect to the HPC
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.WarningPolicy())
        client.connect(HPCConfig.sshHPCDestination, username=HPCConfig.sshUser)


        # Run the hpc queue script
        sshCmd = HPCConfig.queueJobScriptPath + ' "' + self.speciesId + '" "'  + self.getSafeSpeciesName() +  '" "' + HPCConfig.workingDir + '" "' + self.privateTempfile + '" "' + self.publicTempfile +  '" "' + self.metaDataTempfile +  '"'

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

        if self.isDone():
            # The job is done, no need to check status
            return True
        elif self.isExpired():
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
