#!/bin/bash
# starting configure

echo "starting to configure containers..."

for i in $(ls $(dirname $0)/containers)
do
	echo "running $i..."
	$(dirname $0)/containers/$i
done
