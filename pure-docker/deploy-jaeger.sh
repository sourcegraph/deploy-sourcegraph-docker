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
    index.docker.io/sourcegraph/jaeger-all-in-one:3.42.0@sha256:fc33f88b2f55f6bb02149eaa293749f4b82c9db283989b59d88ed80f144688ac \
    --memory.max-traces=20000
