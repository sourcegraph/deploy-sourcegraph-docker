#!/usr/bin/env bash
set -e

# Description: Jaeger's Cassandra database for storing traces.
#
# Disk: 128GB / persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 9042/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=jaeger-cassandra \
    --network=sourcegraph \
    --restart=always \
    --cpus=4 \
    --memory=8g \
    -e HEAP_NEWSIZE='1G' \
    -e MAX_HEAP_SIZE='6G' \
    -e CASSANDRA_DC='sourcegraph' \
    -e CASSANDRA_RACK='rack1' \
    -e CASSANDRA_ENDPOINT_SNITCH='GossipingPropertyFileSnitch' \
    -v ~/sourcegraph-docker/jaeger-cassandra-disk/:/var/lib/cassandra \
    cassandra:3.11.4@sha256:9f1d47fd23261c49f226546fe0134e6d4ad0570b7ea3a169c521005cb8369a32

echo "Deployed jaeger-cassandra service"