#!/bin/bash

# Author: Robert Pyke
#
# Script to queue a HPC Job for a species.
#
# Takes 2 Args
#
# 1. The species to model.
# 2. The working directory.
# 3. The input CSV containing the species occurrence data for modelling.

CURRENT_SPECIES_ID="$1"
WORKING_DIR="$2"
INPUT_CSV="$3"

BIN_DIR="$WORKING_DIR/bin"

MODELS_SPP_SH="$BIN_DIR/modelspp.sh"
TMP_IO_OUTPUT_DIR="$WORKING_DIR/tmp/io"

PRIVATE_OCCUR_DIR="$WORKING_DIR/inputs/$CURRENT_SPECIES_ID"
PRIVATE_OCCUR_FILE="$PRIVATE_OCCUR_DIR/.private_occur.csv"

# Copy the input CSV to the private occur file location
cp "$INPUT_CSV" "$PRIVATE_OCCUR_FILE" > /dev/null

AP03_SPP="$CURRENT_SPECIES_ID"

# Setup the IO dir
rm -rfd "$TMP_IO_OUTPUT_DIR/$AP03_SPP" > /dev/null
mkdir -p "$TMP_IO_OUTPUT_DIR/$AP03_SPP" > /dev/null

# Set the species env var (AP03_SPP) for the model script
# Set the working directory for the model script
export AP03_SPP
export WORKING_DIR

# Then run the qsub
CURRENT_HPC_JOB_ID=`qsub -S /bin/bash -V -o "$TMP_IO_OUTPUT_DIR/$AP03_SPP/std.out" -e "$TMP_IO_OUTPUT_DIR/$AP03_SPP/err.out" "$MODELS_SPP_SH"`

CMD_EXIT_CODE="$?"

if [ $CMD_EXIT_CODE -eq "0" ]; then
    echo -n "$CURRENT_SPECIES_ID"
    exit 0
else
    exit $CMD_EXIT_CODE
fi
