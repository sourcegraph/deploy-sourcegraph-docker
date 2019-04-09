#!/usr/bin/env bash
set -e

# Description: Receives traces from Jaeger agents.
#
# CPU: 1
# Memory: 1GB
# Disk: none
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 14267/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=jaeger-collector \
    --network=sourcegraph \
    --restart=always \
    -e SPAN_STORAGE_TYPE=cassandra \
    -e CASSANDRA_SERVERS=jaeger-cassandra \
    -e CASSANDRA_KEYSPACE=jaeger_v1_sourcegraph \
    jaegertracing/jaeger-collector:1.11@sha256:0b6d28bb52410f7b50c0f0fc16d7ee391e2e3eca47b713ac88d0891ca8a63cb9

echo "Deployed jaeger-collector service"