#!/bin/bash

# Author: Robert Pyke
#
# Script to queue a HPC Job for a species.
#
# Takes 3 Args
#
# 1. The species to model.
# 2. The working directory.
# 3. The input CSV containing the species occurrence data for modelling.

CURRENT_SPECIES_ID="$1"
CURRENT_SPECIES_CLEAN_NAME="$2"
WORKING_DIR="$3"
INPUT_PRIV_CSV="$4"
INPUT_PUB_CSV="$5"

BIN_DIR="$WORKING_DIR/bin"

MODELS_SPP_SH="$BIN_DIR/modelspp_incl_median.sh"
TMP_IO_OUTPUT_DIR="$WORKING_DIR/tmp/io"

mkdir -p "$TMP_IO_OUTPUT_DIR" > /dev/null

OCCUR_DIR="$WORKING_DIR/inputs/$CURRENT_SPECIES_ID"
mkdir -p "$OCCUR_DIR" > /dev/null
PUBLIC_OCCUR_FILE="$OCCUR_DIR/public_occur.csv"
PRIVATE_OCCUR_FILE="$OCCUR_DIR/.private_occur.csv"

# Copy the input CSV to the private occur file location
mv "$INPUT_PRIV_CSV" "$PRIVATE_OCCUR_FILE" > /dev/null
mv "$INPUT_PUB_CSV" "$PUBLIC_OCCUR_FILE" > /dev/null

AP03_SPP="$CURRENT_SPECIES_ID"
AP03_SPP_CLEAN_NAME="$CURRENT_SPECIES_CLEAN_NAME"

# Setup the IO dir
rm -rfd "$TMP_IO_OUTPUT_DIR/$AP03_SPP" > /dev/null
mkdir -p "$TMP_IO_OUTPUT_DIR/$AP03_SPP" > /dev/null

# Set the species env var (AP03_SPP) for the model script
# Set the working directory for the model script
export AP03_SPP
export AP03_SPP_CLEAN_NAME
export WORKING_DIR

# Then run the qsub
CURRENT_HPC_JOB_ID=`qsub -l nodes=1:ppn=4 -S /bin/bash -V -o "$TMP_IO_OUTPUT_DIR/$AP03_SPP/std.out" -e "$TMP_IO_OUTPUT_DIR/$AP03_SPP/err.out" "$MODELS_SPP_SH"`

CMD_EXIT_CODE="$?"

if [ $CMD_EXIT_CODE -eq "0" ]; then
    echo -n "$CURRENT_HPC_JOB_ID"
    exit 0
else
    exit $CMD_EXIT_CODE
fi
