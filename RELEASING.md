# Release guide

**This is the guide for releasing the [Pure-Docker Sourcegraph deployment reference](./pure-docker/README.md).**
The docker-compose release is done entirely via the [Sourcegraph release tool](https://about.sourcegraph.com/handbook/engineering/distribution/tools/release).

## Branching/tagging scheme

Just like deploy-sourcegraph, we use version branches and version tags. We _additionally_ have a second set which is customer-replication branches and version tags:

- Tag examples: `v3.8.2`, `v3.9.2`, `customer-replica-v3.8.2`, `customer-replica-v3.9.2-2`
- Branch examples: `3.8`, `3.9`, `3.8-customer-replica`, `3.9-customer-replica`

The customer replica branches are distinct living branches which have diffs we maintain for replicating some customers using the pure-docker deployment model described in the README.md of this repository (e.g. the customers' different Postgres version, changes to the `prometheus_targets.yml`, and more.) We test, tag, and release these `$VERSION-customer-replica` branches as `customer-replica-$VERSION` to produce the final diffs we send to customers running a pure-docker deployment on e.g. in the [pure docker upgrade guide](https://docs.sourcegraph.com/admin/updates/pure_docker).

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

Pretend `3.8` was the last version of pure-docker release (look for the latest `n.n-customer-replica` branch), and that `3.9` is the version we want to release. Then:

```sh
# Checkout the current pure-docker release branch
git checkout 3.8-customer-replica 

# Create the new pure-docker release branch
git checkout -B 3.9-customer-replica 

# Merge the publish-3.9 branch, which will have been created by the release tool, into the pure-docker release branch.
git merge publish-3.9

# Show which files may have been deleted, etc.
git status

# Reset to HEAD so we can manually inspect ALL changes - we do not want to actually do a merge.
git reset HEAD
```

At this point you should evaluate the `git status` output as well as all the changes in your working git directory. You need to ensure the following happens:

1. Files that were shown as deleted in the `git status` output get deleted in the relevant commit.
2. Create **one** commit with changes _unrelated to the upgrade_, i.e. include ALL changes that are not directly related to upgrading:
    - `git commit -m 'merge 3.9 (changes unrelated to upgrade)'`
3. Create **one** commit with the changes _customers need to apply in order to ugprade_, i.e. the image tag changes, adding/removing any new services, updating env vars, but no unrelated changes.
    - Do not include `docker-compose/` changes in this commit, those are irrelevant to pure-docker users.
    - `git commit -m 'upgrade to v3.9.0'`

During this process you will run into two merge conflicts:

- Do not commit: `deploy-caddy.sh` or changes related to it, as `deploy-apache.sh` is used here.
- Do not commit: changes to `deploy-pgsql.sh`, as Postgres 9.6 is used here.

4. Push the changes to github
```shell
git push --set-upstream origin 3.9-customer-replica
```

Check buildkite for the branch after pushing it, e.g. at https://github.com/sourcegraph/deploy-sourcegraph-docker/commits/3.19-customer-replica

This will take about ~10 minutes to run. Refer to the [testing documentation](TESTING.md) if you run into issues / need more instructions.

Once you see `ALL TESTS PASSED`, tag the release:

```sh
git tag customer-replica-v3.9.0
git push origin customer-replica-v3.9.0
```

Write an entry for https://docs.sourcegraph.com/admin/updates/pure_docker which includes:

- A link to your `upgrade to v3.9.0` commit describing the exact changes needed to be made.
- Any specific manual migrations, including potential `chown` commands that may be needed (if any new service is introduced, etc.)
- Look at https://github.com/sourcegraph/sourcegraph/pulls?q=is%3Apr+is%3Aopen+pure-docker to see if there are any open PRs that might need to be included.

Contact https://app.hubspot.com/contacts/2762526/company/407948923/ over Slack and inform them the update is available, providing a link to the diff and other relevant details like the blog post link.
