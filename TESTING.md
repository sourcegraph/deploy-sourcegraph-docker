## Testing

Developers can test using [Vagrant](https://www.vagrantup.com) and your Sourcegraph GCP account.

- Use [these](https://www.vagrantup.com/docs/index) instructions to install `Vagrant` on your local machine. Once sucessfully installed, install the required plugin:
```
vagrant plugin install vagrant-google
```

- Ensure your credentials are correct by excecuting the command below and following the prompts:
```
gcloud auth application-default login
```

- Configure your local variables using the following environment variables
  - `VAGRANT_GCP_PROJECT_ID`: Project to run on. (default: `sourcegraph-server`)
  - `VAGRANT_SSH_USER`: Your SSH user ID as specified in GCP metadata. (default: `ENV['USER']`)
  - `VAGRANT_SSH_KEY`: Path to your SSH Keys as specified in GCP metadata. (default: `~/.ssh/id_rsa`)
  - `TEST_TYPE`:  Deployment type to test, `pure-docker-test` or `docker-compose-test`.
```
.buildkite/vagrant-run.sh docker-test
```

This command will start a GCP instance, upload your local copy of the reposistory and run the relevant smoke test for each deployment type, [pure-docker-test](test/pure-docker/smoke-test.sh) or [docker-compose-test](test/docker-compose/smoke-test.sh).

To run any additional tests or commands, edit [servers.yaml](test/pure-docker/servers.yaml) and add the commands to the `shell_commands` list, eg:
```
shell_commands:
    - [...]
    - /vagrant/moretests.sh
    - "ps aux | grep thisthat"
    - |
      cd /vagrant
      bartest.sh
```
<<<<<<< HEAD
=======
### Smoke test: ensure Docker Compose upgrades work

Start the prior version of Docker Compose:

```
git checkout <previous_version_branch>
cd test/
TEST_TYPE=docker-compose-test vagrant up docker-test 
```

Wait for the test to pass and for the output (approximately 5-10 minutes):

```
docker-test: ALL TESTS PASSED
```

Update to the latest version:

```
git checkout master
TEST_TYPE=docker-compose-test vagrant provision docker-test
```

Wait for the test to pass and for the output (approximately 5-10 minutes):

```
docker-test: ALL TESTS PASSED
```
>>>>>>> 3.24
