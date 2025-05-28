#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: High level syntax analysis
#
# Ports exposed to other Sourcegraph services: 3288/TCP
# Ports exposed to the public internet: none
#
# NOTE: Keep in sync with https://github.com/sourcegraph/deploy-sourcegraph-docker/blob/main/docker-compose/docker-compose.yaml#L372
#
docker run --detach \
    --name=syntactic-code-intel-worker \
    --network=sourcegraph \
    --restart=always \
    --cpus=2 \
    --memory=4g \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e PRECISE_CODE_INTEL_UPLOAD_BACKEND=blobstore \
    -e PRECISE_CODE_INTEL_UPLOAD_AWS_ENDPOINT=http://blobstore:9000 \
    -e 'OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317' \
    -e 'SYNTACTIC_CODE_INTEL_WORKER_ADDR=:3288' \
    index.docker.io/sourcegraph/syntactic-code-intel-worker:6.1.1295@sha256:c6e2b097b8f16394e339588e208c43587f1fa6a35cb44e9759622c448ddc1445

echo "Deployed syntactic-code-intel-worker service"
