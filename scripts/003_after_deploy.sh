#!/bin/bash -xe

APP_DIR="puntapie"

# PUNTAPIE
# ├── app
# └── deployments
#     ├── api-gems
#     └── api-release

. /home/ubuntu/.profile

# DEPLOY in release folder
#
cd /home/ubuntu/$APP_DIR/deployments/api-release

# INSTALL gems
#
echo "$(date '+%F %T') Installing deployment gems" >> /home/ubuntu/$APP_DIR/deployment_logs/002_bundle_install.log 2>&1
bundle install --deployment \
  --without development test \
  --path /home/ubuntu/$APP_DIR/deployments/api-gems/bundle \
  >> /home/ubuntu/$APP_DIR/deployment_logs/002_bundle_install.log 2>&1

# CHECK or CREATE app/vendor
#
echo "$(date '+%F %T') create vendor/bundle" >> /home/ubuntu/$APP_DIR/deployment_logs/003_bundle_symlink.log 2>&1
[ -d /home/ubuntu/$APP_DIR/app/vendor ] || mkdir -p /home/ubuntu/$APP_DIR/app/vendor >> /home/ubuntu/$APP_DIR/deployment_logs/003_bundle_symlink.log 2>&1

# SYMLINK api-gems to app/vendor/bundle
#
echo "$(date '+%F %T') Symlink api-gems to vendor/bundle" >> /home/ubuntu/$APP_DIR/deployment_logs/003_bundle_symlink.log 2>&1
ln -fsv /home/ubuntu/$APP_DIR/deployments/api-gems/bundle /home/ubuntu/$APP_DIR/app/vendor/ >> /home/ubuntu/$APP_DIR/deployment_logs/003_bundle_symlink.log 2>&1

# SYMLINK NVM node to /usr/local/bin/node
#
# ~./clave is a file holding server user password so that the command can be run by an agent like Github Actions.
#
echo "$(date '+%F %T') Symlink NVM node to /usr/local/bin/node" >> /home/ubuntu/$APP_DIR/deployment_logs/004_node_symlink.log 2>&1
cat ~/.clave | sudo -S ln -sfv /home/ubuntu/.nvm/versions/node/v18.16.1/bin/node /usr/local/bin/node >> /home/ubuntu/$APP_DIR/deployment_logs/004_node_symlink.log 2>&1

# CLEAN old assets
#
echo "$(date '+%F %T') Clobber assets" >> /home/ubuntu/$APP_DIR/deployment_logs/011_clobber_assets.log 2>&1
RAILS_ENV=$RAILS_ENV SECRET_KEY_BASE=$SECRET_KEY_BASE bundle exec rake assets:clobber >> /home/ubuntu/$APP_DIR/deployment_logs/011_clobber_assets.log 2>&1

# COMPILE assets
#
echo "$(date '+%F %T') Compiling assets" >> /home/ubuntu/$APP_DIR/deployment_logs/005_assets_precompile.log 2>&1
RAILS_ENV=$RAILS_ENV SECRET_KEY_BASE=$SECRET_KEY_BASE bundle exec rake assets:precompile >> /home/ubuntu/$APP_DIR/deployment_logs/005_assets_precompile.log 2>&1

# Run migrations
#
echo "$(date '+%F %T') Running migrations" >> /home/ubuntu/$APP_DIR/deployment_logs/006_migration.log 2>&1
RAILS_ENV=$RAILS_ENV SECRET_KEY_BASE=$SECRET_KEY_BASE bundle exec rake db:migrate RAILS_ENV=$RAILS_ENV >> /home/ubuntu/$APP_DIR/deployment_logs/006_migration.log 2>&1

# SYMLINK nginx configuration file to /etc/nginx/sites-enabled
#
echo "$(date '+%F %T') Symlinking nginx configuration file" >> /home/ubuntu/$APP_DIR/deployment_logs/007_nginx_symlink.log 2>&1
sudo ln -fs /home/ubuntu/$APP_DIR/app/config/nginx.$APP_DIR.$RAILS_ENV.conf /etc/nginx/sites-enabled/
