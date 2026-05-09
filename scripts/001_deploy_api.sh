#!/bin/bash -xe

APP_DIR="puntapie"

# PUNTAPIE
# ├── app
# └── deployments
#     ├── api-gems
#     └── api-release
#     └── logs

set -e

# PULL Repo from GitHub
#
bash /home/ubuntu/$APP_DIR/deployments/api-release/scripts/002_pull_repo.sh

# RUN bundle, symlink bundled gems to api/vendor, assets:precompile,
#  migrations, symlink nginx.$RAILS_ENV.conf
#
bash /home/ubuntu/$APP_DIR/deployments/api-release/scripts/003_after_deploy.sh

# SYNC api-release with api folder
#
bash /home/ubuntu/$APP_DIR/deployments/api-release/scripts/004_application_start.sh
