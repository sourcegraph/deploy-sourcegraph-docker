# AGENTS.md

This repository is the deployment reference for [Sourcegraph with Docker Compose](https://sourcegraph.com/docs/self-hosted/deploy/docker-compose). Customers merge each release tag into their own copy of this repository, run `docker-compose/docker-compose.yaml`, and keep their changes in a `docker-compose.override.yaml` file. The repository holds configuration and a few shell scripts, no application code.

## Layout

- `docker-compose/docker-compose.yaml`: the base file every customer runs. It mounts the service configuration in `caddy/`, `pgsql/`, `codeintel-db/`, `codeinsights-db/`, `grafana/`, `prometheus/`, and `otel-collector/`.
- `docker-compose/db-only-migrate.docker-compose.yaml`: a copy of the `pgsql` and `codeintel-db` services for backup and restore. Make every change to those two services in both files.
- `docker-compose/examples/`: example override files. `docker-compose/executors/` and `docker-compose/jaeger/` are optional extra compose files. `docker-compose/dev/` is an overlay for developing this repository.
- `test/` and `.buildkite/`: the smoke test and the CI pipeline.
- `release.yaml`: the release steps that `sg release` runs.

## Checks

- `.tool-versions` pins Node, Yarn, and the GitHub CLI; CI installs them with mise.
- Validate the base file with `docker compose -f docker-compose/docker-compose.yaml config -q`. CI runs the same check in `.buildkite/validate-docker-compose.sh` with the standalone `docker-compose` binary, so the base file must stay valid for that binary. CI validates no other compose file.
- Check formatting with `yarn && yarn run prettier-check`; `yarn run prettier` rewrites the files. Prettier covers only JavaScript and JSON files. `.prettierignore` excludes Markdown and `.github/`, and no formatter runs on YAML, so match the surrounding YAML style by hand.
- The `docker-compose-test` step in `.buildkite/pipeline.yaml` starts the base file on a GCP VM and runs `test/smoke-test.sh`. It reads CI secrets and creates a billed VM, so take its result from the pull request's Buildkite build; run `.buildkite/vagrant-run.sh docker-test` yourself only when a person asks.
- `test/smoke-test.sh` compares the number of running containers with `expect_containers`. Update that number in the same pull request that adds or removes a service.
- CI does not run `test/executor-smoke-test.sh`. Run it against a running deployment when you change `docker-compose/executors/`.

## Conventions

- Customer override files refer to the base file's service names, volume names, published ports, and environment variable names. Describe every rename or removal of one in the pull request description.
- Every `image:` has the form `index.docker.io/sourcegraph/<name>:<version>@sha256:<digest>`. The release process sets the versions and digests (`sg ops update-images` in `release.yaml`) and brings them to `main` in "Update main: build v…" pull requests. Leave them unchanged; Renovate is turned off for these images for the same reason.
- `.github/PULL_REQUEST_TEMPLATE.md` requires a "Test plan" section in every pull request description.

## Branches and releases

- `main` tracks development. Each release is a tag such as `v8.1.0`.
- To copy a pull request to a release branch such as `8.1.x`, add the label `backport 8.1.x` to it. `.github/workflows/backport.yml` opens the backport pull request once the original merges.
- The release tooling owns the branches named `internal/release-*`, `promote/release-*`, and `release-v*`, and the `v*` tags. Do not create, push to, or delete them: CI runs the release steps on a branch whose name starts with `internal/release-` or `promote/release-`, and each `release-v*` branch holds the commit of a tag that customers deploy.
