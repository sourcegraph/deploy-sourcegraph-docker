#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -euxo pipefail

/usr/bin/vagrant box add ../../sg-buildkite.box --name sg-buildkite
/usr/bin/vagrant
# ./smoke-test.sh
/usr/bin/vagrant destroy -f
