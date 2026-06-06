#!/bin/bash
set -eo pipefail

APP_DIR="puntapie"
BASE_DIR="/home/ubuntu/$APP_DIR"
DEPLOY_DIR="$BASE_DIR/deployments/api-release"
LOG_DIR="$BASE_DIR/deployments/logs"

# PUNTAPIE
# ├── app
# └── deployments
#     ├── api-gems
#     └── api-release
#     └── logs

set -a
. /home/ubuntu/.PUNTAPIE.envs
set +a

cd $BASE_DIR/app/

# RSYNC: from api-release/ to app/
#
echo "$(date '+%F %T') rsyncing release folder with app folder" >> $LOG_DIR/012_rsync_files.log 2>&1
rsync -arv --delete-after \
  --exclude "vendor/" \
  $DEPLOY_DIR/ \
  $BASE_DIR/app/ \
  >> $LOG_DIR/012_rsync_files.log 2>&1

# RESTART aplicación (sin reiniciar Nginx)
echo "$(date '+%F %T') Reiniciando aplicación (touch tmp/restart.txt)" >> $LOG_DIR/013_restart_app.log 2>&1
touch ./tmp/restart.txt >> $LOG_DIR/013_restart_app.log 2>&1

# truncate -s 0 log/$RAILS_ENV.log
if [ -f "log/$RAILS_ENV.log" ]; then
  chmod 664 "log/$RAILS_ENV.log"
fi

# CHOWN log, tmp, vendor folders
# Change ownership of process files
#
echo "$(date '+%F %T') Changing ownership to ubuntu" >> $LOG_DIR/014_chown_folders.log 2>&1
cat ~/.clave | sudo -S chown -Rv ubuntu:ubuntu log tmp vendor >> $LOG_DIR/014_chown_folders.log 2>&1

# Restart Sidekiq to ensure it runs with new code
#
echo "$(date '+%F %T') Reloading systemd daemon for sidekiq" >> $LOG_DIR/202_restart_sidekiq_service.log 2>&1
systemctl --user daemon-reload >> $LOG_DIR/202_restart_sidekiq_service.log 2>&1

echo "$(date '+%F %T') Restarting enlacito.sidekiq.service" >> $LOG_DIR/202_restart_sidekiq_service.log 2>&1
systemctl --user restart enlacito.sidekiq.service >> $LOG_DIR/202_restart_sidekiq_service.log 2>&1
