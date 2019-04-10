#!/usr/bin/env bash
set -e

# Description: Jaeger agent which is local to the host machine (containers on
# the machine send trace information to it and it relays to the collector).
#
# Disk: none
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 5775/UDP 6831/UDP 6832/UDP (on the same host machine)
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=jaeger-agent \
    --network=sourcegraph \
    --restart=always \
    --cpus=1 \
    --memory=1g \
    -e COLLECTOR_HOST_PORT='jaeger-collector:14267' \
    jaegertracing/jaeger-agent@sha256:7ad33c19fd66307f2a3c07c95eb07c335ddce1b487f6b6128faa75d042c496cb
