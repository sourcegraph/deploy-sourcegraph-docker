# Executors

Executors are Sourcegraph’s solution for running untrusted code in a secure and controllable way. For more information on executors and how they are used see the Executors [documentation](https://docs.sourcegraph.com/admin/executors)

## Deploying

This directory contains a compose file to deploy a Sourcegraph Executor.



```bash
docker-compose up -d executor.docker-compose.yaml
```