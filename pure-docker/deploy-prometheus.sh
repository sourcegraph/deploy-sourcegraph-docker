#!/usr/bin/env bash
set -e

# Description: Prometheus collects metrics and aggregates them into graphs.
#
# Disk: 200GB / persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: none
# Ports exposed to the public internet: none (HTTP 9090 should be exposed to admins only)
#
VOLUME="$HOME/sourcegraph-docker/prometheus-v2-disk"
./ensure-volume.sh $VOLUME 100
docker run --detach \
    --name=prometheus \
    --network=sourcegraph \
    --restart=always \
    --cpus=4 \
    --memory=8g \
    -p 0.0.0.0:9090:9090 \
    -v $VOLUME:/prometheus \
    -v $(pwd)/../prometheus:/sg_prometheus_add_ons \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    index.docker.io/sourcegraph/prometheus:4.5.0@sha256:4fe9a5fdee206b1aac9d32afb31ad57e1882394aad9e7e9f719a1b2741afcae5
