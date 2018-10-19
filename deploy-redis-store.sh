#!/usr/bin/env bash
set -e

# Description: Redis for storing semi-persistent data like user sessions.
#
# CPU: 1
# Memory: 6GB
# Disk: 128GB / persistent SSD
# Network: 100mbps
# Liveness probe: 6379/TCP
# Ports exposed to other Sourcegraph services: 6379/TCP
# Ports exposed to the public internet: none
#
docker create \
    --name=redis-store \
    --network=sourcegraph \
    -v ~/sourcegraph-docker/redis-store-disk:/redis-data \
    sourcegraph/redis:18-02-07_8205764_3.2-alpine@sha256:f2957e0973ef16968d4bfacfae5ab08da985257aa7ce358a85152275e3da78e8 \
    redis-server /etc/redis/redis.conf # command

# Create /etc/redis/redis.conf
docker cp ./redis-store/redis redis-store:/etc/

docker start redis-store
echo "Deployed redis-store service"