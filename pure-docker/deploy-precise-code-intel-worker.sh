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
    -e PRECISE_CODE_INTEL_UPLOAD_BACKEND=blobstore \
    -e PRECISE_CODE_INTEL_UPLOAD_AWS_ENDPOINT=http://blobstore:9000 \
    index.docker.io/sourcegraph/precise-code-intel-worker:5.1.1@sha256:32f1e8d7e058c642af452578e81df5f1324ec5763fbe8750430a89c5b18e931b

echo "Deployed precise-code-intel-worker service"
