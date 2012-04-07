#!/bin/bash

# Author: Robert Pyke


# Bash script to:
# 1. update status of running jobs.
#    * check queue.csv for in-progress jobs
#    * check qstat for status of each job
#    * update status of job based on output of stat command
# 2. assuming there are no currently running jobs, start the next highest 
#    priority job, and record the status change in the queue file.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR="$DIR/../config"
ENVIRONMENT_CFG="$CONFIG_DIR/environment.cfg"

# Load the config file.
# This defines file paths, etc.
#
# Relevant vars set:
#   WORKING_DIR
#   SLEEP_TIME
source "$ENVIRONMENT_CFG"

echo "WORKING_DIR: $WORKING_DIR"
echo "SLEEP_TIME: $SLEEP_TIME"

TMP_IO_OUTPUT_DIR="$WORKING_DIR/tmp/io"
echo "TMP_IO Dir: $TMP_IO_OUTPUT_DIR"

BIN_DIR="$WORKING_DIR/bin"

# Path to Species Model Script
MODELS_SPP_SH="$BIN_DIR/modelspp.sh"

# Path to update_item_on_queue.py script
UPDATE_ITEM_PY="$BIN_DIR/update_item_on_queue.py"

# Path to show_top_of_queue.py script
SHOW_TOP_OF_QUEUE_PY="$BIN_DIR/show_top_of_queue.py"

# Function to start a job.
# Takes one arg, the species to run the job for.
function start_job {
    local AP03_SPP="$1"

    # Setup the IO dir
    rm -rfd "$TMP_IO_OUTPUT_DIR"
    mkdir -p "$TMP_IO_OUTPUT_DIR"

    echo "About to start job for species: $AP03_SPP"

    # Set the species env var (AP03_SPP) for the model script
    export AP03_SPP

    # Then run the qsub
    local JOB_ID=`qsub -S /bin/bash -V -o "$TMP_IO_OUTPUT_DIR/std.out" -e "$TMP_IO_OUTPUT_DIR/err.out" "$MODELS_SPP_SH"`

    # Update the job information of the job in queue.csv
    # Arg Format: SPECIES_ID STATUS [JOB_ID]
    $UPDATE_ITEM_PY "$AP03_SPP" "S" "$JOB_ID"
}

CYCLE_COUNT=0

while true; do
    CYCLE_COUNT=`expr $CYCLE_COUNT + 1`
    echo "Starting cycle $CYCLE_COUNT at `date`"

    TOP_OF_QUEUE=`$SHOW_TOP_OF_QUEUE_PY`
    if [ $? -eq "0" ]; then
        start_job $TOP_OF_QUEUE
    else
        echo "No items on queue needing to be modelled"
    fi

    sleep $SLEEP_TIME
done

