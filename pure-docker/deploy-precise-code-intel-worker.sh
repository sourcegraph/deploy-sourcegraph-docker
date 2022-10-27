#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Handles conversion of uploaded precise code intelligence bundles.
#
# Ports exposed to other Sourcegraph services: 3188/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=precise-code-intel-worker \
    --network=sourcegraph \
    --restart=always \
    --cpus=2 \
    --memory=4g \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e 'OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317' \
    index.docker.io/sourcegraph/precise-code-intel-worker:4.1.1@sha256:a5d5120ab5097a8469bd0d483429dbe9507d1b9970ad928aa6d9e98e51c7b2f9

echo "Deployed precise-code-intel-worker service"
