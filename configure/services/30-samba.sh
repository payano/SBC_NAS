#!/bin/bash
echo configuring samba...
SMB_CONF="/etc/samba/smb.conf"

SMB_CONFIGURED=$(grep "\[data\]" $SMB_CONF)

if [ ! -z "$SMB_CONFIGURED" ]
then
	echo "already configured..."
	exit 1
fi

DATA_SHARE="[data]\n
   comment = Data\n
   browseable = yes\n
   path = /data\n
   printable = no\n
   guest ok = no\n
   create mask = 0775\n
   directory mask = 0775\n
   writable = yes\n"

echo -e $DATA_SHARE | sudo tee -a /etc/samba/smb.conf

sudo systemctl restart smbd
sudo systemctl restart nmbd
