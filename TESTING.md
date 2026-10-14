# Testing

Developers can test using [Vagrant](https://www.vagrantup.com) and your
Sourcegraph GCP account.

Install [Vagrant](https://www.vagrantup.com/docs/index) on your local machine,
then install the required plugin:

```sh
vagrant plugin install vagrant-google
```

Ensure your credentials are correct by executing the command below and
following the prompts:

```sh
gcloud auth application-default login
```

Configure your local variables using the following environment variables:

- `VAGRANT_GCP_PROJECT_ID`: Project to run on. (default: `sourcegraph-server`)
- `VAGRANT_SSH_USER`: Your SSH user ID as specified in GCP metadata.
  (default: `ENV['USER']`)
- `VAGRANT_SSH_KEY`: Path to your SSH keys as specified in GCP metadata.
  (default: `~/.ssh/id_rsa`)

```sh
.buildkite/vagrant-run.sh docker-test
```

This command will start a GCP instance, upload your local copy of the
repository and run the Docker Compose smoke test.

To run any additional tests or commands, edit `test/servers.yaml` and add the
commands to the `shell_commands` list, eg:

```yaml
shell_commands:
    - [...]
    - /vagrant/moretests.sh
    - "ps aux | grep thisthat"
    - |
      cd /vagrant
      bartest.sh
```

## Smoke test: ensure Docker Compose upgrades work

Start the prior version of Docker Compose:

```sh
git checkout <previous_version_tag>
cd test/
vagrant up docker-test
```

Wait for the test to pass and for the output (approximately 5-10 minutes):

```text
docker-test: ALL TESTS PASSED
```

Update to the latest version:

```sh
git checkout main
vagrant provision docker-test
```

Wait for the test to pass and for the output (approximately 5-10 minutes):

```text
docker-test: ALL TESTS PASSED
```
