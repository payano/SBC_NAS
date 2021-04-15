#!/bin/bash

DOCKER_CONF="/etc/docker/daemon.json"
DOCKER_DIR="/data/system/docker"

sudo mkdir -p /data/files

echo "adding this user to docker group..."
sudo usermod -a -G docker $(whoami)

#sudo docker network create --subnet 192.168.254.0/24 dockernet
# dont change the docker installation path...
exit 0

echo configuring docker
sudo mkdir -p /data/system/docker

if [ -f $DOCKER_CONF ]
then
	exit 1
fi

echo "{" | sudo tee -a $DOCKER_CONF
echo '  "graph":"/data/docker"' | sudo tee -a $DOCKER_CONF
echo "}" | sudo tee -a $DOCKER_CONF

echo "adding this user to docker group..."
sudo usermod -a -G docker $(whoami)

sudo systemctl restart docker
