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
    sourcegraph/prometheus:10.0.3@sha256:7cbd1b00fc79b7575165d36365304ae70072e91410a1ef70d1e9ccc73e33783e
