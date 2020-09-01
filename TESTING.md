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

- Run the tests
```
.buildkite/test-pure-docker.sh
```

This command will start a GCP instance, upload your local copy of the reposistory and run a [smoke test](test/pure-docker/smoke-test.sh).

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
