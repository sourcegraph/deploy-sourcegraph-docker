#!/usr/bin/env bash

set -euo pipefail

pushd ..

sg_dump_file=$(mktemp)
codeintel_dump_file=$(mktemp)

trap 'rm -f ${sg_dump_file} ${codeintel_dump_file}' EXIT

# Stop sourcegraph, and only start databases to ensure no writes when dumping
docker-compose down 
docker-compose -f db-only-migrate.docker-compose.yaml up -d

# Dump sourcegraph DB 
echo "Dumping sourcegraph database"
docker exec "pgsql" sh -c 'pg_dump -C --username=sg sg' > "${sg_dump_file}"

# Dump codeintel DB
echo "Dumping codeintel database"
docker exec "codeintel-db" sh -c 'pg_dump -C --username=sg sg' > "${codeintel_dump_file}"



