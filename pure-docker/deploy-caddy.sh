#!/usr/bin/env bash
set -e

  # Description: Acts as a reverse proxy for all of the sourcegraph-frontend instances
  #
  # Disk: 1GB / persistent SSD
  # Ports exposed to other Sourcegraph services: none
  # Ports exposed to the public internet: 80 (HTTP) and 443 (HTTPS)
  #
  # Sourcegraph ships with a few builtin templates that cover common HTTP/HTTPS configurations:
  # - HTTP only (default)
  # - HTTPS with Let's Encrypt
  # - HTTPS with custom certificates
  #
  # Follow the directions in the comments below to swap between these configurations.
  #
  # If none of these built-in configurations suit your needs, then you can create your own Caddyfile, see:
  # https://caddyserver.com/docs/caddyfile

VOLUME="$HOME/sourcegraph-docker/caddy-storage"
./ensure-volume.sh $VOLUME 100
docker run --detach \
    --name=caddy \
    --network=sourcegraph \
    --restart=always \
    --cpus="4" \
    --memory=4g \
    -e XDG_DATA_HOME="/caddy-storage/data" \
    -e XDG_CONFIG_HOME="/caddy-storage/config" \
    -e SRC_FRONTEND_ADDRESSES="sourcegraph-frontend-0:3080" \
    -p 0.0.0.0:80:80 \
    -p 0.0.0.0:443:443 \
    -v $VOLUME:/caddy-storage \
    --mount type=bind,source="$(pwd)"/../caddy/builtins/http.Caddyfile,target=/etc/caddy/Caddyfile \
<<<<<<< HEAD:deploy-caddy.sh
    index.docker.io/caddy/caddy:alpine@sha256:83d9aa7a5f1bbcc0fc1b4720c183a5ec53dae7dc5d9fa555daf3db345010e7f9
=======
    index.docker.io/caddy/caddy:alpine@sha256:ef2f47730caa12cb7d0ba944c048b8e48f029d5e0ff861840fa2b8f1868e1966
>>>>>>> master:pure-docker/deploy-caddy.sh

