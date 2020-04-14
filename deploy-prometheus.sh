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
docker run --detach \
    --name=prometheus \
    --network=sourcegraph \
    --restart=always \
    --cpus=4 \
    --memory=8g \
    -p 0.0.0.0:9090:9090 \
    -v ~/sourcegraph-docker/prometheus-v2-disk:/prometheus \
    -v $(pwd)/prometheus:/sg_prometheus_add_ons \
    index.docker.io/sourcegraph/prometheus:insiders@sha256:6ee6e6bf73a85cfa0231c554f79c343e7c643ac6f24358ad16cd3815d758432d
