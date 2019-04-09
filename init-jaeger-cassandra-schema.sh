#!/usr/bin/env bash
set -e

# Description: Initializes Jaeger's Cassandra database. Only needs to run once.
# Does not run persistently (exits after doing its work).
#
docker run --detach \
    --name=jaeger-cassandra-schema \
    --network=sourcegraph \
    -e CQLSH_HOST='jaeger-cassandra' \
    -e DATACENTER='sourcegraph' \
    -e KEYSPACE='jaeger_v1_sourcegraph' \
    -e MODE='prod' \
    jaegertracing/jaeger-cassandra-schema@sha256:ba0ffb1953c76705539360c2f83eafe32b977529c3399d1abeb69c94f29c45d0

echo "Deployed jaeger-cassandra-schema initializer"
