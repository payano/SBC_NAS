#!/bin/bash

sudo apt update
sudo apt upgrade -y
sudo /data/admin/docker_install/start.sh

OLDPWD=$(pwd)
echo "updating admin..."
cd /data/admin
mkdir backup
cp ./config/global.sh backup
git checkout ./config/global.sh
git pull
mv backup/global.sh config/global.sh

cd $OLDPWD

echo "Update complete..."
read -p "Do you want to reboot? [N/y]: " reboot

if [ "$reboot" == "y" ] || [ "$reboot" == "Y" ]
then
	sudo reboot
fi

