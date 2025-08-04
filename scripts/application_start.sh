#!/bin/bash -xe

# PUNTAPIE
# ├── app
# └── deployments
#     ├── api-gems
#     └── api-release

cd /home/ubuntu/PUNTAPIE/app/

. /home/ubuntu/.profile

# RSYNC: from api-release/ to app/
#
echo "$(date '+%F %T') rsyncing release folder with app folder" >> /home/ubuntu/PUNTAPIE/deployment_logs/008_rsync_files.log 2>&1
rsync -arv --delete-after \
  --exclude "vendor/" \
  /home/ubuntu/PUNTAPIE/deployments/api-release/ \
  /home/ubuntu/PUNTAPIE/app/ \
  >> /home/ubuntu/PUNTAPIE/deployment_logs/008_rsync_files.log 2>&1

# RESTART nginx
# nginx comes bundled with phussion passenger
#
echo "$(date '+%F %T') Restarting nginx" >> /home/ubuntu/PUNTAPIE/deployment_logs/009_nginx_restart.log 2>&1
cat ~/.clave | sudo -S service nginx restart >> /home/ubuntu/PUNTAPIE/deployment_logs/009_nginx_restart.log 2>&1

# truncate -s 0 log/$RAILS_ENV.log
if [ -f "log/$RAILS_ENV.log" ]; then
  chmod 664 "log/$RAILS_ENV.log"
fi

# CHOWN log, tmp, vendor folders
# Change ownership of process files
#
echo "$(date '+%F %T') Changing ownership to ubuntu" >> /home/ubuntu/PUNTAPIE/deployment_logs/010_chowning.log 2>&1
sudo chown -Rv ubuntu:ubuntu log tmp vendor >> /home/ubuntu/PUNTAPIE/deployment_logs/010_chowning.log 2>&1
