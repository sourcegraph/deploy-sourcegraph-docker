# Development overlay

For use developing Sourcegraph's docker-compose deployment only.
For deployments, refer to the official [Sourcegraph with Docker Compose](https://docs.sourcegraph.com/admin/install/docker-compose) documentation.

Example usage:

```sh
docker-compose \
    -f docker-compose/docker-compose.yaml \
    -f docker-compose/jaeger/docker-compose.yaml \
    -f docker-compose/dev/docker-compose.yaml up
```

The above will deploy Sourcegraph on [http://localhost:8080](http://localhost:8080) with the indicated overlays.
