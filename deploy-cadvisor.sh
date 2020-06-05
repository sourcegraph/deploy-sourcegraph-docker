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
# See docker-compose.yml for docs on the cAdvisor args used
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
    index.docker.io/sourcegraph/cadvisor:insiders@sha256:4074c8bc608b78af3ca3d6e60b3794369a190ab2efd992e31b3079b075401efa \
    --disable_metrics=percpu,sched,tcp,udp \
    --housekeeping_interval=10s \
    --max_housekeeping_interval=15s \
    --event_storage_event_limit=default=0 \
    --event_storage_age_limit=default=0

echo "Deployed cadvisor"
