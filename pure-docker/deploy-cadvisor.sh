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
    # You may set `privileged` to `false and `cadvisor` will run with reduced privileges.
    # `cadvisor` requires root privileges in order to display provisioning metrics.
    # These metrics provide critical information to help you scale the Sourcegraph deployment.
    # If you would like to bring your own infrastructure monitoring & alerting solution,
    # you may want to remove the `cadvisor` container completely 
    --privileged \
    --device=/dev/kmsg \
    index.docker.io/sourcegraph/cadvisor:3.40.0@sha256:c995a7ecb8b6f1cf8a1de4f6c1cb85084761150354bad1fd81c212584010e1f1 \
    --port=8080

echo "Deployed cadvisor"
