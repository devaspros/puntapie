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
  --exclude "tmp/" \
  $DEPLOY_DIR/ \
  $BASE_DIR/app/ \
  >> $LOG_DIR/012_rsync_files.log 2>&1

# truncate -s 0 log/$RAILS_ENV.log
#
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

# =========================================================
# SYSTEMD (PRODUCTION - SYSTEM LEVEL)
# =========================================================

SERVICE_NAME="puntapie.puma.service"
SERVICE_PATH="$APP_DIR_PATH/scripts/$SERVICE_NAME"
SYSTEMD_PATH="/etc/systemd/system/$SERVICE_NAME"

echo "$(date '+%F %T') Symlinking systemd service file" >> $LOG_DIR/210_puma_service_symlink.log 2>&1

sudo ln -fs "$SERVICE_PATH" "$SYSTEMD_PATH"

echo "$(date '+%F %T') Reloading systemd daemon" >> $LOG_DIR/210_puma_service_symlink.log 2>&1
sudo systemctl daemon-reload >> $LOG_DIR/210_puma_service_symlink.log 2>&1

echo "$(date '+%F %T') Enabling service" >> $LOG_DIR/210_puma_service_symlink.log 2>&1
sudo systemctl enable "$SERVICE_NAME" >> $LOG_DIR/210_puma_service_symlink.log 2>&1

echo "$(date '+%F %T') Restarting service" >> $LOG_DIR/210_puma_service_symlink.log 2>&1
sudo systemctl restart "$SERVICE_NAME" >> $LOG_DIR/210_puma_service_symlink.log 2>&1

# RELOAD nginx para que tome cualquier cambio en la config
#
echo "$(date '+%F %T') Reloading nginx" >> $LOG_DIR/211_nginx_reload.log 2>&1
sudo systemctl reload nginx >> $LOG_DIR/211_nginx_reload.log 2>&1
