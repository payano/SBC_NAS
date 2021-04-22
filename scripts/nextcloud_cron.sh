#!/bin/bash

DOCKER_ID=$(docker ps | awk '{print $1" "$2}' | grep nextcloud | awk '{print $1}')

echo "starting..." >> /tmp/out.txt
echo $DOCKER_ID >> /tmp/out.txt
RUNNED=$(/usr/bin/docker exec -u 33 $DOCKER_ID ./occ files:scan --all)
echo $RUNNED >> /tmp/out.txt
