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
    --cpus="0.5" \
    --memory=512m \
    index.docker.io/sourcegraph/opentelemetry-collector:169257_2022-08-25_bb67d3645e59@sha256:a10375336bc505767533b1ec2d32c319e379365e5d6809c1d1dcab1b7fb4798f \
    -e JAEGER_HOST=jaeger \
    --config /etc/otel-collector/configs/jaeger.yaml
