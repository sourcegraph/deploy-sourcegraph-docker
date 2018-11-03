# Pure-Docker Sourcegraph cluster deployment reference

[![sourcegraph: search](https://img.shields.io/badge/sourcegraph-search-brightgreen.svg)](https://sourcegraph.com/github.com/sourcegraph/deploy-sourcegraph-docker)

There are two recommended ways to deploy Sourcegraph:

- [Single-machine Docker deployment](https://docs.sourcegraph.com/admin/install/docker)
- [Multi-machine Kubernetes deployment](https://docs.sourcegraph.com/admin/install/kubernetes_cluster)

But what if your organization wants a multi-machine deployment without using Kubernetes? What if you use a different container management platform, for example? This project aims to solve that, by providing a pure-Docker deployment option.

The goal is that anyone using a container management platform other than Kubernetes (Netflix's [Titus](https://netflix.github.io/titus/), Apache's [Mesos](http://mesos.apache.org/documentation/latest/docker-containerizer/), etc.) would be able to use this repository as a reference for how to deploy Sourcegraph.

## ⚠️ Alpha release

This project is using an alpha release of Sourcegraph v3.0.0. It is not yet heavily tested, and there may be major bugs or regressions. [Code intelligence does not yet work with this deployment method](https://github.com/sourcegraph/deploy-sourcegraph-docker/issues/2).

When Sourcegraph v3.0.0 preview is released, this repository will be updated and code intelligence will work.

## Deploying

First clone the repository, then:

```bash
./deploy.sh
```

Visit http://localhost:3080 to visit the running Sourcegraph instance!

## Tearing down the deployment

```bash
./teardown.sh
```

## System topology

To understand the system topology:

1. Look at `deploy.sh` to get an overview of services.
2. Every service (`deploy-*.sh`) has documentation inline indicating:
  - What the service does / provides.
  - What ports the service exposes.
  - What other services it talks to (see environment variables).

## Service system requirements

Every service (`deploy-*.sh`) documents inline what the system requirements are (CPU/Memory/Disk allocation). For example, [the frontend service](https://github.com/sourcegraph/deploy-sourcegraph-docker/blob/f01b97a397138dd76e5f5ed45b2574b9a2e70cd1/deploy-frontend.sh#L6-L9).

## Scaling / replicas

To scale the cluster deployment, you will need to:

1. Deploy more instances of `gitserver`, `searcher`, and `symbols` services as desired.
2. [Configure the `frontend` and `frontend-internal` to communicate with the new instances.](https://github.com/sourcegraph/deploy-sourcegraph-docker/blob/f01b97a397138dd76e5f5ed45b2574b9a2e70cd1/deploy-frontend.sh#L31-L34)
3. You're done! You do not need to configure or restart any other services.

## Configuring HTTPS

See documentation [inline here](https://github.com/sourcegraph/deploy-sourcegraph-docker/blob/f01b97a397138dd76e5f5ed45b2574b9a2e70cd1/deploy-frontend.sh#L26-L29).

## Questions

[Open an issue](https://github.com/sourcegraph/deploy-sourcegraph-docker/issues/new) or contact us (support@sourcegraph.com), we are happy to answer any questions!
