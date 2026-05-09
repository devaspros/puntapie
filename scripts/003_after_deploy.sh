#!/bin/bash -xe

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

cd $DEPLOY_DIR

echo "$(date '+%F %T') Installing deployment gems" >> $LOG_DIR/002_bundle_install.log 2>&1
bundle install --deployment \
  --without development test \
  --path $BASE_DIR/deployments/api-gems/bundle \
  >> $LOG_DIR/002_bundle_install.log 2>&1

echo "$(date '+%F %T') create vendor/bundle" >> $LOG_DIR/003_bundle_symlink.log 2>&1
[ -d $APP_DIR_PATH/vendor ] || mkdir -p $APP_DIR_PATH/vendor >> $LOG_DIR/003_bundle_symlink.log 2>&1

echo "$(date '+%F %T') Symlink api-gems to vendor/bundle" >> $LOG_DIR/003_bundle_symlink.log 2>&1
ln -fsv $BASE_DIR/deployments/api-gems/bundle $APP_DIR_PATH/vendor/ >> $LOG_DIR/003_bundle_symlink.log 2>&1

echo "$(date '+%F %T') Symlink NVM node to /usr/local/bin/node" >> $LOG_DIR/004_node_symlink.log 2>&1
cat ~/.clave | sudo -S ln -sfv /home/ubuntu/.nvm/versions/node/v18.16.1/bin/node /usr/local/bin/node >> $LOG_DIR/004_node_symlink.log 2>&1

echo "$(date '+%F %T') Clobber assets" >> $LOG_DIR/011_clobber_assets.log 2>&1
RAILS_ENV=$RAILS_ENV SECRET_KEY_BASE=$SECRET_KEY_BASE bundle exec rake assets:clobber >> $LOG_DIR/011_clobber_assets.log 2>&1

echo "$(date '+%F %T') Compiling assets" >> $LOG_DIR/005_assets_precompile.log 2>&1
RAILS_ENV=$RAILS_ENV SECRET_KEY_BASE=$SECRET_KEY_BASE bundle exec rake assets:precompile >> $LOG_DIR/005_assets_precompile.log 2>&1

echo "$(date '+%F %T') Running migrations" >> $LOG_DIR/006_migration.log 2>&1
RAILS_ENV=$RAILS_ENV SECRET_KEY_BASE=$SECRET_KEY_BASE bundle exec rake db:migrate RAILS_ENV=$RAILS_ENV >> $LOG_DIR/006_migration.log 2>&1

echo "$(date '+%F %T') Symlinking nginx configuration file" >> $LOG_DIR/007_nginx_symlink.log 2>&1
sudo ln -fs $APP_DIR_PATH/config/nginx.$APP_DIR.$RAILS_ENV.conf /etc/nginx/sites-enabled/

echo "$(date '+%F %T') Symlinking puntapie.sidekiq.service configuration file" >> $LOG_DIR/201_sidekiq_service_symlink.log 2>&1
sudo ln -fs $APP_DIR_PATH/scripts/puntapie.sidekiq.service /home/ubuntu/.config/systemd/user/
systemctl --user daemon-reload >> $LOG_DIR/201_sidekiq_service_symlink.log 2>&1

echo "$(date '+%F %T') Enabling puntapie.sidekiq.service" >> $LOG_DIR/201_sidekiq_service_symlink.log 2>&1
systemctl --user enable puntapie.sidekiq.service >> $LOG_DIR/201_sidekiq_service_symlink.log 2>&1
