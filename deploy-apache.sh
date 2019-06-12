#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Some customers use an Apache load balancer to round-robin
# requests. This mimicks that.
docker run --detach \
    --name=apache \
    --network=sourcegraph \
    --restart=always \
    --cpus=4 \
    --memory=4g \
    -v $(pwd)/apache/conf/httpd.conf:/usr/local/apache2/conf/httpd.conf \
    -p 0.0.0.0:80:80 \
    httpd:2.4

echo "Deployed apache"
