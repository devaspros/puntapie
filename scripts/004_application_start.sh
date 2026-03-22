#!/bin/bash -xe

APP_DIR="puntapie"

# PUNTAPIE
# ├── app
# └── deployments
#     ├── api-gems
#     └── api-release
#     └── logs

cd /home/ubuntu/$APP_DIR/app/

. /home/ubuntu/.profile

# RSYNC: from api-release/ to app/
#
echo "$(date '+%F %T') rsyncing release folder with app folder" >> /home/ubuntu/$APP_DIR/deployments/logs/008_rsync_files.log 2>&1
rsync -arv --delete-after \
  --exclude "vendor/" \
  /home/ubuntu/$APP_DIR/deployments/api-release/ \
  /home/ubuntu/$APP_DIR/app/ \
  >> /home/ubuntu/$APP_DIR/deployments/logs/008_rsync_files.log 2>&1

# RESTART nginx
# nginx comes bundled with phussion passenger
#
# echo "$(date '+%F %T') Restarting nginx" >> /home/ubuntu/$APP_DIR/deployments/logs/009_nginx_restart.log 2>&1
# cat ~/.clave | sudo -S service nginx restart >> /home/ubuntu/$APP_DIR/deployments/logs/009_nginx_restart.log 2>&1

# RESTART aplicación (sin reiniciar Nginx)
echo "$(date '+%F %T') Reiniciando aplicación (touch tmp/restart.txt)" >> /home/ubuntu/$APP_DIR/deployments/logs/009_nginx_restart.log 2>&1
touch ./tmp/restart.txt >> /home/ubuntu/$APP_DIR/deployments/logs/009_nginx_restart.log 2>&1

# truncate -s 0 log/$RAILS_ENV.log
if [ -f "log/$RAILS_ENV.log" ]; then
  chmod 664 "log/$RAILS_ENV.log"
fi

# CHOWN log, tmp, vendor folders
# Change ownership of process files
#
echo "$(date '+%F %T') Changing ownership to ubuntu" >> /home/ubuntu/$APP_DIR/deployments/logs/010_chowning.log 2>&1
cat ~/.clave | sudo chown -Rv ubuntu:ubuntu log tmp vendor >> /home/ubuntu/$APP_DIR/deployments/logs/010_chowning.log 2>&1

# Restart Sidekiq to ensure it runs with new code
#
echo "$(date '+%F %T') Reloading systemd daemon for sidekiq" >> /home/ubuntu/$APP_DIR/deployments/logs/202_restart_sidekiq_service.log 2>&1
systemctl --user daemon-reload >> /home/ubuntu/$APP_DIR/deployments/logs/202_restart_sidekiq_service.log 2>&1

echo "$(date '+%F %T') Restarting enlacito.sidekiq.service" >> /home/ubuntu/$APP_DIR/deployments/logs/202_restart_sidekiq_service.log 2>&1
systemctl --user restart enlacito.sidekiq.service >> /home/ubuntu/$APP_DIR/deployments/logs/202_restart_sidekiq_service.log 2>&1
