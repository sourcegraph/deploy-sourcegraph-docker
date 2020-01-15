# Sourcegraph for docker-compose

This folder contains a Sourcegraph docker-compose deployment.

**NOTE:** This is early access and slated for release in Sourcegraph v3.12; the missing components today are primarily documentation. Please contact us (support@sourcegraph.com) if you are looking at using this in production so we can assist you.

## Deploying

Simply clone the repository and `docker-compose up -d` to deploy Sourcegraph:

```sh
git clone https://github.com/sourcegraph/deploy-sourcegraph-docker
cd deploy-sourcegraph-docker/docker-compose/
git checkout v3.11.4
docker-compose up -d
```

Sourcegraph will then run in the background and across server restarts.

Notes:

- The `docker-compose.yml` file currently depends on configuration files which live in the repository, as such you must have the repository cloned onto your server.
- Data for all services will be stored in `$DATA_ROOT` (which defaults to `~/sourcegraph-docker`).
- Use `docker ps` to inspect the Sourcegraph containers, and `docker-compose down` to teardown the deployment.

## Upgrading

When a new version of Sourcegraph is released, you will simply checkout that version in this repository and redeploy:

```sh
cd deploy-sourcegraph-docker/docker-compose
git pull
git checkout v3.11.4
docker-compose down
docker-compose up -d
```
