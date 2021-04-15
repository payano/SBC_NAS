#!/bin/bash
echo configuring nfs...
NFS_CONF="/etc/exports"

NFS_CONFIGURED=$(grep data /etc/exports)
if [ ! -z "$NFS_CONFIGURED" ]
then
	echo "already configured..."
	exit 1
fi

echo "/data *(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -ra

