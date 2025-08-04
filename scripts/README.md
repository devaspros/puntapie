# Custom Deployment Scripts

Ideally, you want to deploy your application to Heroku. It's the simplest way to release a Ruby on Rails application.

However, when you need something more customized or your app is hosted in a VPS, then you're going to need to code some scripts to deploy your app.

The scripts in this section are useful to have a Capistrano-like deployment. These scripts work best if you configure them to be run by a CI server after merging changes to a set branch.

## Folder Structure

The scripts assume the following folder structure:

```bash
~/PUNTAPIE # Main folder to hold Rails app and related ones.
├── app # This is the folder that contains the Rails app.
├── deployment_logs # All logs for every deployment step.
└── deployments # The deployment have to happen in a separate place that is synched afterwards.
    ├── api-gems # Install gems here and symlink them to the defined folder.
    └── api-release # Pull latest changes here and sync them to the app/ folder using RSync.
├── backups # Holds all database backups.
├── db # holds the SQLite database file.
```

The whole folder structure can be created with this script:

```bash
mkdir -p ~/PUNTAPIE/{app,deployment_logs,deployments/{api-gems,api-release},backups,db}
```

## Scripts

First make a manual `git clone` to the repo from the `~/PUNTAPIE/deployments/api-release` folder.


For example:
```
cd PUNTAPIE/deployments/api-release

git clone git@gh:cesc1989/PUNTAPIE.git .
```

To start the deployment, from the `api-release` folder, run the `deploy_api.sh` script. This script will take care of running the rest.

1. deploy_api.sh
2. pull_repo.sh
3. after_deploy.sh
4. application_start.sh
