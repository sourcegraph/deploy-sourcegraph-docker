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
    index.docker.io/sourcegraph/opentelemetry-collector:4.1.2@sha256:342422f9439a7e999125173ff6fee708bfd32e265ba0c4d21af08d12dec816a9 \
    --config /etc/otel-collector/configs/logging.yaml
