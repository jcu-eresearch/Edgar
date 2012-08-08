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

# WORKING_DIR DIR is set by ENV variables

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

# Generate the name of the tmp output dir (use the PID to uniquely name the dir)
TMP_DIR_NAME="$SPP-$$"
# Make an output directory
TMP_OUTPUT_DIR="$WORKING_DIR/tmp_outputs/$TMP_DIR_NAME"
OUTPUTS_DIR="$WORKING_DIR/outputs"
FINAL_OUTPUT_DIR="$OUTPUTS_DIR/$SPP"

mkdir -p "$TMP_OUTPUT_DIR"
mkdir -p "$OUTPUTS_DIR"

declare -a YEARS_TO_MODEL=('2015' '2025' '2035' '2045' '2055' '2065' '2075' '2085')
declare -a SCENARIOS_TO_MODEL=('RCP3PD' 'RCP45' 'RCP6' 'RCP85')
declare -a LETTERS=(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)

# declare -a MODELS_TO_MODEL=('cccma-cgcm31' 'ccsr-miroc32hi' 'ccsr-miroc32med' 'cnrm-cm3'), etc.

function model_and_median {
    local SCENARIO=$1
    local YEAR=$2

    # 1 or many any, then /$scenario_$model_$year
    # where model is anything except an underscore (or /)
    local FILTER_PROJECTION_PATH=".*/${SCENARIO}_[^_/]+_${YEAR}"

    local MEDIAN_SCRIPT_TO_RUN="$WORKING_DIR/bin/median.py --outfile=$TMP_OUTPUT_DIR/${SCENARIO}_median_${YEAR}.tif --calc='A' --overwrite "
    local I_INT=0

    # Cycle through the projections and project the maps
    for PROJ in `find "$PROJECTCLIMATE" -mindepth 1 -type d -regex "$FILTER_PROJECTION_PATH"`; do

        java -mx2048m -cp "$MAXENT" density.Project "$TMP_OUTPUT_DIR/${SPP}.lambdas" "$PROJ" "$TMP_OUTPUT_DIR/"`basename "$PROJ"`.asc fadebyclamping nowriteclampgrid nowritemess -x

        local letter="${LETTERS[$I_INT]}"
        MEDIAN_SCRIPT_TO_RUN="$MEDIAN_SCRIPT_TO_RUN -$letter $TMP_OUTPUT_DIR/`basename $PROJ`.asc"
        let I_INT+=1

    done
    
    # At this point, the modelling is complete for this scenario year combo
    
    # Now calc the median

    # Execute the py script.
    $MEDIAN_SCRIPT_TO_RUN
    # Translate output to ascii grid
    gdal_translate "$TMP_OUTPUT_DIR/${SCENARIO}_median_${YEAR}.tif" "$TMP_OUTPUT_DIR/${SCENARIO}_median_${YEAR}.asc" -of AAIGrid

}

# Dump the environmental vars to the output dir
`printenv > "$TMP_OUTPUT_DIR/JOB_ENV_VARS.txt"`

# Produce training data
java -mx2048m -jar "$MAXENT" environmentallayers="$TRAINCLIMATE" samplesfile="$OCCUR" outputdirectory="$TMP_OUTPUT_DIR" -J -P -x -z redoifexists autorun

# Model the 'current' projection ( in the background )
java -mx2048m -cp "$MAXENT" density.Project "$TMP_OUTPUT_DIR/${SPP}.lambdas" "$TRAINCLIMATE" "$TMP_OUTPUT_DIR/"`basename "$TRAINCLIMATE"`.asc fadebyclamping nowriteclampgrid nowritemess -x &

# Model all models for each scenario year combo
for SCENARIO in "${SCENARIOS_TO_MODEL[@]}"; do
    for YEAR in "${YEARS_TO_MODEL[@]}"; do
        NUM_RUNNING=`jobs -p | wc -l`

        while [ "$NUM_RUNNING" -ge "$MAX_NUM_PROCS" ]; do
            # I have hit the maximum number of simultaneous jobs running
            # Sleep periodically, and recheck.
            sleep 1
            NUM_RUNNING=`jobs -p | wc -l`
        done

        model_and_median "$SCENARIO" "$YEAR" &
    done
done

# Wait for all remaining jobs to go to zero...
wait

# TODO
# Add some sanity checks before removing any existing good output data

# Remove any existing final output
rm -rfd "$FINAL_OUTPUT_DIR"

# Move the tmp output to the final output location
mv "$TMP_OUTPUT_DIR" "$FINAL_OUTPUT_DIR"

# Give read access to everyone
chmod -R ugo+rX "$FINAL_OUTPUT_DIR"
