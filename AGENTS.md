# AGENTS.md

Guidance for coding agents working in this repository.

## What this repo is

This is the **deployment reference for Sourcegraph with Docker Compose** (`github.com/sourcegraph/deploy-sourcegraph-docker`). It is primarily configuration (Docker Compose YAML, service configs, dashboards) plus small Go and shell tooling for testing and releases — not an application codebase.

The `main` branch tracks development. Versioned branches (e.g. `3.19`) correspond to released Sourcegraph versions.

## Where the main code/config lives

- `docker-compose/` — the deployment reference; `docker-compose/docker-compose.yaml` is the primary entrypoint, with `dev/`, `examples/`, `executors/`, and `jaeger/` variants.
- Service config directories: `caddy/`, `nginx/`, `pgsql/`, `codeintel-db/`, `codeinsights-db/`, `grafana/`, `prometheus/`, `otel-collector/`.
- `test/` — smoke and upgrade tests (`smoke-test.sh`, `upgrade-test.go`, `Vagrantfile`, `servers.yaml`).
- `tools/` — Go-pinned CLIs (`update-docker-tags`) and `migrate.sh`.
- `.buildkite/` — CI scripts and pipeline.

## Toolchain versions

Defined in `.tool-versions` (asdf/mise): Go `1.19.8`, Node `16.7.0`, Yarn `1.22.4`, shellcheck `0.7.1`, github-cli `2.46.0`, checkov.

## Setup, build, and checks

These mirror what CI (`.buildkite/pipeline.yaml`) actually runs.

Install JS dev dependencies (for prettier):

```bash
yarn
```

Validate the Docker Compose config:

```bash
cd docker-compose
docker-compose -f docker-compose.yaml config -q
```

Or via the CI wrapper from the repo root:

```bash
.buildkite/validate-docker-compose.sh
```

Format / check formatting (prettier, config in `prettier.config.js`):

```bash
yarn run prettier        # write
yarn run prettier-check  # check only
```

Run the Terraform/IaC security scan (Checkov):

```bash
.buildkite/ci-checkov.sh
```

## Testing

Smoke and upgrade tests run on GCP via Vagrant (see `TESTING.md`):

```bash
.buildkite/vagrant-run.sh docker-test   # TEST_TYPE=docker-compose-test
```

This starts a GCP instance, uploads the repo, and runs the docker-compose smoke test. Expected output: `docker-test: ALL TESTS PASSED`.

## Conventions

- Keep changes minimal and config-focused; this is a deployment reference consumed by customers.
- All `*.{js,json,ts,tsx,graphql,md,scss}` files are formatted with prettier — run `yarn run prettier` before committing.
- Shell scripts should pass shellcheck.
- Releases are driven by `release.yaml` and the `sg release` steps in `.buildkite/pipeline.yaml`; release branches use `internal/release-*` and `promote/release-*` naming.
