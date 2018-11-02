# pure-Docker Sourcegraph cluster deployment reference

[![sourcegraph: search](https://img.shields.io/badge/sourcegraph-search-brightgreen.svg)](https://sourcegraph.com/github.com/sourcegraph/deploy-sourcegraph-docker)

There are two recommended ways to deploy Sourcegraph:

- [Single-machine Docker deployment](https://docs.sourcegraph.com/admin/install/docker)
- [Multi-machine Kubernetes deployment](https://docs.sourcegraph.com/admin/install/kubernetes_cluster)

But what if your organization wants a multi-machine deployment without using Kubernetes? What if you use a different container management platform, for example? This project aims to solve that, by providing a pure-Docker deployment option.

The goal is that anyone using a container management platform other than Kubernetes (Netflix's [Titus](https://netflix.github.io/titus/), Apache's [Mesos](http://mesos.apache.org/documentation/latest/docker-containerizer/), etc.) would be able to use this repository as a reference for how to deploy Sourcegraph.

## Deploying

First clone the repository, then:

```bash
./deploy.sh
```

Visit http://localhost:3080 to visit the running Sourcegraph Data Center instance!

## Tearing down the deployment

```bash
./teardown.sh
```
