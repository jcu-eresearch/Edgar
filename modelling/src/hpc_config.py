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

class HPCConfig:
    cakeAppBaseURL = "http://tdh-tools-2.hpc.jcu.edu.au/Edgar/webapplication"
    #cakeAppBaseURL = "http://localhost/~robert/ap03"
    nextSpeciesURL= cakeAppBaseURL + "/species/get_next_job_and_assume_queued"
    sshUser = "jc155857"
    sshHPCDestination = "login.hpc.jcu.edu.au"

    # Determine the paths to the different files
    # The working dir is the modelling dir
    workingDir = os.path.join(os.path.dirname(__file__), '../')
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

    @staticmethod
    def disposeDB():
        db.engine.dispose()
