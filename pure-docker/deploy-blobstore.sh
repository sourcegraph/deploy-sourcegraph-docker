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
    index.docker.io/sourcegraph/blobstore:5.3.0@sha256:7d24918463593dca0190e674f0433abc282cb5d7055ef76df79298d128944075
