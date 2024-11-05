#!/bin/bash

# This script writes log messages to multiple log files every second.

LOG_FILES=(
    "/var/log/test_app1.log"
    "/var/log/log2/test_app2.log"
    "/var/log/log2/log3/test_app3.log"
    "/var/log/log2/log3/log4/test_app4.log"
)

# Ensure the log files exist and have appropriate permissions
for LOG_FILE in "${LOG_FILES[@]}"; do
    DIR=$(dirname "$LOG_FILE")
    mkdir -p "$DIR"
    touch "$LOG_FILE"
    chmod o+rw "$LOG_FILE"
done

echo "Starting to write logs to multiple files. Press Ctrl+C to stop."

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    LOG_MESSAGE="$TIMESTAMP - INFO - This is a test log message."

    for LOG_FILE in "${LOG_FILES[@]}"; do
        echo "$LOG_MESSAGE" >> "$LOG_FILE"
    done

    sleep 1
done
