#!/bin/bash

# Author: Robert Pyke
#
# Script to check the status of a HPC Job for a job id.
#
# Takes 2 Args
#
# 1. The job id of the model.
# 2. The working directory.

JOB_ID="$1"
WORKING_DIR="$2"

# Check if the job is still running
QSTAT_GREP_OUTPUT=`qstat -f "$JOB_ID" | grep -P "^\s*job_state\s*=" | grep -Po "=.*" | grep -Po "\w"`
QSTAT_GREP_EXIT_CODE="$?"

if [ "$QSTAT_GREP_EXIT_CODE" -ne "0" ]; then
    # The output of the qstat command wasn't valid.
    # We assume this means the job wasn't found in the qstat.
    # We assume that this means the job is finished.
    echo -n "FINISHED_SUCCESS"
else
    # QSTAT_GREP_OUTPUT is a single letter representing the
    # job status.
    #
    # The different statuses are described in the qstat man page:
    # C -  Job is completed after having run.
    # E -  Job is exiting after having run.
    # H -  Job is held.
    # Q -  job is queued, eligible to run or routed.
    # R -  job is running.
    # T -  job is being moved to new location.
    # W -  job is waiting for its execution time
    #      (-a option) to be reached.
    # S -  (Unicos only) job is suspend.
    echo -n "$QSTAT_GREP_OUTPUT"
fi

exit 0
