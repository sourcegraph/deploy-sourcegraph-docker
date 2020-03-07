# Sourcegraph for docker-compose

This folder contains a Sourcegraph docker-compose deployment.

**NOTE:** This is early access and slated for release in Sourcegraph v3.12; the missing components today are primarily documentation. Please contact us (support@sourcegraph.com) if you are looking at using this in production so we can assist you.

## Deploying

Simply clone the repository and `docker-compose up -d` to deploy Sourcegraph:

```sh
git clone https://github.com/sourcegraph/deploy-sourcegraph-docker
cd deploy-sourcegraph-docker/docker-compose/
git checkout v3.12.3
docker-compose up -d
```

Sourcegraph will then run in the background and across server restarts.

Notes:

- The `docker-compose.yaml` file currently depends on configuration files which live in the repository, as such you must have the repository cloned onto your server.
- Data for all services will be stored as docker volumes.
- Use `docker ps` to inspect the Sourcegraph containers, and `docker-compose down` to teardown the deployment.

## Upgrading

When a new version of Sourcegraph is released, you will simply checkout that version in this repository and redeploy:

```sh
cd deploy-sourcegraph-docker/docker-compose
git pull
git checkout NEW_VERSION
docker-compose down
docker-compose up -d
```

## src-expose on ec2

A guide for src-expose on ec2. Please read the shell script below, it contains
comments explaining what to do. Once fully ready, run through it.

``` sh
# Setup deploy-sourcegraph
cd ~
git clone https://github.com/sourcegraph/deploy-sourcegraph-docker
cd deploy-sourcegraph-docker/docker-compose/
git checkout core/src-expose

# Install src-expose into /usr/local/bin
wget https://storage.googleapis.com/sourcegraph-artifacts/src-expose/latest/linux-amd64/src-expose
chmod +x src-expose
sudo mv src-expose /usr/local/bin/src-expose

# src-expose will export ~/export/dir1 ~/export/dir2 ~/export/dir3
# Modify src-expose.service to adjust the behaviour. See https://github.com/sourcegraph/sourcegraph/pull/5835/files for some documentation on src-expose.
mkdir -p ~/export/dir{1,2,3}

# Install the systemd service files
sudo cp sourcegraph.service src-expose.service /etc/systemd/system/
sudo systemctl start sourcegraph src-expose
sudo systemctl enable sourcegraph src-expose

# Check the status of the jobs
sudo systemctl status sourcegraph src-expose
```

After everything is running you will need to configure Sourcegraph to connect to src-expose. You need to find the IP docker can use to connect to the host (where src-expose is running). I did this by running "route". For example the default route indicates it is "172.20.0.1" when I tried:

``` shellsession
$ docker exec repo-updater route
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
default         ip-172-20-0-1.u 0.0.0.0         UG    0      0        0 eth0
172.20.0.0      *               255.255.0.0     U     0      0        0 eth0
```

Using this IP you add an external service to communicate with src-expose:

``` javascript
{
  // url is the http url to src-expose (listening on 127.0.0.1:3434)
  // url should be reachable by Sourcegraph.
  // 172.20.0.1 is the IP I found when testing.
  "url": "http://172.20.0.1:3434",
  "repos": [
    "src-expose"
  ] // This may change in versions later than 3.9
}
```

Go to Admin > External services > Add external service > Single Git
repositories. Input the above configuration. Your directories should now be
syncing in Sourcegraph.
