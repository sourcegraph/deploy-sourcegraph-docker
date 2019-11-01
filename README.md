# Pure-Docker Sourcegraph cluster deployment reference

[![sourcegraph: search](https://img.shields.io/badge/sourcegraph-search-brightgreen.svg)](https://sourcegraph.com/github.com/sourcegraph/deploy-sourcegraph-docker)

There are two recommended ways to deploy Sourcegraph:

- [Single-machine Docker deployment](https://docs.sourcegraph.com/admin/install/docker)
- [Multi-machine Kubernetes deployment](https://docs.sourcegraph.com/admin/install/kubernetes_cluster)

But what if your organization wants a multi-machine deployment without using Kubernetes? What if you use a different container management platform, for example? This project aims to solve that, by providing a pure-Docker deployment option.

The goal is that anyone using a container management platform other than Kubernetes (Netflix's [Titus](https://netflix.github.io/titus/), Apache's [Mesos](http://mesos.apache.org/documentation/latest/docker-containerizer/), etc.) would be able to use this repository as a reference for how to deploy Sourcegraph.

## Deploying

First clone the repository, then:

```bash
./deploy.sh
```

Visit http://localhost:3080 to visit the running Sourcegraph instance!

## Tearing down the deployment

```bash
./teardown.sh
```

## System topology

To understand the system topology:

1. Look at `deploy.sh` to get an overview of services.
2. Every service (`deploy-*.sh`) has documentation inline indicating:
   - What the service does / provides.
   - What ports the service exposes.
   - What other services it talks to (see environment variables).

## Service system requirements

Every service (`deploy-*.sh`) documents inline what the system requirements are (CPU/Memory/Disk allocation). For example, [the frontend service](https://github.com/sourcegraph/deploy-sourcegraph-docker/blob/f01b97a397138dd76e5f5ed45b2574b9a2e70cd1/deploy-frontend.sh#L6-L9).

## Scaling / replicas

To scale the cluster deployment, you will need to:

1. Deploy more instances of `gitserver`, `indexed-search`, `searcher` and `symbols` services as desired.
2. [Configure the `frontend` and `frontend-internal` to communicate with the new instances.](https://github.com/sourcegraph/deploy-sourcegraph-docker/blob/f01b97a397138dd76e5f5ed45b2574b9a2e70cd1/deploy-frontend.sh#L31-L34)
3. You're done! You do not need to configure or restart any other services.

## Metrics and Tracing

This deployment comes with metrics and tracing built-in. See [metrics and tracing](metrics-and-tracing.md) for details.

## Configuring HTTPS

See https://docs.sourcegraph.com/admin/nginx#nginx-for-other-sourcegraph-clusters-e-g-pure-docker

## Configuring SSH cloning

1. Ensure your **Site admin** > **External services** code host configuration is configured to use SSH. For example, by setting the [`gitURLType`](https://docs.sourcegraph.com/admin/site_config/all#giturltype-string-enum) field to `"ssh"`. You may still need to configure an access token or other codehost authentication method in order for Sourcegraph to discover your repositories.

Alternatively, you may use the `OTHER` codehost type under **External services**, which allows you to directly specify Git repository URLs for cloning.

2. Provide your `gitserver` instances with your SSH / Git configuration (usually just `.ssh/id_rsa`, `.ssh/id_rsa.pub`, and `.ssh/known_hosts` -- but you can also provide other files like `.netrc`, `.gitconfig`, etc. if needed) by mounting it into the `sourcegraph` users home directory in the `gitserver` containers. For example, by adding the following flag:

```
-v ~/my-sourcegraph-ssh-config/.ssh:/home/sourcegraph/.ssh
```

All future Git cloning operations will use the credentials configured there.

If you wish, you can test that cloning with your configuration is working by performing the clone in a gitserver container shell, e.g. first acquire shell access:

```
$ docker exec -it gitserver-0 sh
```

Then try cloning the repository:

```
$ git clone ssh://git@myhost.com/my/repo /tmp/my-repo
```

## Questions

[Open an issue](https://github.com/sourcegraph/deploy-sourcegraph-docker/issues/new) or contact us (support@sourcegraph.com), we are happy to answer any questions!
