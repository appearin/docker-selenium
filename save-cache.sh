#!/bin/bash

set -e

AUTHORS=$1
VERSION=$2
PREFIX=$3

shift;
shift;
shift;

for IMAGE in "$@"; do docker history -q $AUTHORS/selenium-node-$IMAGE:$VERSION; done | grep -v '<missing>' | sort | uniq \
  > docker-cache/$PREFIX-cache-layers

ID=$(sha1sum docker-cache/$PREFIX-cache-layers | cut -d' ' -f1)
CACHE=docker-cache/$PREFIX-cache-$ID.tar.gz
test -f "$CACHE" && exit 0

echo "Recreating cache... $CACHE"
rm -f docker-cache/$PREFIX-cache*.tar.gz
docker save $(cat docker-cache/$PREFIX-cache-layers) | gzip -1 > $CACHE
