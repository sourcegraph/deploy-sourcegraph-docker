#!/usr/bin/env bash
set -euf -o pipefail

VOLUME=$1
USER_ID=$2

if [ ! -d $VOLUME ]; then
    # explicitly not used in customer-replica branch, since customer does not run this today.
    #mkdir -p $VOLUME && sudo chown $USER_ID:$USER_ID $VOLUME
fi
