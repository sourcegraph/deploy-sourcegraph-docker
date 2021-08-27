#!/usr/bin/env bash
set -euf -o pipefail

VOLUME=$1
USER_ID=$2

if [[ "${CI:-"false"}" != "true" ]]; then
  exit 0
fi

if [ ! -d $VOLUME ]; then
    mkdir -p $VOLUME && sudo chown $USER_ID:$USER_ID $VOLUME && sudo chmod 777 $VOLUME
fi
