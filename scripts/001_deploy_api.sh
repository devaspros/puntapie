#!/bin/bash -xe

APP_DIR="puntapie"

BASE_DIR="/home/ubuntu/$APP_DIR"
DEPLOY_DIR="$BASE_DIR/deployments/api-release"

# PUNTAPIE
# ├── app
# └── deployments
#     ├── api-gems
#     └── api-release
#     └── logs

set -e

# PULL Repo from GitHub
#
bash $DEPLOY_DIR/scripts/002_pull_repo.sh

# RUN bundle, symlink bundled gems to api/vendor, assets:precompile,
#  migrations, symlink nginx.$RAILS_ENV.conf
#
bash $DEPLOY_DIR/scripts/003_after_deploy.sh

# SYNC api-release with api folder
#
bash $DEPLOY_DIR/scripts/004_application_start.sh
