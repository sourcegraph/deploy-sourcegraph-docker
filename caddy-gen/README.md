# Caddy-gen

Example Caddy deployment with docker-gen.

Run with
```
docker build . -t caddy:local
docker network create caddy
docker run -it --network caddy -v /var/run/docker.sock:/tmp/docker.sock:ro -p 8080:80 caddy:local
```

It will round robbin "frontends" which are found by looking at containers with the `src.frontend` label.

Example upstreams:
```
docker run -d --network caddy --label 'src.frontend=true' caddy
docker run -d --network caddy --label 'src.frontend=true' nginx
```

You can also specify a port by setting `--label 'virtual.port=3000'`

## Running standalone

The tool providing the generation is `docker-gen` which can be run in a standalone container to restrict the proxy's access to the docker host. Your `docker-gen` container has access to `docker.socket` and writes to a file in a shared volume and your proxy (or other service) watches that file and automatically reloads.
