#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Publishes Prometheus metrics about the machine's hardware / operating system.
#
# Disk: none
# Ports exposed to other Sourcegraph services: 9100/TCP
# Ports exposed to the public internet: none
#
sudo docker run --detach \
    --name=node-exporter \
    --network=sourcegraph \
    --restart=always \
    --cpus=0.5 \
    --memory=1g \
    --pid='host' \
    --volume=/:/rootfs:ro \
    --volume=/proc:/host/proc:ro \
    --volume=/sys:/host/sys:ro \
    -p 0.0.0.0:9100:9100 \
    index.docker.io/sourcegraph/node-exporter:5.1.1@sha256:8e9030b5c86269e523bcf0be6d1dc7ab38fc3f52f3a1b09c1092bd272e2fdeed \
    '--path.procfs=/host/proc' \
    '--path.rootfs=/rootfs' \
    '--path.sysfs=/host/sys' \
    '--no-collector.wifi' \
    '--no-collector.hwmon' \
    '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'

echo "Deployed node-exporter"
