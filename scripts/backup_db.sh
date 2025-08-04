#!/bin/bash

# configure the crontab for ubuntu
# crontab -e
#
# will run every twelve hours.
#
# 0 */12 * * * bash /home/ubuntu/PUNTAPIE/app/scripts/backup_db.sh >> /home/ubuntu/PUNTAPIE/deployment_logs/100_cron.log 2>&1
#
# Backup database file to PUNTAPIE/db-backups folder in Mega

destination=PUNTAPIE/db-backups
db_file="/home/ubuntu/PUNTAPIE/db/PUNTAPIE_production.sqlite"
tmp_destination="/home/ubuntu/PUNTAPIE/backups"

# Create archive filename with timestamp
day=$(date +"%Y%m%d%s")
archive_file="PUNTAPIE_db_$day.tgz"

# Backup the files using tar.
tar czf /home/ubuntu/PUNTAPIE/backups/$archive_file $db_file

echo "Upload DB backup to Mega destination folder"
mega-put $tmp_destination/$archive_file $destination

echo "Completed backup"
