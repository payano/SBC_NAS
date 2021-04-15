#!/bin/bash
set -x
inotifywait -r -q -m -e CREATE /data/files |
while read -r directory mask filename; do
	/tmp/test.sh $directory$filename         # or "./$filename"
done
