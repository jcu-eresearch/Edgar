#!/bin/bash

# Add to cron like so (runs every day at 1am):
# min hr  dom mth dow cmd
# 0   1   *   *   *   /home/jc171154/Edgar/importing/bin/ala_cron.sh

IMPORTER_DIR="/var/www/webroot/Edgar/importing"
LOG_DIR="$IMPORTER_DIR/logs"
SYNC_SCRIPT="$IMPORTER_DIR/bin/ala_db_update"
CONFIG_FILE="$IMPORTER_DIR/config.json"

LOG_FILE="$LOG_DIR/$(date "+%Y-%m-%d %H:%M:%S").log"
"$SYNC_SCRIPT" "$CONFIG_FILE" &> "$LOG_FILE"
