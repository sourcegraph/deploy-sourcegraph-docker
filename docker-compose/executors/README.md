# Executors

Executors are Sourcegraph’s solution for running untrusted code in a secure and controllable way. For more information on executors and how they are used see the Executors [documentation](https://docs.sourcegraph.com/admin/executors)

## Deploying

This directory contains a compose file to deploy a Sourcegraph Executor.

NOTE: Executors require privileged access in order to run correctly on docker-compose based deployments.

To learn more visit TODO

To run this as part of a Sourcegraph deployment on the machine machine, execute the following command from the `docker-compose` directory:

```bash
docker-compose -f docker-compose.yaml -f executors/executor.docker-compose.yaml up -d
```

To run this on a standalone machine, execute the following from the `executors` directory

```bash
docker-compose up -d executor.docker-compose.yaml
```