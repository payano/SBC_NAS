#!/bin/bash

USERNAME=$1
MIN_PWD_LEN=5
GROUP=nas

usage()
{
	echo -ne "usage is:
$0 <username>
"
}

if [ -z "$USERNAME" ] 
then
	echo "no username provided.."
	usage
	exit 1
fi

EXISTS=$(id $USERNAME 2>/dev/null)
if [ ! -z "$EXISTS" ]
then
	echo "user already exists.."
	exit 1
fi

#check if docker is found...
DOCKER_ID=$(docker ps | awk '{print $1" "$2}' | grep nextcloud | awk '{print $1}')
if [ -z "$DOCKER_ID" ]
then
	echo "nextcloud docker not running..."
	exit 1
fi



echo "Creating user $USERNAME..."
read -sp "Type the user password: " password
echo
read -sp "Type the user password again: " password2
echo

if [ "$password" != "$password2" ]
then
	echo "password mismatch!"
	exit 1

fi

if [ ${#password} -lt $MIN_PWD_LEN ]
then
	echo "Password length must be grater than $MIN_PWD_LEN"
	exit 1
fi

echo "creating system user..."
sudo useradd -g $GROUP -s /bin/bash -d /home/$USERNAME -m $USERNAME -p $(openssl passwd -crypt $password)
echo "creating samba user..."
(echo $password; echo $password)| sudo smbpasswd -a -s $USERNAME
echo "creating nextcloud user..."
sudo /usr/bin/docker exec -e "OC_PASS=$password" -u 33 $DOCKER_ID ./occ user:add --password-from-env $USERNAME


