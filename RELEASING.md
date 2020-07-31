# Releasing a new version

## 1) Update the image tags in `master`

In the latest `master` branch:

1. Find and replace `:insiders` with `:3.0.0` on all files except this one. This is required for the next step.
2. Run these commands:

```
go get -u github.com/slimsag/update-docker-tags
update-docker-tags --constraint 'sourcegraph/prometheus=<10.0' --constraint 'sourcegraph/grafana=<6.0' .
```

3. Confirm the diff shows the image tags being updated to the version you expect, and push directly to `master`.

## 2) Create the release branch:

For example if releasing `v3.17.2` then create this branch from latest `master`:

```
git checkout -B 3.17
git push --set-upstream origin 3.17
```

## 3) Smoke test: ensure Docker Compose starts from scratch

**IMPORTANT**: This step MUST be ran on a Linux machine, NOT Mac or Windows/WSL. This is because Docker for Linux treats file permissions differently and we must identify such issues.

```
git checkout <version_branch>
cd docker-compose/
docker-compose up -d
```

Check that all services come up and report as healthy in the output of:

```
docker ps
```

Visit http://localhost and confirm the app loads.

## 4) Smoke test: ensure Docker Compose upgrades work

**IMPORTANT**: This step MUST be ran on a Linux machine, NOT Mac or Windows/WSL. This is because Docker for Linux treats file permissions differently and we must identify such issues.

Start the prior version of Docker Compose:

```
git checkout <previous_version_branch>
cd docker-compose/
docker-compose up -d
```

Check that all services come up and report as healthy in the output of:

```
docker ps
```

Visit http://localhost and confirm the app loads.

Upgrade to the latest version:

```
docker-compose down
git checkout master
docker-compose up -d
```

Check that all services come up and report as healthy in the output of:

```
docker ps
```

Visit http://localhost and confirm the app loads.

## 5) Confirm Pure-Docker works with a smoke test

(this will take about ~7 minutes to run, and you must have a machine with 8 CPUs)

```sh
cd testing/
vagrant up
./smoke-test.sh
vagrant destroy
```

**Message @stephen on Slack:**

> I am releasing deploy-sourcegraph-docker, please release pure-docker.

If you are Stephen, follow [releasing pure-docker](#releasing-pure-docker)

## 6) Tag the final release

For example:

```
git checkout 3.9
git tag v3.9.2
git push origin v3.9.2
```

## 7) Update documentation & publish notifications

Replace the old version with the new version in the `master` branches of the following:

- This repository: `docker-compose/README.md`
- sourcegraph/sourcegraph:
    - replace two instances: https://github.com/sourcegraph/sourcegraph/blob/master/doc/admin/install/docker-compose/index.md
    - add a new section with all relevant upgrade details: https://sourcegraph.com/github.com/sourcegraph/sourcegraph@a718276cbdc4c9e079d5495cb34ce663c5d35c01/-/blob/doc/admin/updates/docker_compose.md#updating-a-docker-compose-sourcegraph-instance
    - Update `latestReleaseDockerComposeOrPureDocker` in https://github.com/sourcegraph/sourcegraph/blob/master/cmd/frontend/internal/app/pkg/updatecheck/handler.go#L47

## 8) Post that you are done.

Write a message to #dev-announce:

> Docker Compose v3.9.2 has been released.

# This repository branching / tag scheme

Just like deploy-sourcegraph, we use version branches and version tags. We _additionally_ have a second set which is customer-replication branches and version tags:

- Tag examples: `v3.8.2`, `v3.9.2`, `customer-replica-v3.8.2`, `customer-replica-v3.9.2-2`
- Branch examples: `3.8`, `3.9`, `3.8-customer-replica`, `3.9-customer-replica`

The customer replica ones are important as we must maintain some diffs for replication purposes, such as using a different Postgres version, changes to the `prometheus_targets.yml` and more. We use tags to ensure each AMI we save correlates directly with an immutable Git tag.

## Releasing pure-docker

@stephen handles releasing pure Docker after Docker Compose is released. This process is tedious and manual, and applies to one single customer only.

For pure-docker, we provide customers with an exact diff of changes to make. They do not run our deploy.sh scripts directly, instead they copy them or adapt them to their own deployment environment entirely. This means we must carefully communicate each change that is made.

To reduce the chance for errors, we send an exact diff of changes. This diff needs to be as minimal and concise as possible, and e.g. not include changes to unrelated files like `.prettierignore` or `docker-compose/` to avoid any confusion. See https://docs.sourcegraph.com/admin/updates/pure_docker for examples of what these diffs look like.

Pretend `3.8` was the last version of pure-docker release (look for the latest `n.n-customer-replica` branch), and that `3.9` is the version we want to release (which must have already been released for Docker Compose deployments). Then:

```sh
# Checkout the current pure-docker release branch
git checkout 3.8-customer-replica 

# Create the new pure-docker release branch
git checkout -B 3.9-customer-replica 

# Merge the 3.9 branch into the pure-docker release branch.
git merge 3.9

# Show which files may have been deleted, etc.
git status

# Reset to HEAD so we can manually inspect ALL changes - we do not want to actually do a merge.
git reset HEAD
```

At this point you should evaluate the `git status` output as well as all the changes in your working git directory. You need to ensure the following happens:

1. Files that were shown as deleted in the `git status` output get deleted in the relevant commit.
2. Create **one** commit with changes _unrelated to the upgrade_, i.e. include ALL changes that are not directly related to upgrading:
    - `git commit -m 'merge 3.8 (changes unrelated to upgrade)'`
3. Create **one** commit with the changes _customers need to apply in order to ugprade_, i.e. the image tag changes, adding/removing any new services, updating env vars, but no unrelated changes.
    - Do not include `docker-compose/` changes in this commit, those are irrelevant to pure-docker users.
    - `git commit -m 'upgrade to v3.8.2'`

During this process you will run into two merge conflicts:

- Do not commit: `deploy-caddy.sh` or changes related to it, as `deploy-apache.sh` is used here.
- Do not commit: changes to `deploy-pgsql.sh`, as Postgres 9.6 is used here.

Once you have performed the above, you should run a basic smoke test to ensure that `./deploy.sh` on Ubuntu 18.04 causes all services to start up OK, that the frontend is responsive, and that no container UID/GIDs/file permissions have changed (which would be a regression). You can do this with Vagrant:

```sh
cd testing/
vagrant up
./smoke-test.sh
vagrant destroy
```

Once you see `ALL TESTS PASSED`, then push the new pure-docker release branch up and tag the release:

```sh
git push --set-upstream origin 3.8-customer-replica
git tag customer-replica-v3.8.2
git push origin customer-replica-v3.8.2
```

Write an entry for https://docs.sourcegraph.com/admin/updates/pure_docker which includes:

- A link to your `upgrade to v3.8.2` commit describing the exact changes needed to be made.
- Any specific manual migrations, including potential `chown` commands that may be needed (if any new service is introduced, etc.)
