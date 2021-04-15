#!/bin/bash

source $(dirname $0)/../../config/global.sh

sudo docker pull pihole/pihole

# not a good solution...
OLDDIR=$(pwd)
DIR=$(dirname $0)/../../docker_config/pi-hole
CUSTOM_FILE="/data/system/apps/pihole/etc-pihole/custom.list"
cd $DIR
sudo docker-compose pull
sudo docker-compose up -d --remove-orphans
sudo docker image prune -f

while true 
do
	if [ -f "$CUSTOM_FILE" ]
	then
		break
	fi
	sleep 3
done

FQDN_EXIST=$(grep $FQDN $CUSTOM_FILE)

if [ -z "$FQDN_EXIST" ]
then
	echo "$IPADDR $FQDN" | sudo tee -a $CUSTOM_FILE
	sudo docker-compose restart
fi

cd $OLDDIR
