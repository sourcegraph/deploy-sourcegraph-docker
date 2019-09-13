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
    -e GF_AUTH_ANONYMOUS_ENABLED=true \
    -e GF_AUTH_ANONYMOUS_ORG_NAME='Main Org.' \
    -e GF_AUTH_ANONYMOUS_ORG_ROLE=Editor \
    -e GF_USERS_ALLOW_SIGN_UP='false' \
    -e GF_USERS_AUTO_ASSIGN_ORG='true' \
    -e GF_USERS_AUTO_ASSIGN_ORG_ROLE=Editor \
    sourcegraph/grafana:6.3.3-1@sha256:bbfa5565f3755ac961c8560e94c323cc588fc241364c4c6839376ccdb7c756db

# Add the following lines above if you wish to use an auth proxy with Grafana:
#
# -e GF_AUTH_PROXY_ENABLED=true \
# -e GF_AUTH_PROXY_HEADER_NAME='X-Forwarded-User' \
# -e GF_SERVER_ROOT_URL='https://grafana.example.com' \
