#!/usr/bin/env bash
set -e

docker rm -f sourcegraph-frontend-internal &> /dev/null || true
docker rm -f sourcegraph-frontend &> /dev/null || true
docker rm -f github-proxy &> /dev/null || true
docker rm -f gitserver-0 &> /dev/null || true
docker rm -f indexer &> /dev/null || true
docker rm -f pgsql &> /dev/null || true
docker rm -f query-runner &> /dev/null || true
docker rm -f redis-cache &> /dev/null || true
docker rm -f redis-store &> /dev/null || true
docker rm -f repo-updater &> /dev/null || true
docker rm -f searcher-0 &> /dev/null || true
docker rm -f symbols-0 &> /dev/null || true
docker rm -f syntect-server &> /dev/null || true
docker rm -f zoekt-indexserver &> /dev/null || true
docker rm -f zoekt-webserver &> /dev/null || true

docker network rm sourcegraph &> /dev/null || true