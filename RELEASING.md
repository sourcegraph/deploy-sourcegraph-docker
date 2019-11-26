# Releasing a new version

If for example deploy-sourcegraph-docker's last release was v3.8.2 and you are releasing v3.9.2:

1. Locate the latest `master` commit that correlates with the 3.9 release branch cut date.
2. `git checkout <commit> && git checkout -B 3.9 && git push` to create the release branch here.
3. Commit all relevant changes upstream on deploy-sourcegraph here, e.g. by viewing the diff at https://github.com/sourcegraph/deploy-sourcegraph/compare/v3.8.2..v3.9.2
4. `git tag v3.9.2 && git push origin v3.9.2`

Then for smoke testing & customer replication please also:

- `git checkout 3.8-customer-replica`
- `git checkout -B 3.9-customer-replica`
- `git merge 3.9` -> fix conflicts manually -> `git commit && git push --set-upstream origin 3.9-customer-replica`
- `git tag customer-replica-v3.9.2 && git push origin customer-replica-v3.9.2`
- Proceed with testing on customer replica environment: https://github.com/sourcegraph/infrastructure
- Check diff before sending it to customers as it is often applied by hand: https://github.com/sourcegraph/deploy-sourcegraph-docker/compare/customer-replica-v3.8.2..customer-replica-v3.9.2

## Branches & tags

Just like deploy-sourcegraph, we use version branches and version tags. We _additionally_ have a second set which is customer-replication branches and version tags:

- Tag examples: `v3.8.2`, `v3.9.2`, `customer-replica-v3.8.2`, `customer-replica-v3.9.2-2`
- Branch examples: `3.8`, `3.9`, `3.8-customer-replica`, `3.9-customer-replica`

The customer replica ones are important as we must maintain some diffs for replication purposes, such as using a different Postgres version, changes to the `prometheus_targets.yml` and more. We use tags to ensure each AMI we save correlates directly with an immutable Git tag.
