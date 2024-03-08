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
    index.docker.io/sourcegraph/opentelemetry-collector:5.3.2@sha256:6868dbd6b9d81e45c5825b1496808efd1c2f87deec18685b73f4fea25daee757 \
    --config /etc/otel-collector/configs/logging.yaml
