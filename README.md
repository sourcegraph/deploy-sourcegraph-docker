# WIP

This project is a work in progress, it is not yet ready for use. If you are interested in this project, please open an issue to get in touch! :)

Remaining work: see [issue tracker](https://github.com/sourcegraph/deploy-sourcegraph-docker/issues)

# deploy-sourcegraph-docker

This project contains scripts to deploy Sourcegraph Data Center on pure Docker, rather than e.g. Kubernetes.

**The point of this project is to make Sourcegraph easy to deploy into any container-based environment.**

It is not expected that anyone would actually run Sourcegraph Data Center on bare Docker in production.

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
