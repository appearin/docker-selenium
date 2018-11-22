#!/bin/bash

set -e

PREFIX=$1

test -r docker-cache/$PREFIX-cache-layers || exit 0

# Exit if none of the cached layers are missing from local history
comm -13 <(docker image ls -a -q | sort) docker-cache/$PREFIX-cache-layers | grep -q '' || exit 0

zcat docker-cache/$PREFIX-cache-*.tar.gz | docker load
