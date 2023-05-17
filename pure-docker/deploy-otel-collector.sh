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
    index.docker.io/sourcegraph/opentelemetry-collector:5.0.4@sha256:6744dad44fa845a17be6cb1867baee81b476349ec04f2434fbaf318212fe4de2 \
    --config /etc/otel-collector/configs/logging.yaml
