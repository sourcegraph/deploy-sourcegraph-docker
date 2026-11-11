# AGENTS.md

This repository is the deployment reference for [Sourcegraph with Docker Compose](https://sourcegraph.com/docs/self-hosted/deploy/docker-compose). Customers run `docker-compose/docker-compose.yaml` at a release tag: they check the tag out in a clone of this repository, or merge it into their own fork. We recommend they keep their changes in a `docker-compose.override.yaml` file. The repository holds configuration and a few shell scripts, no application code.

## Layout

- `docker-compose/docker-compose.yaml`: the base file every customer runs. It mounts the service configuration in `caddy/`, `pgsql/`, `codeintel-db/`, `codeinsights-db/`, `grafana/`, `prometheus/`, and `otel-collector/`.
- `docker-compose/db-only-migrate.docker-compose.yaml`: starts only the three databases, for backup and restore. It `extends` them from the base file, so change them there. Do not add any other service to it.
- `docker-compose/examples/`: example override files. `docker-compose/executors/` and `docker-compose/jaeger/` are optional extra Compose files. `docker-compose/dev/` is an overlay for developing this repository.
- `test/` and `.buildkite/`: the smoke tests and the CI pipeline.
- `release.yaml`: the release steps that `sg release` runs. `batch-change/release.yaml` is the batch change flavour of the same steps; when you change a step in one, check the other.

## Checks

CI runs these on every branch. `.tool-versions` pins Node, the GitHub CLI, and shellcheck; CI installs them with mise. `renovate.json` turns Renovate off so that these tools are upgraded together with the `sourcegraph/sourcegraph` monorepo, not on their own.

- **Compose files:** `.buildkite/validate-docker-compose.sh` runs `docker compose config` on every Compose file, in each combination the docs say to run. Add a line to it for every new Compose file or combination.
- **Formatting:** `npm ci && npm run prettier-check`; `npm run prettier` rewrites the files. Prettier formats the JavaScript and JSON files; the repository has no other file type its glob matches. `.prettierignore` excludes Markdown and `.github/`, and no formatter runs on YAML, so match the surrounding YAML style by hand.
- **Shell scripts:** `git ls-files -z '*.sh' .buildkite/hooks | xargs -0 shellcheck`.
- **Smoke test:** the `docker-compose-test` step runs `.buildkite/vagrant-run.sh docker-test`. See below.

Use `docker compose` (v2) in scripts and docs, not `docker-compose`.

## Smoke test

`.buildkite/vagrant-run.sh` uses Vagrant to boot a GCP VM from the image named in `IMAGE` in `.buildkite/pipeline.yaml`, runs the two tests below on it, and deletes it. It reads CI secrets and creates a billed VM, so take its result from the pull request's Buildkite build; run the script yourself only when a person asks.

- `test/smoke-test.sh` starts the base file, `jaeger/`, `executors/`, and `test/docker-compose.override.yaml` with `docker compose up --wait`, which fails if any container reports `unhealthy`. It then checks that every service has a running container, no container restarted, and the frontend and Jaeger respond. It counts the services itself, so a new long-running service in those files needs no change to the test. A new service which exits when it is done, like `migrator`, must be left out of the count. Add a new optional Compose file to its `compose_files`.
- `test/executor-smoke-test.sh` checks that the executor registers with the frontend.
- A service which is not ready until another service is needs a `start_period` on its health check, or `--wait` fails.
- A test failure is not retried, and the step uploads every container's logs as artifacts. Only the image pull is retried: `test/smoke-test.sh` tries `docker compose pull` three times.
- A branch which only changes files listed in the step's `if_changed` `exclude` skips the step. Builds on `main` always run it. When the smoke test starts reading a file on that list, remove it from the list.
- The VM image is built from `gcp/images/e2e` in sourcegraph/infrastructure.

## Conventions

- Customer override files refer to the base file's service names, volume names, published ports, and environment variable names. Describe every rename or removal of one in the pull request description.
- Every `image:` has the form `index.docker.io/sourcegraph/<name>:<version>@sha256:<digest>`. The release process sets the versions and digests (`sg ops update-images` in `release.yaml`) and brings them to `main` in "Update main: build v…" pull requests. Leave them unchanged.
- `.github/PULL_REQUEST_TEMPLATE.md` requires a "Test plan" section in every pull request description.

## Branches and releases

- `main` tracks development. Each release is a tag such as `v8.1.0`.
- To copy a pull request to a release branch such as `8.2.x`, add the label `backport 8.2.x` to it. `.github/workflows/backport.yml` opens the backport pull request once the original merges.
- The release tooling owns the branches named `internal/release-*`, `promote/release-*`, and `release-v*`, and the `v*` tags. Do not create, push to, or delete them: CI runs the release steps on a branch whose name starts with `internal/release-` or `promote/release-`, and each `release-v*` branch holds the commit of a tag that customers deploy.
