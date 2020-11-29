#!/bin/bash

set -e

root_dir="$(dirname "${BASH_SOURCE[0]}")/.."
cd "$root_dir"

CONSTRAINT=$1

go run ./tools/enforce-tags "$CONSTRAINT" base/
