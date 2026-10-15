# Testing

## Smoke test

CI runs `test/smoke-test.sh` on every pull request, on a GCP VM managed by
[Vagrant](https://www.vagrantup.com) (`.buildkite/vagrant-run.sh docker-test`).
It starts the Docker Compose deployment and checks that all containers are
running and the frontend answers on port 80.

To run it yourself you need access to the `sourcegraph-ci` GCP project and
its `e2e-builder-sa-key` and `DOCKER_PASSWORD_BUILDKITE_AGENT` secrets, which
`vagrant-run.sh` reads with `gcloud secrets versions access`. The VM image is
built from `gcp/images/e2e` in `sourcegraph/infrastructure`; its name is the
`IMAGE` value in `.buildkite/pipeline.yaml`.

```sh
export IMAGE="<IMAGE value from .buildkite/pipeline.yaml>"
export VAGRANT_GCP_PROJECT_ID=sourcegraph-ci
export VAGRANT_SSH_USER="<SSH user in the project's instance metadata>"
export VAGRANT_SSH_KEY="<matching private key, default ~/.ssh/id_rsa>"
.buildkite/vagrant-run.sh docker-test
```

Do not set `VAGRANT_RUN_ENV=CI` outside CI: it gives the VM a private IP
only, which is reachable from the Buildkite agents but not from a laptop.

The script installs the `vagrant-google`, `vagrant-env` and `vagrant-scp`
plugins, creates the VM, syncs this repository to `/deploy-sourcegraph-docker`
on it, runs the smoke test, and destroys the VM on exit. Container logs from a
failed run are copied to the repository root as `*.log`.

To run more commands on the VM, add them to the `shell_commands` list in
`test/servers.yaml`.

## Upgrade test

`test/upgrade-test.go` runs a standard or multi-version upgrade between
released versions on the local Docker daemon, and checks for schema drift,
the `versions` table, and failed rows in `migration_logs`. It clones this
repository into a temporary directory and checks out the version tags, so it
does not use your working copy.

```sh
go run ./test standard --versions 8.0.0,8.1.0
go run ./test multiversion --from 7.0.0 --to 8.1.0
go run ./test --help
```
