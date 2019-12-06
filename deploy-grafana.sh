#!/usr/bin/env bash
set -e

# Description: Dashboards and graphs for Prometheus metrics.
#
# Disk: 100GB / persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: none
# Ports exposed to the public internet: none (HTTP 3000 should be exposed to admins only)
#
docker run --detach \
    --name=grafana \
    --network=sourcegraph \
    --restart=always \
    --cpus=1 \
    --memory=1g \
    -p 0.0.0.0:3370:3370 \
    -v ~/sourcegraph-docker/grafana-disk:/var/lib/grafana \
    -v $(pwd)/grafana/datasources:/sg_config_grafana/provisioning/datasources \
    -v $(pwd)/grafana/dashboards:/sg_grafana_additional_dashboards \
    sourcegraph/grafana:10.0.6@sha256:895a791f7e3580a4bcc6cc4feb4887025a154c7cb25824d94cbd7650159b4fdd

# Add the following lines above if you wish to use an auth proxy with Grafana:
#
# -e GF_AUTH_PROXY_ENABLED=true \
# -e GF_AUTH_PROXY_HEADER_NAME='X-Forwarded-User' \
# -e GF_SERVER_ROOT_URL='https://grafana.example.com' \
