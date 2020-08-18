#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -euxo pipefail

pwd && ls -l
vagrant up
# ./smoke-test.sh
vagrant destroy -f
