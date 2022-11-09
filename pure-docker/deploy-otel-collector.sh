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
    index.docker.io/sourcegraph/opentelemetry-collector:4.1.3@sha256:461b0e829f6575a593bd07b4597d71c297fff2b57efb5ef5831572b9713ef4d7 \
    --config /etc/otel-collector/configs/logging.yaml
