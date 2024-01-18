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
    us-central1-docker.pkg.dev/sourcegraph-ci/rfc795-internal/opentelemetry-collector:5.3.666@sha256:918f2299cbfb23588e761844c9a99328c8dffdfca943166f6d94e2a285d9c18d \
    --config /etc/otel-collector/configs/logging.yaml
