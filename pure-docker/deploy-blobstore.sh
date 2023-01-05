#!/usr/bin/env bash
set -e

# Description: generic S3-like blobstore for storing LSIF uploads.
#
# Disk: 128GB / persistent SSD
# Network: 1Gbps
# Liveness probe: HTTP GET http://blobstore:9000/
# Ports exposed to other Sourcegraph services: 9000/TCP
# Ports exposed to public internet: none
#
VOLUME="$HOME/sourcegraph-docker/blobstore-disk"
./ensure-volume.sh $VOLUME 100
docker run --detach \
    --name=blobstore \
    --network=sourcegraph \
    --restart=always \
    --cpus=1 \
    --memory=1g \
    -p 0.0.0.0:9000:9000 \
    -v $VOLUME:/data \
    index.docker.io/sourcegraph/blobstore:4.3.1@sha256:bdb5bb31391eb47a44c6222cc4665413de114176bba784fd54f2997e1935e91e
