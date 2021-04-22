#!/bin/bash

source $(dirname $0)/../config/global.sh

WATCH_DIR="${MOUNTPOINT}/files"


inotifywait -q -r -m -e create $WATCH_DIR |
while read -r dir event file; do
	if [ -f "${dir}${file}" ]
	then
		chown www-data:www-data ${dir}${file}
		chmod 0664 ${dir}${file}
	elif [ -d "${dir}${file}" ]
	then
		chown www-data:www-data ${dir}${file}
		chmod 0775 ${dir}${file}
	fi
done
