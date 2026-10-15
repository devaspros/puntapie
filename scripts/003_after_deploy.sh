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

# STOP jobs (Solid Queue)
#
# || true para que el primer deploy no falle cuando el servicio todavía no existe.
#
echo "$(date '+%F %T') Stop puntapie.jobs.service" >> $LOG_DIR/200_stop_jobs_service.log 2>&1
systemctl --user stop puntapie.jobs.service >> $LOG_DIR/200_stop_jobs_service.log 2>&1 || true

# CONFIGURACIÓN de bundle
#
echo "$(date '+%F %T') Configuración de bundle" >> $LOG_DIR/002_bundle_install.log 2>&1
bundle config set --local deployment true
bundle config set --local path '/home/ubuntu/puntapie/deployments/api-gems/bundle'
bundle config set --local without 'development test'

# INSTALL gems
#
echo "$(date '+%F %T') Installing deployment gems" >> $LOG_DIR/002_bundle_install.log 2>&1
bundle install >> $LOG_DIR/002_bundle_install.log 2>&1

# CREA carpeta vendor/bundle
#
echo "$(date '+%F %T') create vendor/bundle" >> $LOG_DIR/004_create_vendor.log 2>&1
[ -d $APP_DIR_PATH/vendor ] || mkdir -p $APP_DIR_PATH/vendor >> $LOG_DIR/004_create_vendor.log 2>&1

# SYMLINK api-gems to app/vendor/bundle
#
echo "$(date '+%F %T') Symlink api-gems to vendor/bundle" >> $LOG_DIR/005_symlink_gems.log 2>&1
ln -fsv $BASE_DIR/deployments/api-gems/bundle $APP_DIR_PATH/vendor/ >> $LOG_DIR/005_symlink_gems.log 2>&1

# CHECK node en /usr/local/bin/node
#
# execjs (autoprefixer) lo usa en assets:precompile. El symlink se crea al
# aprovisionar el servidor (dap_cloud/setup_server.sh), no en el deploy.
#
echo "$(date '+%F %T') Check /usr/local/bin/node" >> $LOG_DIR/006_check_node.log 2>&1
if [ ! -x /usr/local/bin/node ]; then
  echo "$(date '+%F %T') /usr/local/bin/node no existe o apunta a una versión que no está. Crear el symlink en el servidor." >> $LOG_DIR/006_check_node.log
  exit 1
fi
/usr/local/bin/node --version >> $LOG_DIR/006_check_node.log 2>&1

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
# db:prepare migra las bases existentes y crea las nuevas cargando su schema
# (queue_schema.rb, cache_schema.rb y cable_schema.rb no tienen migraciones).
#
echo "$(date '+%F %T') Running migrations" >> $LOG_DIR/010_run_migrations.log 2>&1
RAILS_ENV=$RAILS_ENV SECRET_KEY_BASE=$SECRET_KEY_BASE bundle exec rake db:prepare RAILS_ENV=$RAILS_ENV >> $LOG_DIR/010_run_migrations.log 2>&1

# CACHE sudo credentials
#
# ~/.clave tiene la clave del usuario del servidor para que un agente como GitHub Actions pueda usar sudo.
# `sudo -v` la deja en caché para los `sudo` siguientes de este script y de 004_application_start.sh.
#
cat ~/.clave | sudo -S -v

# SYMLINK nginx configuration file to /etc/nginx/sites-enabled
#
echo "$(date '+%F %T') Symlinking nginx configuration file" >> $LOG_DIR/011_symlink_nginx.log 2>&1
sudo ln -fs $APP_DIR_PATH/config/nginx.$APP_DIR.$RAILS_ENV.conf /etc/nginx/sites-enabled/

# SYMLINK PUNTAPIE.jobs.service to user folder at /home/ubuntu/.config/systemd/user/PUNTAPIE.jobs.service
#
echo "$(date '+%F %T') Symlinking puntapie.jobs.service configuration file" >> $LOG_DIR/201_jobs_service_symlink.log 2>&1
sudo ln -fs $APP_DIR_PATH/scripts/puntapie.jobs.service /home/ubuntu/.config/systemd/user/
systemctl --user daemon-reload >> $LOG_DIR/201_jobs_service_symlink.log 2>&1

# Ensure jobs service is enabled (starts on boot)
#
echo "$(date '+%F %T') Enabling puntapie.jobs.service" >> $LOG_DIR/201_jobs_service_symlink.log 2>&1
systemctl --user enable puntapie.jobs.service >> $LOG_DIR/201_jobs_service_symlink.log 2>&1
