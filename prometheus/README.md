# Prometheus configuration

This directory contains configuration for the [Prometheus](https://prometheus.io/) metrics deployment.

This directory is mounted into the `prometheus` container. After making your changes to this directory,
simply `docker restart prometheus` for your changes to take effect (depending on your change, Prometheus
may respond to it as soon as you save the file).

You can add `_rules.yml` and `_targets.yml` files to this directory and they will be picked up automatically.

### Docker metrics scraping

To scrape Docker itself for metrics, add the following file depending on your host machine OS:

#### Linux

Inside the `prometheus` container, `localhost` is the container itself, so the target must name the host.

1. Set `"metrics-addr": "0.0.0.0:9323"` in `/etc/docker/daemon.json`, and restart Docker. Containers cannot reach a daemon which listens on `127.0.0.1:9323`.

2. Add the host's name to the `prometheus` service in your `docker-compose.override.yaml`:

   ```yaml
   services:
     prometheus:
       extra_hosts:
         - 'host.docker.internal:host-gateway'
   ```

3. Create `prometheus/docker_targets.yml`:

   ```yaml
   - labels:
       job: docker
     targets:
       - host.docker.internal:9323
   ```

#### Mac & Windows

Create `prometheus/docker_targets.yml`:

```yaml
- labels:
    job: docker
  targets:
    - host.docker.internal:9323
```
