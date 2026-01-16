#!/bin/bash -xe

# PUNTAPIE
# ├── app
# └── deployments
#     ├── api-gems
#     └── api-release

set -e

# CLEAN CURRENT APP
#
# This step is covered by using RSync. It only replaces modified files.

# PULL Repo from GitHub
#
bash /home/ubuntu/PUNTAPIE/deployments/api-release/scripts/002_pull_repo.sh

# RUN bundle, symlink bundled gems to api/vendor, assets:precompile,
#  migrations, symlink nginx.$RAILS_ENV.conf
#
bash /home/ubuntu/PUNTAPIE/deployments/api-release/scripts/003_after_deploy.sh

# SYNC api-release with api folder
#
bash /home/ubuntu/PUNTAPIE/deployments/api-release/scripts/004_application_start.sh
