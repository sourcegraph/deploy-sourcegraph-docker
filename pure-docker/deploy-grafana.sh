#!/usr/bin/env bash
set -e

# Description: Dashboards and graphs for Prometheus metrics.
#
# Disk: 2GB / persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: none
# Ports exposed to the public internet: none (HTTP 3000 should be exposed to admins only)
#
VOLUME="$HOME/sourcegraph-docker/grafana-disk"
./ensure-volume.sh $VOLUME 472
docker run --detach \
    --name=grafana \
    --network=sourcegraph \
    --restart=always \
    --cpus=1 \
    --memory=1g \
    -v $VOLUME:/var/lib/grafana \
    -v $(pwd)/../grafana/datasources:/sg_config_grafana/provisioning/datasources \
    -v $(pwd)/../grafana/dashboards:/sg_grafana_additional_dashboards \
    index.docker.io/sourcegraph/grafana:187572_2022-12-06_cbecc5321c7d@sha256:cf295a1dada50607a364390a54744dbc9142aa99b42c07f1bb623ca251639d2c

# Add the following lines above if you wish to use an auth proxy with Grafana:
#
# -e GF_AUTH_PROXY_ENABLED=true \
# -e GF_AUTH_PROXY_HEADER_NAME='X-Forwarded-User' \
# -e GF_SERVER_ROOT_URL='https://grafana.example.com' \
