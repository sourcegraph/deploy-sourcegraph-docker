# deploy-sourcegraph-docker metrics

This deployment mode of Sourcegraph features metrics that are a staple in other cluster Sourcegraph deployments:

- [Jaeger tracing](https://www.jaegertracing.io/), for getting exact details on specific requests.
- [Grafana](https://grafana.com/) and [Prometheus](https://prometheus.io), for dashboards with nice high-level insight into Sourcegraph ([it can also send alerts](http://docs.grafana.org/alerting/rules/), although we are not aware of anyone using it for that yet).

### A brief note about security

It is your responsibility to ensure that Jaeger, Grafana, and Prometheus are only accessible by admins. In specific, you will want a way for admins to access:

- jaeger-query HTTP port 16686.
- grafana HTTP port 3000.
- prometheus HTTP port 9090.

This is due to the fact that these services (in particular, Jaeger) record details about HTTP queries, which may contain sensitive information.

# Jaeger tracing

Jaeger tracing allows you to grab a detailed trace for any HTTP request that goes through Sourcegraph. It can provide us critical information like:

- What operations occurred behind the scenes?
- How long did those operations take?
- What errors occurred while performing those operations?
- etc.

![image](https://user-images.githubusercontent.com/3173176/55772329-91152680-5a40-11e9-82ea-e29def753266.png)

To use Jaeger after running `deploy.sh`:

1. Visit jaeger-query in a browser (e.g. at http://localhost:16686) and confirm there are no errors displayed on the home page (you should just see a stern-looking Gopher with a hat).
   - If there are errors, you may need to wait a few minutes for Jaeger's Cassandra database to initialize if it is the first time you are running this. It can take around 5 minutes.
   - Consult `docker ps | grep jaeger` until all containers have started.
2. In the Sourcegraph management console, set `"useJaeger": true`, then restart all Sourcegraph services. This will cause Sourcegraph's services to begin sending tracing information to Jaeger. It is safe (and highly recommended) to run this in production.

### Acquiring traces

Every HTTP response sent by Sourcegraph will have a header like `X-Trace: 5023c9288d9d4797`. This trace ID can be put into Jaeger to view the trace.

# Grafana and Prometheus

Grafana queries Prometheus to provide dashboards with high-level insight into Sourcegraph. (It can also provide alerting on specific metrics, if desired):

![image](https://user-images.githubusercontent.com/3173176/55769416-9751d580-5a35-11e9-892d-198b02bb3663.png)

To use Grafana and Prometheus after running `deploy.sh`:

1. If you have multiple replicas of searcher/gitserver/etc, open `prometheus/prometheus_targets.yml` in an editor and duplicate lines as needed so that Prometheus knows to scrape those services for metrics. Save the file, then `docker restart prometheus` to apply the changes.
1. Visit grafana in a browser (e.g. at http://localhost:3000) and sign in using the default credentials `admin` > `admin`.
1. Add Prometheus as a data source: **Gear icon** > **Data sources** > **Add data source** > **Prometheus** > enter the Prometheus URL (e.g. `http://localhost:9090` on Linux or `http://docker.for.mac.localhost:9090` on Mac).
1. You can now visit any dashboards via: **Dashboard icon** > **Home** > **Home dropdown in top-left** > **<the dashboard>**.

### Sourcegraph standard dashboards

The deployment comes with a set of standard dashboards for monitoring Sourcegraph:

- **Overview** - high level overview of how Sourcegraph is performing
- **Containers** - insight into Docker containers themselves (memory, CPU, open file descriptors, etc). Requires additional configuratoin, see below.
- **HTTP** - insight into end-user HTTP requests (i.e. excluding interservice communication)
- **Searcher** - detailed insight into the searcher service
- **Gitserver** - detailed insight into the gitserver service

The JSON for these dashboards is located in the `grafana/provisioning/sourcegraph` directory. It is intended that thes are maintained by Sourcegraph and will recieve regular updates (you will get updates on redeploy, no need to do anything special).

If there are specific dashboards or metrics you'd like to see, please [file an issue](https://github.com/sourcegraph/sourcegraph/issues) to let us know!

### Container metrics

The `Containers` dashboard metrics come from Docker itself. In order to expose these metrics to Prometheus, you will need to:

1. Flip a bit in the Docker config to expose its Prometheus metrics exporter: https://docs.docker.com/config/thirdparty/prometheus/#configure-docker
2. Uncomment the relevant `job_name: docker` line at the end of `prometheus/prometheus_targets.yml` for your OS.
3. `docker restart prometheus` to make the changes take effect.
4. To confirm the above worked, you can run a Prometheus query [like this](http://localhost:9090/graph?g0.range_input=1h&g0.expr=process_resident_memory_bytes&g0.tab=0) or visit the `Containers` dashboard in Grafana.
