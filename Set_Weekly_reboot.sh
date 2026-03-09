#!/bin/bash

# Define cron job
CRON_JOB="0 4 * * 6 /sbin/shutdown -r now"

# Check if the cron job already exists
if crontab -l | grep -Fxq "$CRON_JOB"; then
    echo "Weekly reboot is already scheduled."
else
    # Add the cron job
    (crontab -l; echo "$CRON_JOB") | crontab -
    echo "Weekly reboot scheduled for every Sunday at 3 AM."
fi
