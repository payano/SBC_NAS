#!/bin/bash

source $(dirname $0)/../config/global.sh

fix_route()
{
	sudo ip route del default
	sudo ip route add default via $GATEWAY dev $INTERFACE
}

remove_autostart()
{
#	LINE=$(grep -n $0 ~/.profile | sed 's/:/ /g' | awk '{print $1}')
#	sed -i "${LINE}"'d' ~/.profile
	sed -i "s#$0##g" ~/.profile
}

remove_nohup()
{
	sudo rm $(dirname $0)/../nohup.out
}

update_motd()
{
	echo -ne '
Theses commands will modify account settings:
nas-adduser          # Create a new user
nas-deluser          # Delete a user
nas-passwd           # Change password for a user
nas-create-root-dir  # Create a new directory under /data
nas-remove-root-dir  # Remove ad direcotyr under /data
nas-update           # Update the system
' | sudo tee /etc/motd

}

install_systemctl()
{
	# this is a hack...
	if [ ! -f "lib/systemd/system/inotifywatcher.service" ]
	then
		sudo cp -rp $(dirname $0)/files/*.service /lib/systemd/system
		sudo chmod 0664 /lib/systemd/system/inotifywatcher.service
		sudo ln -s /lib/systemd/system/inotifywatcher.service /etc/systemd/system/
		sudo systemctl enable inotifywatcher.service
		sudo systemctl start inotifywatcher.service
	fi
}

install_bins()
{
	sudo ln -s /data/admin/bin/* /usr/local/bin
}

create_files_dir()
{
	DATA_DIR="/data/files"
	if [ ! -d $DATA_DIR ]
	then
		sudo mkdir -p $DATA_DIR
	fi
	sudo chown www-data:www-data $DATA_DIR
	sudo chmod 0775 $DATA_DIR

}
#main
fix_route
create_files_dir
remove_autostart
update_motd
install_systemctl
install_bins

$(dirname $0)/install_services.sh

$(dirname $0)/../configure/start.sh

$(dirname $0)/../docker_install/start.sh

create_files_dir



echo -ne "
############################
#
# CONGRATULATIONS!!!
# IF EVERYTHING WENT OK, YOU NEED TO UPDATE THE 
# DNS SETTINGS ON YOUR ROUTER, THE FIRST DNS SERVER
# MUST BE POINTING TO THIS COMPUTER, WHICH IS
# IP ADDRESS $IPADDR
# GET THE MODEL NAME OF YOUR ROUTER AND SEARCH ON
# INTERNET TO SEE WHO YOU CAN CHANGE THE DNS SETTINGS
# FOR YOUR CLIENTS ON YOUR NETWORK.
#
"

sudo mkdir -p /var/www/html/
echo -ne "
<html>
<head>
<title> welcome to nas</title>
</head>
<body>
nextcloud: <a href="https://$FQDN">Nextcloud link</a></br>
pi-hole: <a href="http://$IPADDR:81">Pi-hole link</a></br></br>
Certs:</br>
Root ca public cert: <a href="./ca.crt">ca</a></br>
Nas public cert: <a href="./nas.crt">nas</a></br>
</body>
</html>
" | sudo tee /var/www/html/index.htm
