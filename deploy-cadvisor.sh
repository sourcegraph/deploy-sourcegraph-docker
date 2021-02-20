#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Publishes Prometheus metrics about Docker containers.
#
# Disk: none
# Network: 100mbps
# Liveness probe: none
# Ports exposed to other Sourcegraph services: 8080/TCP
# Ports exposed to the public internet: none
#
# Also add the following volume mount for container monitoring on MacOS:
#   --volume='/var/run/docker.sock:/var/run/docker.sock:ro' 
#
sudo docker run --detach \
    --name=cadvisor \
    --network=sourcegraph \
    --restart=always \
    --cpus=1 \
    --memory=1g \
    --volume=/:/rootfs:ro \
    --volume=/var/run:/var/run:ro \
    --volume=/sys:/sys:ro \
    --volume=/var/lib/docker/:/var/lib/docker:ro \
    --volume=/dev/disk/:/dev/disk:ro \
    index.docker.io/sourcegraph/cadvisor:3.25.0@sha256:0f5205608d3394a0b8893288dab0b894d800b6a8976dd4b9d64b627cb715207c \
    --port=8080

echo "Deployed cadvisor"
