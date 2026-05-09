#!/bin/bash -xe

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

echo "$(date '+%F %T') Pull from Repo" >> $LOG_DIR/001_pull_remote.log 2>&1
git pull origin main >> $LOG_DIR/001_pull_remote.log 2>&1
