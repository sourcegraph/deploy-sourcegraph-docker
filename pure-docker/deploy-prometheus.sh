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
    us.gcr.io/sourcegraph-dev/prometheus@sha256:33908e4d62102f4fb488f910861a4710c6426e7c95e2cb4b0d8c5b43a12e5abd

# index.docker.io/sourcegraph/prometheus:5.0.6@sha256:08fd31f6ba5289ac9468c2e456d4cad6076889195f4c23722273ec1d80a2f317

