# Sourcegraph with Docker Compose

[![sourcegraph: search](https://img.shields.io/badge/sourcegraph-search-brightgreen.svg)](https://sourcegraph.com/github.com/sourcegraph/deploy-sourcegraph-docker) [![Build status](https://badge.buildkite.com/e60f9ffcafd68882d3db6fe5e33567e3a111d391a554d50d82.svg)](https://buildkite.com/sourcegraph/deploy-sourcegraph-docker)

This repository is the deployment reference for [deploying Sourcegraph with Docker Compose](https://docs.sourcegraph.com/admin/install/docker-compose).

> 🚨 IMPORTANT: When upgrading Sourcegraph, please check [upgrading docs](https://docs.sourcegraph.com/admin/updates/docker_compose) to check if any manual migrations are necessary.
>
> The `master` branch tracks development. Use the branch of this repository corresponding to the
> version of Sourcegraph you wish to deploy, e.g. `git checkout 3.19`.

For product and [pricing](https://about.sourcegraph.com/pricing/) information, visit
[about.sourcegraph.com](https://about.sourcegraph.com) or [contact
us](https://about.sourcegraph.com/contact/sales) for more information. If you're just starting out,
we recommend running Sourcegraph as a [single Docker
container](https://docs.sourcegraph.com/#quickstart-guide) or using [Docker
Compose](https://docs.sourcegraph.com/admin/install/docker-compose). Migrating to Sourcegraph on
Kubernetes is easy later.

## Is Docker Compose the right deployment type for me?

Please see [our docs](https://docs.sourcegraph.com/admin/install) for comparisons of deployment types and our resource estimator.

## Contributing

We've made our deployment configurations open source to better serve our customers' needs. If there is anything we can do to make deploying Sourcegraph easier just [open an issue (in sourcegraph/sourcegraph)](https://github.com/sourcegraph/sourcegraph/issues/new?assignees=&labels=deploy-sourcegraph-docker&title=%5Bdeploy-sourcegraph-docker%5D) or a pull request and we will respond promptly!

## Questions & Issues

[Open an issue (in sourcegraph/sourcegraph)](https://github.com/sourcegraph/sourcegraph/issues/new?assignees=&labels=deploy-sourcegraph&template=deploy-sourcegraph.md&title=%5Bdeploy-sourcegraph%5D) or contact us (support@sourcegraph.com), we are happy to help!

## Pure-Docker Sourcegraph cluster deployment reference

What if your organization wants a multi-machine deployment without using Kubernetes?
What if you use a different container management platform, for example?
Anyone using a container management platform other than Kubernetes (Netflix's [Titus](https://netflix.github.io/titus/), Apache's [Mesos](http://mesos.apache.org/documentation/latest/docker-containerizer/), etc.) can use our [Pure-Docker Sourcegraph cluster deployment reference](./pure-docker/README.md) to deploy Sourcegraph.

---

## Releasing


