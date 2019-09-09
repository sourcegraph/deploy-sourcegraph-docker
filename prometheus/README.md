# Prometheus configuration

This directory contains configuration for the [Prometheus](https://prometheus.io/) metrics deployment.

This directory is mounted into the `prometheus` container. After making your changes to this directory,
simply `docker restart prometheus` for your changes to take effect (depending on your change, Prometheus
may respond to it as soon as you save the file).

You can add `_rules.yml` and `_targets.yml` files to this directory and they will be picked up automatically.
For example see below on how to add a target for docker itself.

### Docker metrics scraping
 
To scrape Docker itself for metrics, add the following file depending on your host machine OS:

#### Linux

Create `prometheus/docker_targets.yml`:

#### Linux

```yaml
- labels:
    job: docker
  targets:
    - localhost:9323
 ```

#### Mac & Windows

Create `prometheus/docker_targets.yml`:

```yaml
- labels:
    job: docker
  targets:
    - host.docker.internal:9323
```
