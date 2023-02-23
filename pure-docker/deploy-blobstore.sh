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
    index.docker.io/sourcegraph/blobstore:4.5.0@sha256:c698fc450e913c78f0dba798013efe02d2bb6abcb481b1679d9b0f1b68bdb120
