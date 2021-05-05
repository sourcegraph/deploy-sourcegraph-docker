#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/../.."
set -euxo pipefail

ROOT="$(pwd)"
cd .buildkite/verify-release

echo "--- Check to see if semver tag are set in release branch"
go run verify-release.go -verbose=true "${ROOT}"
