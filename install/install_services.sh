#!/bin/bash

# starting configure

echo "starting to install services..."

for i in $(ls $(dirname $0)/services)
do
	echo "running $i..."
	$(dirname $0)/services/$i
done

