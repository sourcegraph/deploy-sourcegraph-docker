#!/usr/bin/env bash
set -e

# Description: Jaeger frontend for querying traces.
#
# CPU: 1
# Memory: 1GB
# Disk: none
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: none
# Ports exposed to the public internet: none (HTTP 16686 should be exposed to admins only)
#
docker run --detach \
    --name=jaeger-query \
    --network=sourcegraph \
    --restart=always \
    -p 0.0.0.0:16686:16686 \
    -e SPAN_STORAGE_TYPE=cassandra \
    -e CASSANDRA_SERVERS=jaeger-cassandra \
    -e CASSANDRA_KEYSPACE=jaeger_v1_sourcegraph \
    -e CASSANDRA_LOCAL_DC=sourcegraph \
    jaegertracing/jaeger-query:1.11@sha256:cddc521d0166c868931282685a863368ae2c14c4de0c1be38e388ece3080439e
