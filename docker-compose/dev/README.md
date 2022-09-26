# Development overlay

For use developing Sourcegraph's docker-compose deployment only.
For deployments, refer to the official [Sourcegraph with Docker Compose](https://docs.sourcegraph.com/admin/install/docker-compose) documentation.

This folder includes a helper script, [run.sh](./run.sh), that will run the `docker` command (with any provided arguments) while automatically specifying the appropriate set of overlays.

Example usage:

```sh
./run.sh up -d 
```

The above will deploy Sourcegraph on [http://localhost:8080](http://localhost:8080) with the indicated overlays.

```sh
./run.sh down
```

The above will tear down the local Sourcegraph instance that was set up using the previous command.
