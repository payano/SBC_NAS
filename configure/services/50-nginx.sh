#!/bin/bash

sudo cp $(dirname $0)/../files/nextcloud /etc/nginx/sites-available
sudo ln -s /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/nextcloud

sudo systemctl restart nginx

