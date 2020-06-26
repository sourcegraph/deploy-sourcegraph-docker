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

## 5) Confirm Pure-Docker works on the customer replica instance

**Contact @stephen on Slack and ask him to perform this step, do not attempt it yourself.**

If for example deploy-sourcegraph-docker's last release was v3.8.2 and you are releasing v3.9.2:

1. Locate the latest `master` commit that correlates with the 3.9 release branch cut date.
2. `git checkout <commit> && git checkout -B 3.9 && git push` to create the release branch here.
3. Commit all relevant changes upstream on deploy-sourcegraph here, e.g. by viewing the diff at https://github.com/sourcegraph/deploy-sourcegraph/compare/v3.8.2..v3.9.2
4. `git tag v3.9.2 && git push origin v3.9.2`

Then for smoke testing & customer replication please also:

- `git checkout 3.8-customer-replica`
- `git checkout -B 3.9-customer-replica`
- `git merge 3.9` -> fix conflicts manually -> `git commit && git push --set-upstream origin 3.9-customer-replica`
- `git tag customer-replica-v3.9.2 && git push origin customer-replica-v3.9.2`
- Proceed with testing on customer replica environment: https://github.com/sourcegraph/infrastructure
- Check diff before sending it to customers as it is often applied by hand: https://github.com/sourcegraph/deploy-sourcegraph-docker/compare/customer-replica-v3.8.2..customer-replica-v3.9.2

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
    - ask Stephen on Slack to write an entry for https://sourcegraph.com/github.com/sourcegraph/sourcegraph@a718276cbdc4c9e079d5495cb34ce663c5d35c01/-/blob/doc/admin/updates/pure_docker.md#updating-a-pure-docker-sourcegraph-cluster
    - Update `latestReleaseDockerComposeOrPureDocker` in https://github.com/sourcegraph/sourcegraph/blob/master/cmd/frontend/internal/app/pkg/updatecheck/handler.go#L47

# This repository branching / tag scheme

Just like deploy-sourcegraph, we use version branches and version tags. We _additionally_ have a second set which is customer-replication branches and version tags:

- Tag examples: `v3.8.2`, `v3.9.2`, `customer-replica-v3.8.2`, `customer-replica-v3.9.2-2`
- Branch examples: `3.8`, `3.9`, `3.8-customer-replica`, `3.9-customer-replica`

The customer replica ones are important as we must maintain some diffs for replication purposes, such as using a different Postgres version, changes to the `prometheus_targets.yml` and more. We use tags to ensure each AMI we save correlates directly with an immutable Git tag.
