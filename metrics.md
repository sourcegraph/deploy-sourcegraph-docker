# deploy-sourcegraph-docker metrics

This deployment mode of Sourcegraph features metrics that are a staple in other cluster Sourcegraph deployments:

- [Jaeger tracing](https://www.jaegertracing.io/), for getting exact details on specific requests.
- [Grafana](https://grafana.com/) and [Prometheus](https://prometheus.io), for dashboards with nice high-level insight into Sourcegraph.

# A brief note about security

It is your responsibility to ensure that Jaeger, Grafana, and Prometheus are only accessible by admins. In specific, you will want a way for admins to access:

- jaeger-query HTTP port 16686.
- grafana HTTP port 3000.
- prometheus HTTP port 9090.

This is due to the fact that these services (in particular, Jaeger) record details about HTTP queries, which may contain sensitive information.

# Jaeger tracing

Jaeger tracing allows you to grab a detailed trace for any HTTP request that goes through Sourcegraph. It can provide us critical information like:

- What operations occurred behind the scenes?
- How long did certain operations behind the scenes take?
- What errors occurred when doing something?
- etc.




# Grafana and Prometheus

Grafana queries Prometheus to provide dashboards with high-level insight into Sourcegraph. (It can also provide alerting on specific metrics, if desired):

![image](https://user-images.githubusercontent.com/3173176/55769416-9751d580-5a35-11e9-892d-198b02bb3663.png)

To use Grafana and Prometheus in this deployment type after running `deploy.sh`:

1. Visit http://localhost:3000 in a browser and sign in using the default credentials `admin` > `admin`.
2. Add Prometheus as a data source: **Gear icon** > **Data sources** > **Add data source** > **Prometheus** > enter the Prometheus URL (e.g. `http://localhost:9090` on Linux or `http://docker.for.mac.localhost:9090` on Mac).
3. You can now visit any dashboards via: **Dashboard icon** > **Home** > **Home dropdown in top-left** > **<the dashboard>**.

## Sourcegraph standard dashboards

The deployment comes with a set of standard dashboards for monitoring Sourcegraph:

- **Overview** - high level overview of how Sourcegraph is performing
- **Containers** - insight into Docker containers themselves (memory, CPU, open file descriptors, etc). Requires additional configuratoin, see below.
- **HTTP** - insight into end-user HTTP requests (i.e. excluding interservice communication)
- **Searcher** - detailed insight into the searcher service
- **Gitserver** - detailed insight into the gitserver service

The JSON for these dashboards is located in the `grafana/provisioning/sourcegraph` directory. It is intended that thes are maintained by Sourcegraph and will recieve regular updates (you will get updates on redeploy, no need to do anything special).

If there are specific dashboards or metrics you'd like to see, please [file an issue](https://github.com/sourcegraph/sourcegraph/issues) to let us know!

## Container metrics

The `Containers` dashboard metrics come from Docker itself. In order to expose these metrics to Prometheus, you will need to:

1. Flip a bit in the Docker config to expose its Prometheus metrics exporter: 

Container prometheus metrics are exposed by Docker itself.
