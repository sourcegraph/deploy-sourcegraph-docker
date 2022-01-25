#!/usr/bin/env bash
set -e

# Description: Jaeger all-in-one instance
# (https://www.jaegertracing.io/docs/1.17/getting-started/#all-in-one) for distributed tracing.
#
# Disk: none
# Ports exposed to other Sourcegraph services: 5778/TCP 6831/UDP 6832/UDP 14250/TCP
# Ports exposed to the public internet: none
# Ports exposed to site admins only: 16686/HTTP
#
docker run --detach \
    --name=jaeger \
    --network=sourcegraph \
    --restart=always \
    --cpus="0.5" \
    --memory=512m \
    -p 0.0.0.0:16686:16686 \
    -p 0.0.0.0:14250:14250 \
    -p 0.0.0.0:5778:5778 \
    -p 0.0.0.0:6831:6831 \
    -p 0.0.0.0:6832:6832 \
    index.docker.io/sourcegraph/jaeger-all-in-one:3.36.2@sha256:e2c0c17dd38a2661b29c29599d151d3c1f75d5ed7e687344821ecff8cf62e17d \
    --memory.max-traces=20000
