# Docker Compose Examples

## Best Practices

These best practices reduce the operational cost of keeping your Sourcegraph instance up to date, and are consistent across the customers we see keeping up to date at low cost, with happy users, vs customers who are often many versions behind, with users asking, "Hey, where's the new features?"

- All of your customizations should be in one docker-compose.override.yaml file, applied on top of one or more unmodified base docker-compose.yaml file(s) from this deploy-sourcegraph-docker repo

- Your docker-compose.override.yaml file should be stored, maintained, and fetched from a Git repo / code version control system, with meaningful commit messages, so that future you, and future admins, can understand why changes needed to be made

    - Bonus points if your override file is stored outside of your clone of this deploy-sourcegraph-docker repo, so that this deploy-sourcegraph-docker repo can be deleted / recreated / `git reset --hard` as needed, without losing your customizations

- The examples in this directory use the current compose syntax, used by `docker compose`, the docker-compose-plugin. Some parts of this syntax may not be valid for the old `docker-compose` standalone binary. It is highly recommended to switch to using the new compose plugin. See Docker docs:

    - Install Compose plugin
        - https://docs.docker.com/compose/install

    - Merging multiple compose files
        - https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/
        - https://docs.docker.com/reference/compose-file/merge/#reset-value

- Using multiple compose / override files

    - Old method:

        - Store your docker-compose.override.yaml file inside this deploy-sourcegraph-docker repo, under the /docker-compose directory

        - `docker compose -f docker-compose.yaml -f executors/executor.docker-compose.yaml -f docker-compose.override.yaml up -d --remove-orphans`

    - New method:

        - Store your docker-compose.override.yaml file in the parent directory / beside this deploy-sourcegraph-docker repo

        - Create an `.env` file, containing the below

        - `docker compose up -d --remove-orphans`

        - Note that any file paths (ex. mounting TLS CAs) are relative to the first compose file, so the mount path will likely start with `../../cert-chain.pem` if `cert-chain.pem` is in the parent directory / beside this deploy-sourcegraph-docker repo

```env
SOURCEGRAPH=./deploy-sourcegraph-docker/docker-compose/docker-compose.yaml
EXECUTORS=./deploy-sourcegraph-docker/docker-compose/executors/executor.docker-compose.yaml
OVERRIDE=./docker-compose.override.yaml

COMPOSE_FILE=${SOURCEGRAPH}:${EXECUTORS}:${OVERRIDE}
```
