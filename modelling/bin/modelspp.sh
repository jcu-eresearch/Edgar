#/bin/bash

# Requires ENV Variable AP03_SPP to be set.

# Expected call format
#
# $: mkdir -p ~/tmp
# $: rm -rfd  ~/tmp/*
# $: AP03_SPP "MAGPIES"
# $: export AP03_SPP
# $: qsub -S /bin/bash -V -o ~/tmp/my_std_out -e ~/tmp/my_std_err modelspp.sh
#
# -V means pass all env variables from the caller's env through to the script env.
# -S specifies the shell type
# -o/-e specifies where the stdout and stderr will be written

# WORKING_DIR DIR is one up from this file (which is in bin)
WORKING_DIR="/home/jc155857/ap03/modelling"

# Determine path to config (based on path to this file)
CONFIG_DIR="$WORKING_DIR/config"
ENVIRONMENT_CFG="$CONFIG_DIR/environment.cfg"

# Load the config file.
# This defines file paths, etc.
#
# Relevant vars set:
#   MAXENT
#   TRAINCLIMATE
#   PROJECTCLIMATE
source "$ENVIRONMENT_CFG"

mkdir -p $WORKING_DIR

# Define the species
# The species is expected to be provided as an environmental variable
if [ -z "$AP03_SPP" ]; then
    echo "SPP env variable (AP03_SPP) required. Please set the SPP env variable (AP03_SPP) and try again" 1>&2
    exit 1
fi

SPP=$AP03_SPP

# Determine the occurrences file.
# Use the private file if it exists, fall back to the public file if it doesn't
#
# The private file will contain unobfiscated data,
# the public file may contain obfiscated data.
PUBLIC_OCCUR="$WORKING_DIR/inputs/$SPP/public_occur.csv"
PRIVATE_OCCUR="$WORKING_DIR/inputs/$SPP/.private_occur.csv"

OCCUR=""

if [ -f "$PRIVATE_OCCUR" ]; then
    OCCUR=$PRIVATE_OCCUR
elif [ -f "$PUBLIC_OCCUR" ]; then
    OCCUR=$PUBLIC_OCCUR
else
    echo "No occurrences file found for $SPP" 1>&2
    exit 2
fi

# Load the java module for the HPC
module load java

# Move to the species directory
cd "$WORKING_DIR/inputs/$SPP"

# Make an output directory
TMP_OUTPUT_DIR="$WORKING_DIR/tmp_outputs/$SPP"
FINAL_OUTPUT_DIR="$WORKING_DIR/outputs/$SPP"

mkdir -p "$TMP_OUTPUT_DIR"
mkdir -p "$FINAL_OUTPUT_DIR"

# Dump the environmental vars to the output dir
`printenv > "$TMP_OUTPUT_DIR/JOB_ENV_VARS.txt"`

# Model the species distribution
java -mx2048m -jar "$MAXENT" environmentallayers="$TRAINCLIMATE" samplesfile="$OCCUR" outputdirectory="$TMP_OUTPUT_DIR" -J -P -x -z redoifexists autorun

# Cycle through the projections and project the maps
for PROJ in `find "$PROJECTCLIMATE" -type d`; do
    java -mx2048m -cp "$MAXENT" density.Project "$TMP_OUTPUT_DIR/${SPP}.lambdas" "$PROJ" "$TMP_OUTPUT_DIR/"`basename "$PROJ"`.asc fadebyclamping nowriteclampgrid nowritemess -x
done

# TODO
# Add some sanity checks before removing any existing good output data

# Remove any existing final output
rm -rfd "$FINAL_OUTPUT_DIR"

# Move the tmp output to the final output location
mv "$TMP_OUTPUT_DIR" "$FINAL_OUTPUT_DIR"
