# Sourcegraph for docker-compose

This folder contains a Sourcegraph docker-compose deployment.

## Deploying

Simply clone the repository and `docker-compose up -d` to deploy Sourcegraph:

```sh
git clone https://github.com/sourcegraph/deploy-sourcegraph-docker
cd deploy-sourcegraph-docker/docker-compose/
git checkout v3.17.2
docker-compose up -d
```

Sourcegraph will then run in the background and across server restarts.

Notes:

- The `docker-compose.yaml` file currently depends on configuration files which live in the repository, as such you must have the repository cloned onto your server.
- Data for all services will be stored as docker volumes.
- Use `docker ps` to inspect the Sourcegraph containers, and `docker-compose down` to teardown the deployment.

## Upgrading

Always refer to https://docs.sourcegraph.com/admin/updates/docker_compose prior to upgrading, as it will document any manual steps you may need to take in order to upgrade smoothly.
