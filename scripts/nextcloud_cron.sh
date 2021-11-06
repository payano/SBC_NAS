#!/bin/bash

DOCKER_ID=$(docker ps | awk '{print $1" "$2}' | grep nextcloud | awk '{print $1}')

echo "starting..." > /tmp/out.txt
echo $DOCKER_ID > /tmp/out.txt
RUNNED=$(/usr/bin/docker exec -u 33 $DOCKER_ID ./occ files:scan --all)
if [ $? -ne 0 ]
then
	echo "couldn't execute the docker scan files"
fi

RUNNED=$(/usr/bin/docker exec -u 33 $DOCKER_ID php ./cron.php)
if [ $? -ne 0 ]
then
	echo "couldn't execute the docker cron files"
fi


