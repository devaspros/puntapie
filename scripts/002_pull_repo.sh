#!/bin/bash -xe

APP_DIR="puntapie"

# PUNTAPIE
# ├── app
# └── deployments
#     ├── api-gems
#     └── api-release

. /home/ubuntu/.profile

cd /home/ubuntu/$APP_DIR/deployments/api-release

# PULL from GitHub Repo
# There's an SSH key configured in the server's ~/.ssh folder
# that is allowed to pull changes from the private repo.
#
echo "$(date '+%F %T') Pull from Repo" >> /home/ubuntu/$APP_DIR/deployment_logs/001_pull_remote.log 2>&1
git pull origin main >> /home/ubuntu/$APP_DIR/deployment_logs/001_pull_remote.log 2>&1
