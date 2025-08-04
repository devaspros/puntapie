#!/bin/bash

# configure the crontab for ubuntu
# crontab -e
#
# will run every tweenty three hours.
#
# 0 */23 * * * bash /home/ubuntu/PUNTAPIE/app/scripts/backup_logs.sh >> /home/ubuntu/PUNTAPIE/deployment_logs/100_cron.log 2>&1
#
# Backup log file to PUNTAPIE/prod-logs folder in Mega

destination=PUNTAPIE/prod-logs
log_file="/home/ubuntu/PUNTAPIE/app/log/production.log"
tmp_destination="/home/ubuntu/PUNTAPIE/backups"

# Create archive filename with timestamp
day=$(date +"%Y%m%d%s")
archive_file="PUNTAPIE_log_$day.tgz"

# Backup the files using tar.
tar czf /home/ubuntu/PUNTAPIE/backups/$archive_file $log_file

echo "Upload Logs backup to Mega destination folder"
mega-put $tmp_destination/$archive_file $destination

echo "Completed log backup"
