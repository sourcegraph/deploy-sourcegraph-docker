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
# You may remove the --privileged flag to run with reduced privileges.
# `cadvisor` requires root privileges in order to display provisioning metrics.
# These metrics provide critical information to help you scale the Sourcegraph deployment.
# If you would like to bring your own infrastructure monitoring & alerting solution,
# you may want to remove the `cadvisor` container completely
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
    --privileged \
    --device=/dev/kmsg \
    index.docker.io/sourcegraph/cadvisor:4.4.0@sha256:81e3c4af586858220b382a24c82ab45b5bf30295e7e796f34e41ca33a98a3d98 \
    --port=8080

echo "Deployed cadvisor"
