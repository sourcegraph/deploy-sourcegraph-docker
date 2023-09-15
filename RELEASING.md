# Release guide

**This is the guide for releasing the [Pure-Docker Sourcegraph deployment reference](./pure-docker/README.md).**
The docker-compose release is done entirely via the [Sourcegraph release tool](https://about.sourcegraph.com/handbook/engineering/distribution/tools/release).

## Customer Replica

We maintain a copy of pure-docker in a separate [repo](https://github.com/sourcegraph/deploy-sourcegraph-docker-customer-replica-1) for a [customer](https://github.com/sourcegraph/accounts/issues/565). In the past
this was maintained in this repo as a separate series of branches that were suffixed with -customer-replica. This was deprecated in favor of the separate repo after 4.4.1. The repo is included in our release automation so no additional manual steps are required after 4.4.1. This note is just sharing context for future releases and for anyone referencing -customer-replica branches.

## Branching/tagging scheme

Just like deploy-sourcegraph, we use version branches and version tags.

- Tag examples: `v3.8.2`, `v3.9.2`
- Branch examples: `3.8`, `3.9`

## Releasing a new version

### Create the release branch

> ⚠️ If you are using the Sourcegraph release tooling, this step will be done for you in the PR it creates. Learn more about the release process in [the handbook](https://about.sourcegraph.com/handbook/engineering/releases). In this case, do not do this step manually.

For example if releasing `v3.17.2` then create this branch from latest `master`:

```
git checkout -B 3.17
git push --set-upstream origin 3.17
```

### Update the image tags

> ⚠️ If you are using the Sourcegraph release tooling, this step will be done for you in the PR it creates. Learn more about the release process in [the handbook](https://about.sourcegraph.com/handbook/engineering/releases). In this case, do not do this step manually.

In the latest release branch you created:

1. Run `tools/update-docker-tags.sh $VERSION`
2. Confirm the diff shows the image tags being updated to the version you expect, and push directly to the release branch.

### Smoke Test: ensure  Pure-Docker starts from scratch

> ⚠️ This test now runs in Buildkite, under the `pure-docker-test` step - you can validate [the results of the CI run](https://buildkite.com/sourcegraph/deploy-sourcegraph-docker) instead.
### Smoke test: ensure Docker Compose starts from scratch

> ⚠️ This test now runs in Buildkite, under the `docker-compose-test` step - you can validate [the results of the CI run](https://buildkite.com/sourcegraph/deploy-sourcegraph-docker) instead.

Refer to the [testing documentation](TESTING.md) for running tests from your local machine.

### Smoke test: ensure Docker Compose upgrades work

> ⚠️ This test now runs in Buildktie, in the `qa` pipeline under the `Sourcegraph Upgrade` step, you can validate [the results of the CI run](https://buildkite.com/sourcegraph)

Refer to the [testing documentation](TESTING.md) for running tests from your local machine.

### Tag the final release

> ⚠️ If you are using the Sourcegraph release tooling, this will be done for you as part of the release steps. Learn more about the release process in [the handbook](https://about.sourcegraph.com/handbook/engineering/releases). In this case, do not do this step manually.

For example:

```
git checkout 3.9
git tag v3.9.2
git push origin v3.9.2
```

## Releasing pure-docker

For pure-docker, we provide customers with an exact diff of changes to make. They do not run our deploy.sh scripts directly, instead they copy them or adapt them to their own deployment environment entirely. This means we must carefully communicate each change that is made.

To reduce the chance for errors, we send an exact diff of changes. This diff needs to be as minimal and concise as possible, and e.g. not include changes to unrelated files like `.prettierignore` or `docker-compose/` to avoid any confusion. See https://docs.sourcegraph.com/admin/updates/pure_docker for examples of what these diffs look like.
