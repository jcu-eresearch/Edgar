#!/bin/bash

# Author: Robert Pyke
#
# Daemon for running HPC bird distribution modelling jobs.
#
# Only capable of handling a single in-flight job at a time.
#
# Requests jobs from the associated cake-app (see config for URL),
# and then generates distributions.
#
# Reports status of job to cake-app throughout the job life cycle.
#
# See issue #253 (https://eresearch.jcu.edu.au/redmine/issues/253) for
# detailed documentation.
#
# NOTE/TODO:
# ===========
#
# There is a clear and present risk of timing bugs
# -------------------------------------------------
#
# At the moment, in the best case scenario, it may take only a few moments ( < second)
# between the server telling the HPC what species to model and the
# HPC gathering all inputs (making a copy) and reporting back to the server 
# that it has started modelling.
#
# * It is possible that the inputs are being modified while the HPC is copying them.
# * It is possible that after the HPC gets the inputs, but before it reports that
#   it has started modelling, that the inputs data is updated (the original, not the copy)
#   This would mean that the server would be under the impression that the
#   HPC is modelling newer data than it actually is.
#
# One way to fix this would be to set an updates since last modelled.
# When the HPC asks for a species to model, it could be told a species id, and a
# changes_since_last_modelled. When the HPC starts a job, and reports in that 
# the species is being modelled, it could report in both the species, and the 
# changes since last model (as it remembers).
# The server can then deduct this number from its internal store of changes_since_last_modelled.
# If the changes_since_last_modelled is at 0, then it doesn't need to be modelled again.
# If the changes_since_last_modelled is still > 0, then it needs to be modelled again.
#
#
# Job statuses are not resent on failure
# --------------------------------------------------
#
# At present, when a job status fails to be sent, it isn't resent.
#
# This is especially problematic for the status 'QUEUED', which indicates that modelling
# has started for the species.

# Determine path to this file.
BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# WORKING_DIR is one up from this file (which is in bin)
WORKING_DIR="$BIN_DIR/.."

# Determine path to config (based on path to this file)
CONFIG_DIR="$WORKING_DIR/config"
ENVIRONMENT_CFG="$CONFIG_DIR/environment.cfg"

MODELS_SPP_SH="$BIN_DIR/modelspp.sh"

# Load the config file.
# This defines file paths, etc.
#
# Relevant vars set:
#   CYCLE_SLEEP_TIME
#   CAKE_ROOT_URI
source "$ENVIRONMENT_CFG"

echo "WORKING_DIR: $WORKING_DIR"
echo "CYCLE_SLEEP_TIME: $CYCLE_SLEEP_TIME"
echo "MODELS_SPP_SH: $MODELS_SPP_SH"
echo "CAKE_ROOT_URI: $CAKE_ROOT_URI"

TMP_IO_OUTPUT_DIR="$WORKING_DIR/tmp/io"
echo "TMP_IO Dir: $TMP_IO_OUTPUT_DIR"

CAKE_NEXT_JOB_URI="$CAKE_ROOT_URI/species/next_job"
CAKE_REPORT_JOB_STATUS_URI="$CAKE_ROOT_URI/species/job_status"

# A global to hold our current SPECIES_ID, and our current HPC_JOB_ID
CURRENT_SPECIES_ID=""
CURRENT_HPC_JOB_ID=""
CURRENT_HPC_JOB_START_TIME=""

# Function to get the next job on the queue.
#
# Sets:
#  * CURRENT_SPECIES_ID
#
# CURRENT_SPECIES_ID is cleared (empty-string) in the case of no
# species_id to model, or failure determining next species_id to model
function get_next_job_species_id {
    echo -n "Getting next species id for modelling... "

    # Curl the next job URI.
    # Append to the response ';<http_response_code>'
    NEXT_JOB_RESPONSE=`curl -sL "$CAKE_NEXT_JOB_URI" -w ";%{http_code}"`
    # Don't do anything unless the above worked
    if [ "$?" -eq "0" ]; then
        # Process the response
        OLD_IFS="$IFS"
        IFS=";"
        RESPONSE_ARRAY=( $NEXT_JOB_RESPONSE )
        IFS="$OLD_IFS"

        # Split on the ;,
        # The first element is the species_id
        # The second element is the http_response_code
        SPECIES_ID="${RESPONSE_ARRAY[0]}"
        RESPONSE_CODE="${RESPONSE_ARRAY[1]}"

        if [ "$RESPONSE_CODE" -eq "200" ]; then
            # 200 (OK): We got a Species Id
            echo "$SPECIES_ID"
            CURRENT_SPECIES_ID="$SPECIES_ID"
        elif [ "$RESPONSE_CODE" -eq "503" ]; then
            # 503 (Service Unavailable): Nothing to run
            echo "nothing to run"
            clear_current
        else
            echo ""
            clear_current
            # Unexpected response code
            log_error "Unexpected Response: $NEXT_JOB_RESPONSE"
        fi
    else
        # Curl Failed
        log_error "Curl Failed: $NEXT_JOB_RESPONSE"
    fi
}

# Function to log something to stderr with a timestamp
function log_error {
    echo "[E] `date`: $1" >&2
}

# Function to queue a job.
#
# Starts: CURRENT_SPECIES_ID
#
# Sets:
#   * CURRENT_HPC_JOB_ID
#   * CURRENT_HPC_JOB_START_TIME
function queue_job {
    local AP03_SPP="$CURRENT_SPECIES_ID"
    echo "Queueing job: $AP03_SPP"

    # Setup the IO dir
    rm -rfd "$TMP_IO_OUTPUT_DIR/$AP03_SPP"
    mkdir -p "$TMP_IO_OUTPUT_DIR/$AP03_SPP"

    # Set the species env var (AP03_SPP) for the model script
    export AP03_SPP

    # Then run the qsub
    CURRENT_HPC_JOB_ID=`qsub -S /bin/bash -V -o "$TMP_IO_OUTPUT_DIR/std.out" -e "$TMP_IO_OUTPUT_DIR/err.out" "$MODELS_SPP_SH" 2>&1`
    CURRENT_HPC_JOB_START_TIME=`date +%s`

    # Check the exit code
    # If something went wrong,
    # clear the CURRENT_* vars.
    if [ "$?" -ne "0" ]; then
        log_error "Failed to queue job on HPC: $CURRENT_HPC_JOB_ID"

        # Clear the current species/job vars
        clear_current
    fi
}

# Takes one arg
# 1. The status to report
function report_status {
    local STATUS_TO_REPORT="$1"
    local REPORT_URI="$CAKE_ROOT_URI/species/job_status/$CURRENT_SPECIES_ID"

    CURL_OUTPUT=`curl -sL -F "status=$STATUS_TO_REPORT" -w "%{http_code}" "$REPORT_URI" -o /dev/null`
    local CMD_EXIT_CODE="$?"
    if [ "$CMD_EXIT_CODE" -ne "0" ]; then
        log_error "Failed to report status of $STATUS_TO_REPORT to $REPORT_URI. Curl command failed. Curl output: $CURL_OUTPUT. Curl exit code: $CMD_EXIT_CODE"
    elif [ "$CURL_OUTPUT" -ne "200" ]; then
        log_error "Failed to report status of $STATUS_TO_REPORT to $REPORT_URI. HTTP response code not okay. Curl output: $CURL_OUTPUT."
    fi
}

function check_and_report_status {
    # Check if the job is still running
    QSTAT_GREP_OUTPUT=`qstat -f "$CURRENT_HPC_JOB_ID" | grep -P "^\s*job_state\s*=" | grep -Po "=.*" | grep -Po "\w"`
    QSTAT_GREP_EXIT_CODE="$?"

    if [ "$QSTAT_GREP_EXIT_CODE" -ne "0" ]; then
        # The output of the qstat command wasn't valid.
        # We assume this means the job wasn't found in the qstat.
        # We assume that this means the job is finished.
        mark_current_as_finished
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
        report_status "$QSTAT_GREP_OUTPUT"
    fi
}

function mark_current_as_finished {
    # Report that the job is finished
    report_status "FINISHED"

    # Note the finish time.
    CURRENT_HPC_JOB_FINISH_TIME=`date +%s`

    # TODO take note how long the job ran for..
    # If it appears to have taken too short of a time, report the error.

    # Clear our current job status, so that we queue a new job
    # on our next cycle
    clear_current
}

function clear_current {
    CURRENT_SPECIES_ID=""
    CURRENT_HPC_JOB_ID=""
    CURRENT_HPC_JOB_START_TIME=""
    CURRENT_HPC_JOB_FINISH_TIME=""
}

CYCLE_COUNT=0

while true; do
    CYCLE_COUNT=`expr $CYCLE_COUNT + 1`
    echo "---------------------------------------"
    echo "Starting cycle $CYCLE_COUNT at `date`"
    echo "Current Species Id: $CURRENT_SPECIES_ID"
    echo "Current HPC Job: $CURRENT_HPC_JOB_ID"

    if [ -z "$CURRENT_HPC_JOB_ID" ]; then
        # No current HPC Job, we need to queue a new job.

        # This function sets CURRENT_SPECIES_ID if there is a species that needs 
        # to be modelled
        get_next_job_species_id

        # If we now have a 
        if [ -n "$CURRENT_SPECIES_ID" ]; then
            # We have something to model
            echo "$CURRENT_SPECIES_ID"

            # Queue Job
            queue_job

            # If everything went according to plan, CURRENT_HPC_JOB_ID will now be set.
            if [ -n "$CURRENT_HPC_JOB_ID" ]; then
                echo "Queued job: $AP03_SPP [$CURRENT_HPC_JOB_ID]"

                # Report the queueing of the job to the cake app
                report_status "QUEUED"
            fi
        fi
    else
        # We have a current job, check its status 
        check_and_report_status
    fi

    sleep $CYCLE_SLEEP_TIME
done

