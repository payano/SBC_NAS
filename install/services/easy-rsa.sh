echo installing easy-rsa

sudo apt install -y easy-rsa openssl

exit 0

OLDDIR=$(pwd)

echo "user $(whoami) will have the root ca..."

mkdir ~/easy-rsa
ln -s /usr/share/easy-rsa/* ~/easy-rsa/
chmod 700 ~/easy-rsa
cd ~/easy-rsa
./easyrsa init-pki
cd ~/easy-rsa

echo -e 'set_var EASYRSA_REQ_COUNTRY    "SE"
set_var EASYRSA_REQ_PROVINCE   "Stockholm"
set_var EASYRSA_REQ_CITY       "Stockholm"
set_var EASYRSA_REQ_ORG        "nas-server"
set_var EASYRSA_REQ_EMAIL      "admin@example.com"
set_var EASYRSA_REQ_OU         "Community"
set_var EASYRSA_ALGO           "ec"
set_var EASYRSA_DIGEST         "sha512"' > vars

echo | ./easyrsa build-ca nopass

cd $OLDDIR

exit 0

#cert for nextcloud
mkdir ~/csr
cd ~/csr
openssl genrsa -out nextcloud.local.key

openssl req -new -key nextcloud.local.key -out nextcloud.local.req -subj \
/C=SE/ST=Stockholm/L=Stockholm/O=nas-server/OU=Community/CN=nextcloud.local

cd ~/easy-rsa
./easyrsa import-req ../csr/nextcloud.local.req nextcloud

echo yes | ./easyrsa sign-req server nextcloud



cd $OLDDIR

