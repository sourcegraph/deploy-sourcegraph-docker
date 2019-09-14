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
    -p 0.0.0.0:3000:3000 \
    -v ~/sourcegraph-docker/grafana-disk:/var/lib/grafana \
    -v $(pwd)/grafana:/sg_config_grafana/provisioning/datasources \
    sourcegraph/grafana:6.3.3-2@sha256:4bc97accb0c0b08ab48294ff6b94def09414e2b01dc90f8747a667213d91343b

# Add the following lines above if you wish to use an auth proxy with Grafana:
#
# -e GF_AUTH_PROXY_ENABLED=true \
# -e GF_AUTH_PROXY_HEADER_NAME='X-Forwarded-User' \
# -e GF_SERVER_ROOT_URL='https://grafana.example.com' \
