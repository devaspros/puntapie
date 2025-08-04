#!/bin/bash

# configure the crontab for ubuntu
# crontab -e
#
# 30 0 * * * bash /home/ubuntu/PUNTAPIE/app/scripts/clean_backup_folder.sh >> /home/ubuntu/PUNTAPIE/deployment_logs/100_cron.log 2>&1

# Remove all files from ~/PUNTAPIE/backups

echo "Cleaning backup folder"
rm ~/PUNTAPIE/backups/*
