#!/bin/bash

#set -x


GROUPNAME="nas"
MOUNTPOINT="/data"
GIT_PATH="${MOUNTPOINT}/admin"
GIT_REPO="https://github.com/payano/SBC_NAS.git"
HOSTNAME="nas"
FQDN="nas.local"
SOURCED_FILE="${GIT_PATH}/config/global.sh"

if [ -f $SOURCED_FILE ]
then
	source $SOURCED_FILE
fi


MODEL=$(tr -d '\0' < /proc/device-tree/model)
DISK_NAME=""

# functions
remove_pkgs()
{
	echo "removing some packages..."
	sudo apt autoremove --purge snapd -y
	sudo apt purge cloud-init -y
	sudo rm -rf /etc/cloud && sudo rm -rf /var/lib/cloud/
}
install_req_pkgs()
{
	echo "installing required packages..."
	sudo apt install -y git curl inotify-tools gcc make
}

get_drives()
{
	#lsblk | grep disk | awk '{print $1}' | while read line


	# Declare a string array
	disks=()
	for i in $(lsblk | grep disk | awk '{print $1}')
	do
		disks+=("$i")
	done

	echo "Found drives:"
	# Iterate the loop to read and print each array element
	i=0
	for value in "${disks[@]}"
	do
	     echo "[$i]: $value"
	     i=$((i+1))
	done

	disks_sz="${#disks[@]}"

	echo -e "which one will you use for the data drive,\nuse the number:"
	read drive_index
	
	re='^[0-9]+$'
	if ! [[ $drive_index =~ $re ]] ; then
	   echo "Not a number, bailing out..." >&2; 
	   exit 1
	fi

	if [[ $drive_index -lt 0 ]] || [[ $drive_index -ge $disks_sz ]]
	then
		echo "Index is wrong, bailing out..."
		exit 1
	fi


	echo "You choose $drive_index = ${disks[$drive_index]}, is that correct?"
	echo "Answer Yes or No"
	read choice
	if [ "$choice" != "Yes" ] 
	then
		echo "Bailing out, answer is not Yes..."
		exit 1
	fi

	DISK_NAME=${disks[$drive_index]}


}

umount_drive()
{
	dev="/dev/$DISK_NAME"
	mountpoints=$(mount | grep $dev | awk '{print $1}')
	if [ -z $mountpoints ] 
	then
		return 0
	fi

	for i in "$mountpoints"
	do
		echo "Unmounting $i"
		sudo umount -f $i
	done
}

wipe_disk()
{
	echo "The $DISK_NAME will be wiped, are you sure?"
	echo "Answer Yes or No"

	read choice
	if [ "$choice" != "Yes" ]
	then
	        echo "Bailing out, answer is not Yes..."
	        exit 1
	fi

	partitions=()
	for i in $(sudo fdisk -l /dev/$DISK_NAME 2>&1 | grep -vE "^Disk" | grep "/dev/" | awk '{print $1}')
	do
		partitions+=("$i")
	done

	echo "Removing partitions..."
	for value in "${partitions[@]}"
	do
		echo "Removing partition: $value"
		NAME=$(echo $value | sed 's/[0-9]*//g')
		NUMBER=$(echo $value | tr -dc '0-9')
		sudo sfdisk --delete $NAME $NUMBER
	done
}

create_partition()
{
	echo "Creating one partition"
	echo 'type=0FC63DAF-8483-4772-8E79-3D69D8477DE4' | sudo sfdisk /dev/${DISK_NAME}
}

create_fs()
{
	echo "Creating Filesystem..."
	sleep 10
	while true
	do
		echo unmounting ${DISK_NAME}1
		sudo umount -f /dev/${DISK_NAME}1
		MOUNTED=$(mount | grep ${DISK_NAME}1)
		if [ -z $MOUNTED ]
		then
			break
		fi
		sleep 3
	done
	sudo mkfs.ext4 -m0 /dev/${DISK_NAME}1
}

create_mountpoint()
{
	echo "Creating mountpoint"
	if [ -d "$MOUNTPOINT" ]
	then
		echo "mountpoint already exists.. bailing out.."
		exit 1
	fi

	sudo mkdir -p $MOUNTPOINT
}

add_group()
{
	echo "adding group $GROUPNAME"
	sudo groupadd $GROUPNAME
	echo "adding user to group..."
	sudo usermod -a -G $GROUPNAME $(whoami)
	sudo usermod -a -G www-data $(whoami)
}

set_mountpoint_acl()
{
	#echo fix this...
	sudo chown root:$GROUPNAME $MOUNTPOINT
	sudo chmod 0775 $MOUNTPOINT
}

update_fstab()
{
	EXISTS=$(grep "$MOUNTPOINT" /etc/fstab)
	if [ ! -z "$EXISTS" ] 
	then
		echo "already exists in fstab.. bailing out..."
		exit 1
	fi

	sleep 10

	UUID=$(sudo lsblk -f | grep ${DISK_NAME}1 | awk '{print $3}')
	echo $UUID
	echo "UUID=$UUID	${MOUNTPOINT}	ext4	defaults,nodiratime,noatime,errors=remount-ro,commit=20	0 1" | sudo tee -a /etc/fstab

	sleep 5 
	sudo umount -f ${DISK_NAME}1

	echo "mounting new drive..."
	while true
	do
		sudo mount ${MOUNTPOINT}
		MOUNTED=$(mount | grep ${DISK_NAME}1)
		if [ ! -z "$MOUNTED" ]
		then
			break
		fi
		sleep 1
	done
	mount
}

get_repo()
{
	echo "Cloning git repo..."
	sudo git clone $GIT_REPO $GIT_PATH
	sudo chown -R $(whoami):$(id -gn) $GIT_PATH
}

update_hostname()
{
	OLD_HOST=$(hostname)
	echo "setting hostname to: $HOSTNAME"
	sudo hostnamectl set-hostname $HOSTNAME
	sudo sed -i "s#${OLD_HOST}#${HOSTNAME}#g" /etc/hosts

}

remove_resolved()
{
	sudo sed -i '/^\[main\]$/a dns=none' /etc/NetworkManager/NetworkManager.conf
	sudo rm /etc/resolv.conf
	echo "search local" | sudo tee /etc/resolv.conf
	echo "nameserver 127.0.0.1" | sudo tee -a /etc/resolv.conf
	echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
	echo "127.0.0.1 $HOSTNAME $FQDN" | sudo tee -a /etc/hosts
	sudo systemctl restart NetworkManager
	sudo systemctl disable systemd-resolved
	sudo systemctl stop systemd-resolved
}

set_network_settings()
{
	OLDDIR=$(pwd)
	cd $GIT_PATH/helpers/network_probe
	make
	./nprobe
	if [ $? -ne 0 ]
	then
		cd $OLDDIR
		exit 1
	fi

	GATEWAY=$(ip -4 route | grep default | awk '{print $3}' | head -1)

	NET_SETTINGS=$(cat ./settings.txt)
	NET_SETTINGS+=" GATEWAY=\"$GATEWAY\""
	rm settings.txt
	cd $OLDDIR

	for i in ${NET_SETTINGS}
	do
		parse=$(echo $i | sed 's/=/ /g' | awk '{print $1}')
		exists=$(grep $parse ${GIT_PATH}/config/global.sh)
		if [ ! -z $exists ]
		then
			echo $exists already exists..
			continue
		fi

		echo $i | sudo tee -a $SOURCED_FILE
	done


	# SET THE NETWORK SETTINGS HERE!!!!
	source $SOURCED_FILE
	
	NETPLAN_FILE="/etc/netplan/01-netcfg.yaml"
	sudo cp ${GIT_PATH}/install/files/01-netcfg.yaml /etc/netplan/
	sudo sed -i "s#ddd#${INTERFACE}#g" $NETPLAN_FILE
	sudo sed -i "s#aaa.aaa.aaa.aaa#${IPADDR}#g" $NETPLAN_FILE
	sudo sed -i "s#bb#${NET_BITS}#g" $NETPLAN_FILE
	sudo sed -i "s#ccc.ccc.ccc.ccc#${GATEWAY}#g" $NETPLAN_FILE


}

prepare_reboot()
{
	#update .profile, will get deleted later..
	echo "$GIT_PATH/install/post_install.sh" >> ~/.profile
}

restart_system()
{
	echo "rebooting system in 10 seconds..."
	echo "after the reboot login to the new ip: ${IPADDR}"
	sleep 10
	sudo reboot
}


#main
remove_pkgs
install_req_pkgs
get_drives
umount_drive
wipe_disk
create_partition
create_fs
create_mountpoint
add_group
set_mountpoint_acl
update_fstab
get_repo
update_hostname
remove_resolved
set_network_settings
prepare_reboot
restart_system

