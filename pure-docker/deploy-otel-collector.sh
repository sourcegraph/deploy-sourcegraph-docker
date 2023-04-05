#!/usr/bin/env bash
set -e

# Description: Ingests and exports OpenTelemetry data.
#
# Disk: none
# Ports exposed to other Sourcegraph services: 4317 (receiver), 55679 (zpages)
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=otel-collector \
    --network=sourcegraph \
    --restart=always \
    --cpus="1" \
    --memory=1g \
    -e JAEGER_HOST=jaeger \
    -v $(pwd)/../otel-collector/config.yaml:/etc/otel-collector/config.yaml \
    index.docker.io/sourcegraph/opentelemetry-collector:5.0.1@sha256:1fd0daec77a302cba6c8194c5eb802d1440a4cf329112aceddadb8004d9aa541 \
    --config /etc/otel-collector/configs/logging.yaml
