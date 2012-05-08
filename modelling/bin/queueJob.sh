#!/bin/bash

# Author: Robert Pyke
#
# Script to queue a HPC Job for a species.
#
# Takes 2 Args
#
# 1. The species to model.
# 2. The working directory.

CURRENT_SPECIES_ID="$1"
WORKING_DIR="$2"

BIN_DIR="$WORKING_DIR/bin"

MODELS_SPP_SH="$BIN_DIR/modelspp.sh"
TMP_IO_OUTPUT_DIR="$WORKING_DIR/tmp/io"

AP03_SPP="$CURRENT_SPECIES_ID"

# Setup the IO dir
rm -rfd "$TMP_IO_OUTPUT_DIR/$AP03_SPP" > /dev/null
mkdir -p "$TMP_IO_OUTPUT_DIR/$AP03_SPP" > /dev/null

# Set the species env var (AP03_SPP) for the model script
export AP03_SPP

# Then run the qsub
CURRENT_HPC_JOB_ID=`qsub -S /bin/bash -V -o "$TMP_IO_OUTPUT_DIR/std.out" -e "$TMP_IO_OUTPUT_DIR/err.out" "$MODELS_SPP_SH"`

CMD_EXIT_CODE="$?"

if [ $CMD_EXIT_CODE -eq "0" ]; then
    echo -n "$CURRENT_SPECIES_ID"
    exit 0
else
    exit $CMD_EXIT_CODE
fi
