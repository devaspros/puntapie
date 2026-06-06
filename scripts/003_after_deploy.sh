#!/bin/bash

APP_DIR="puntapie"
BASE_DIR="/home/ubuntu/$APP_DIR"
DEPLOY_DIR="$BASE_DIR/deployments/api-release"
LOG_DIR="$BASE_DIR/deployments/logs"
APP_DIR_PATH="$BASE_DIR/app"

# PUNTAPIE
# ├── app
# └── deployments
#     ├── api-gems
#     └── api-release
#     └── logs

set -a
. /home/ubuntu/.PUNTAPIE.envs
set +a

source /usr/local/share/chruby/chruby.sh
chruby ruby-3.4.8

set -eo pipefail

# DEPLOY in release folder
#
cd $DEPLOY_DIR

# INSTALL gems
#
echo "$(date '+%F %T') Installing deployment gems" >> $LOG_DIR/002_bundle_install.log 2>&1
bundle install >> $LOG_DIR/002_bundle_install.log 2>&1

echo "$(date '+%F %T') Installing npm packages" >> $LOG_DIR/003_npm_install.log 2>&1
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "$(date '+%F %T') create vendor/bundle" >> $LOG_DIR/004_create_vendor.log 2>&1
[ -d $APP_DIR_PATH/vendor ] || mkdir -p $APP_DIR_PATH/vendor >> $LOG_DIR/004_create_vendor.log 2>&1

# SYMLINK api-gems to app/vendor/bundle
#
echo "$(date '+%F %T') Symlink api-gems to vendor/bundle" >> $LOG_DIR/005_symlink_gems.log 2>&1
ln -fsv $BASE_DIR/deployments/api-gems/bundle $APP_DIR_PATH/vendor/ >> $LOG_DIR/005_symlink_gems.log 2>&1

# SYMLINK NVM node to /usr/local/bin/node
#
# ~./clave is a file holding server user password so that the command can be run by an agent like Github Actions.
#
echo "$(date '+%F %T') Symlink NVM node to /usr/local/bin/node" >> $LOG_DIR/006_symlink_node.log 2>&1
cat ~/.clave | sudo -S ln -sfv /home/ubuntu/.nvm/versions/node/v18.16.1/bin/node /usr/local/bin/node >> $LOG_DIR/006_symlink_node.log 2>&1

# CLEAN old assets
#
echo "$(date '+%F %T') Clobber assets" >> $LOG_DIR/007_clobber_assets.log 2>&1
RAILS_ENV=$RAILS_ENV SECRET_KEY_BASE=$SECRET_KEY_BASE bundle exec rake assets:clobber >> $LOG_DIR/007_clobber_assets.log 2>&1

# COMPILE assets
#
echo "$(date '+%F %T') Compiling assets" >> $LOG_DIR/008_precompile_assets.log 2>&1
RAILS_ENV=$RAILS_ENV SECRET_KEY_BASE=$SECRET_KEY_BASE bundle exec rake assets:precompile >> $LOG_DIR/008_precompile_assets.log 2>&1

if [ -f "$BASE_DIR/deployments/vite-assets.tar.gz" ]; then
  echo "$(date '+%F %T') Extracting Vite assets from GitHub Actions" >> $LOG_DIR/009_extract_vite.log 2>&1

  cd $DEPLOY_DIR/public/
  tar -xzf $BASE_DIR/deployments/vite-assets.tar.gz >> $LOG_DIR/009_extract_vite.log 2>&1
  rm $BASE_DIR/deployments/vite-assets.tar.gz

  echo "$(date '+%F %T') Vite assets extracted successfully" >> $LOG_DIR/009_extract_vite.log 2>&1
else
  echo "$(date '+%F %T') No vite-assets.tar.gz found, skipping extraction" >> $LOG_DIR/009_extract_vite.log 2>&1
fi

# Run migrations
#
echo "$(date '+%F %T') Running migrations" >> $LOG_DIR/010_run_migrations.log 2>&1
RAILS_ENV=$RAILS_ENV SECRET_KEY_BASE=$SECRET_KEY_BASE bundle exec rake db:migrate RAILS_ENV=$RAILS_ENV >> $LOG_DIR/010_run_migrations.log 2>&1

# SYMLINK nginx configuration file to /etc/nginx/sites-enabled
#
echo "$(date '+%F %T') Symlinking nginx configuration file" >> $LOG_DIR/011_symlink_nginx.log 2>&1
sudo ln -fs $APP_DIR_PATH/config/nginx.$APP_DIR.$RAILS_ENV.conf /etc/nginx/sites-enabled/

# SYMLINK PUNTAPIE.sidekiq.service to user folder at /home/ubuntu/.config/systemd/user/PUNTAPIE.sidekiq.service
#
echo "$(date '+%F %T') Symlinking puntapie.sidekiq.service configuration file" >> $LOG_DIR/201_sidekiq_service_symlink.log 2>&1
sudo ln -fs $APP_DIR_PATH/scripts/puntapie.sidekiq.service /home/ubuntu/.config/systemd/user/
systemctl --user daemon-reload >> $LOG_DIR/201_sidekiq_service_symlink.log 2>&1

# Ensure Sidekiq service is enabled (starts on boot)
echo "$(date '+%F %T') Enabling puntapie.sidekiq.service" >> $LOG_DIR/201_sidekiq_service_symlink.log 2>&1
systemctl --user enable puntapie.sidekiq.service >> $LOG_DIR/201_sidekiq_service_symlink.log 2>&1
