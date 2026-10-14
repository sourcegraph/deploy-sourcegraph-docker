# Sourcegraph with Docker Compose

[![sourcegraph: search](https://img.shields.io/badge/sourcegraph-search-brightgreen.svg)](https://sourcegraph.com/github.com/sourcegraph/deploy-sourcegraph-docker) [![Build status](https://badge.buildkite.com/e60f9ffcafd68882d3db6fe5e33567e3a111d391a554d50d82.svg)](https://buildkite.com/sourcegraph/deploy-sourcegraph-docker)

This repository is the deployment reference for [deploying Sourcegraph with Docker Compose](https://sourcegraph.com/docs/self-hosted/deploy/docker-compose).

> 🚨 IMPORTANT: When upgrading Sourcegraph, please check the [upgrade docs](https://sourcegraph.com/docs/self-hosted/deploy/docker-compose/upgrade) and [changelog](https://sourcegraph.com/changelog/self-hosted/docker-compose) to check if any manual migrations are necessary.
>
> The `main` branch tracks development. Use the tag of this repository corresponding to the
> version of Sourcegraph you wish to deploy, e.g. `git checkout v8.1.0`.

## Is Docker Compose the right deployment type for me?

Please see [our docs](https://sourcegraph.com/docs/self-hosted/deploy) for comparisons of deployment types and our resource estimator.

## Contributing

We've made our deployment configurations open source to better serve our customers' needs. If there is anything we can do to make deploying Sourcegraph easier just [open an issue (in sourcegraph/sourcegraph)](https://github.com/sourcegraph/sourcegraph/issues/new?assignees=&labels=deploy-sourcegraph-docker&title=%5Bdeploy-sourcegraph-docker%5D) or a pull request and we will respond promptly!

See [TESTING.md](TESTING.md) for how to run the smoke test.

### Releasing

Please see the [documentation](https://go/releases).

## Questions & Issues

[Open an issue (in sourcegraph/sourcegraph)](https://github.com/sourcegraph/sourcegraph/issues/new?assignees=&labels=deploy-sourcegraph&template=deploy-sourcegraph.md&title=%5Bdeploy-sourcegraph%5D) or contact us (support@sourcegraph.com), we are happy to help!
