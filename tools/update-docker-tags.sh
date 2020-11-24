#!/bin/bash

CONSTRAINT=$1

# Using `go run` ensures we are using the version of `update-docker-tags` pinned in `go.mod`
go run github.com/slimsag/update-docker-tags \
  -enforce="sourcegraph/cadvisor=$CONSTRAINT" \
  -enforce="sourcegraph/frontend=$CONSTRAINT" \
  -enforce="sourcegraph/jaeger-agent=$CONSTRAINT" \
  -enforce="sourcegraph/github-proxy=$CONSTRAINT" \
  -enforce="sourcegraph/gitserver=$CONSTRAINT" \
  -enforce="sourcegraph/grafana=$CONSTRAINT" \
  -enforce="sourcegraph/indexed-searcher=$CONSTRAINT" \
  -enforce="sourcegraph/search-indexer=$CONSTRAINT" \
  -enforce="sourcegraph/jaeger-all-in-one=$CONSTRAINT" \
  -enforce="sourcegraph/postgres-11.4=$CONSTRAINT" \
  -enforce="sourcegraph/precise-code-intel-worker=$CONSTRAINT" \
  -enforce="sourcegraph/codeintel-db=$CONSTRAINT" \
  -enforce="sourcegraph/syntax-highlighter=$CONSTRAINT" \
  -enforce="sourcegraph/prometheus=$CONSTRAINT" \
  -enforce="sourcegraph/query-runner=$CONSTRAINT" \
  -enforce="sourcegraph/redis-cache=$CONSTRAINT" \
  -enforce="sourcegraph/redis-store=$CONSTRAINT" \
  -enforce="sourcegraph/repo-updater=$CONSTRAINT" \
  -enforce="sourcegraph/searcher=$CONSTRAINT" \
  -enforce="sourcegraph/symbols=$CONSTRAINT" \
  -enforce="sourcegraph/minio=$CONSTRAINT" \
  ./
