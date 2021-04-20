#!/usr/bin/env bash
set -e

# Description: MinIO for storing LSIF uploads.
#
# Disk: 128GB / persistent SSD
# Network: 1Gbps
# Liveness probe: HTTP GET http://minio:9000/minio/health/live
# Ports exposed to other Sourcegraph services: 9000/TCP
# Ports exposed to public internet: none
#
VOLUME="$HOME/sourcegraph-docker/minio-disk"
./ensure-volume.sh $VOLUME 100
docker run --detach \
    --name=minio \
    --network=sourcegraph \
    --restart=always \
    --cpus=1 \
    --memory=1g \
    -p 0.0.0.0:9000:9000 \
    -v $VOLUME:/data \
    -e MINIO_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE \
    -e MINIO_SECRET_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY \
    index.docker.io/sourcegraph/minio:3.27.0@sha256:e534fd638ee25fb730bd53cd4633b28e4d8f8383580857e3bb45ad36f64929fe \
    server /data
