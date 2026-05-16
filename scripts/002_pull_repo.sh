#!/bin/bash
set -eo pipefail

APP_DIR="puntapie"
BASE_DIR="/home/ubuntu/$APP_DIR"
DEPLOY_DIR="$BASE_DIR/deployments/api-release"
LOG_DIR="$BASE_DIR/deployments/logs"

# PUNTAPIE
# ├── app
# └── deployments
#     ├── api-gems
#     └── api-release
#     └── logs

. /home/ubuntu/.PUNTAPIE.envs

cd $DEPLOY_DIR

# PULL from GitHub Repo
# There's an SSH key configured in the server's ~/.ssh folder
# that is allowed to pull changes from the private repo.
#
echo "$(date '+%F %T') Pull from Repo" >> $LOG_DIR/001_pull_remote.log 2>&1
git pull origin main >> $LOG_DIR/001_pull_remote.log 2>&1
