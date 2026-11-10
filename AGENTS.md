# AGENTS.md

This repository is the deployment reference for [Sourcegraph with Docker Compose](https://sourcegraph.com/docs/self-hosted/deploy/docker-compose). Customers run `docker-compose/docker-compose.yaml` at a release tag: they check the tag out in a clone of this repository, or merge it into their own fork. We recommend they keep their changes in a `docker-compose.override.yaml` file. The repository holds configuration and a few shell scripts, no application code.

## Layout

- `docker-compose/docker-compose.yaml`: the base file every customer runs. It mounts the service configuration in `caddy/`, `pgsql/`, `codeintel-db/`, `codeinsights-db/`, `grafana/`, `prometheus/`, and `otel-collector/`.
- `docker-compose/db-only-migrate.docker-compose.yaml`: starts only the `pgsql` and `codeintel-db` services, for backup and restore. It `extends` both from the base file, so change them there.
- `docker-compose/examples/`: example override files. `docker-compose/executors/` and `docker-compose/jaeger/` are optional extra compose files. `docker-compose/dev/` is an overlay for developing this repository.
- `test/` and `.buildkite/`: the smoke tests and the CI pipeline.
- `release.yaml`: the release steps that `sg release` runs.

## Checks

- `.tool-versions` pins Node, Yarn, the GitHub CLI, and shellcheck; CI installs them with mise.
- `.buildkite/validate-docker-compose.sh` runs `docker compose config` on every compose file, in each combination the docs say to run. Add a line to it for every new compose file or combination.
- Check formatting with `yarn && yarn run prettier-check`; `yarn run prettier` rewrites the files. Prettier covers only JavaScript and JSON files. `.prettierignore` excludes Markdown and `.github/`, and no formatter runs on YAML, so match the surrounding YAML style by hand.
- CI runs shellcheck on every shell script: `git ls-files -z '*.sh' .buildkite/hooks | xargs -0 shellcheck`.
- The `docker-compose-test` step runs `.buildkite/smoke-test-vm.sh`, which boots a GCP VM from the image named in `IMAGE` in `.buildkite/pipeline.yaml`, runs the two tests below on it, and deletes it. The step reads CI secrets and creates a billed VM, so take its result from the pull request's Buildkite build; run the script yourself only when a person asks. Branches which only change Markdown files skip the step.
  - `test/smoke-test.sh` starts the base file, `jaeger/`, `executors/`, and `test/docker-compose.override.yaml`, then checks that every service has a running container, no container restarted, the health checks pass, and the frontend and Jaeger respond. It counts the services itself, so a new service in those files needs no change to the test. Add a new optional compose file to its `compose_files`.
  - `test/executor-smoke-test.sh` checks that the executor registers with the frontend.
- If the VM stops answering SSH, the script runs the tests once more on a new VM. A test failure is not retried, and the step uploads every container's logs as artifacts.
- GCP deletes each VM an hour after it starts, and the script deletes the VMs and disks which older jobs left behind. Keep the step's `timeout_in_minutes` under an hour.
- The VM image is built from `gcp/images/e2e` in sourcegraph/infrastructure. The release branches name their image too, so leave old images in place.
- The CI agents' queue is still named `vagrant`. Release branches up to `8.1.x` run the smoke test with Vagrant (`.buildkite/vagrant-run.sh`), so a CI change on `main` does not backport cleanly.

## Conventions

- Customer override files refer to the base file's service names, volume names, published ports, and environment variable names. Describe every rename or removal of one in the pull request description.
- Every `image:` has the form `index.docker.io/sourcegraph/<name>:<version>@sha256:<digest>`. The release process sets the versions and digests (`sg ops update-images` in `release.yaml`) and brings them to `main` in "Update main: build v…" pull requests. Leave them unchanged; Renovate is turned off for these images for the same reason.
- `.github/PULL_REQUEST_TEMPLATE.md` requires a "Test plan" section in every pull request description.

## Branches and releases

- `main` tracks development. Each release is a tag such as `v8.1.0`.
- To copy a pull request to a release branch such as `8.1.x`, add the label `backport 8.1.x` to it. `.github/workflows/backport.yml` opens the backport pull request once the original merges.
- The release tooling owns the branches named `internal/release-*`, `promote/release-*`, and `release-v*`, and the `v*` tags. Do not create, push to, or delete them: CI runs the release steps on a branch whose name starts with `internal/release-` or `promote/release-`, and each `release-v*` branch holds the commit of a tag that customers deploy.
