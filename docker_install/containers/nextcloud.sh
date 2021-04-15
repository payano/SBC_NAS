#!/bin/bash

sudo docker pull nextcloud

# not a good solution...
OLDDIR=$(pwd)
DIR=$(dirname $0)/../../docker_config/nextcloud

cd $DIR
sudo docker-compose pull
sudo docker-compose up -d --remove-orphans
sudo docker image prune -f

cd $OLDDIR
