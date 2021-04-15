#!/bin/bash

source $(dirname $0)/../../config/global.sh
OLDDIR=$(pwd)

echo "user $(whoami) will have the root ca..."
export EASYRSA_CERT_EXPIRE=10000

mkdir ~/easy-rsa
ln -s /usr/share/easy-rsa/* ~/easy-rsa/
chmod 700 ~/easy-rsa
cd ~/easy-rsa
./easyrsa init-pki
cd ~/easy-rsa

echo -e 'set_var EASYRSA_REQ_COUNTRY    "SE"
set_var EASYRSA_REQ_PROVINCE   "Stockholm"
set_var EASYRSA_REQ_CITY       "Stockholm"
set_var EASYRSA_REQ_ORG        "nas"
set_var EASYRSA_REQ_EMAIL      "admin@example.com"
set_var EASYRSA_REQ_OU         "Community"
set_var EASYRSA_ALGO           "ec"
set_var EASYRSA_DIGEST         "sha512"' > vars

echo | ./easyrsa build-ca nopass


#cert for nextcloud
mkdir ~/csr
cd ~/csr
openssl genrsa -out ${FQDN}.key

openssl req -new -key ${FQDN}.key -out ${FQDN}.req -subj \
/C=SE/ST=Stockholm/L=Stockholm/O=nas-server/OU=Community/CN=${FQDN}

cd ~/easy-rsa
./easyrsa import-req ../csr/${FQDN}.req ${HOSTNAME}

echo yes | ./easyrsa sign-req server ${HOSTNAME}

sudo mkdir -p ${CERTDIR}
sudo cp ~/csr/${FQDN}.key ~/easy-rsa/pki/issued/${HOSTNAME}.crt ${CERTDIR}

sudo cp ~/easy-rsa/pki/issued/${HOSTNAME}.crt ~/easy-rsa/pki/ca.crt /var/www/html/
sudo chmod 0655 /var/www/html/*.crt

cd $OLDDIR

