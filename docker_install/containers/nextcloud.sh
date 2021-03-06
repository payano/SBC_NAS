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

ACL_SET=$(ls -la /data/ | grep files | grep -oE "root")

if [ ! -z "$ACL_SET" ]
then
	echo setting acl...
	sudo chown -R www-data:www-data /data/files
	sudo find /data/files -type f -exec chmod 0664 {} \;
	sudo find /data/files -type d -exec chmod 0775 {} \;
fi

#create cronjob
FILE_EXISTS=$(sudo grep nextcloud_cron.sh /etc/crontab)
if [ -z "$FILE_EXISTS" ]
then
	echo "*  */12 *  *  *	root	/data/admin/scripts/nextcloud_cron.sh" | sudo tee -a /etc/crontab
	sudo systemctl restart cron
fi

