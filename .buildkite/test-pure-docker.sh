#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -euxo pipefail

vagrant up
# ./smoke-test.sh
vagrant destroy -f
