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

## Known issues

- Code intelligence language support is not yet working here. We are improving/changing how language support is deployed in data center instances, so this project does not yet try to deploy language servers.
- `zoekt-indexserver`, `repo-updater`, and `indexer` all require `--priviledged` or else DNS fails to resolve on Docker for Mac. It is unclear yet why this is, but this is a bug.
- Some services are more complex than they need to be, we are actively simplifying / removing env vars / configuration files that are needed.
- This project does not try to deploy e.g. prometheus metrics / monitoring yet.
