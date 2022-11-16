#!/usr/bin/env bash
set -euxo pipefail
###############################################################################
# ACTION REQUIRED: REPLACE THE URL AND REVISION WITH YOUR DEPLOYMENT REPO INFO
###############################################################################
# Please read the notes below the script if you are cloning a private repository
# Example: DEPLOY_SOURCEGRAPH_DOCKER_FORK_REVISION='v4.1.3'
DEPLOY_SOURCEGRAPH_DOCKER_FORK_REVISION="$1"
DEPLOY_SOURCEGRAPH_DOCKER_FORK_CLONE_URL="$2"
##################### NO CHANGES REQUIRED BELOW THIS LINE #####################
if [ "$2" = "" ]; then
    DEPLOY_SOURCEGRAPH_DOCKER_FORK_CLONE_URL='https://github.com/sourcegraph/deploy-sourcegraph-docker.git'
fi
DEPLOY_SOURCEGRAPH_DOCKER_CHECKOUT='/root/deploy-sourcegraph-docker'
DOCKER_DATA_ROOT='/mnt/docker-data'
DOCKER_COMPOSE_VERSION='1.29.2'
DOCKER_DAEMON_CONFIG_FILE='/etc/docker/daemon.json'
PERSISTENT_DISK_DEVICE_NAME='/dev/sda'
# Install git
sudo apt-get update -y
sudo apt-get install -y git
# Clone the deployment repository
git clone "${DEPLOY_SOURCEGRAPH_DOCKER_FORK_CLONE_URL}" "${DEPLOY_SOURCEGRAPH_DOCKER_CHECKOUT}"
cd "${DEPLOY_SOURCEGRAPH_DOCKER_CHECKOUT}"
git checkout "${DEPLOY_SOURCEGRAPH_DOCKER_FORK_REVISION}"
# Format (if unformatted) and then mount the attached volume
device_fs=$(sudo lsblk "${PERSISTENT_DISK_DEVICE_NAME}" --noheadings --output fsType)
if [ "${device_fs}" == "" ]; then
    sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard "${PERSISTENT_DISK_DEVICE_NAME}"
fi
sudo mkdir -p "${DOCKER_DATA_ROOT}"
sudo mount -o discard,defaults "${PERSISTENT_DISK_DEVICE_NAME}" "${DOCKER_DATA_ROOT}"
# Mount file system by UUID on reboot
DISK_UUID=$(sudo blkid -s UUID -o value "${PERSISTENT_DISK_DEVICE_NAME}")
sudo echo "UUID=${DISK_UUID}  ${DOCKER_DATA_ROOT}  ext4  discard,defaults,nofail  0  2" >>'/etc/fstab'
sudo umount "${DOCKER_DATA_ROOT}"
sudo mount -a
# Install, configure, and enable Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update -y
apt-cache policy docker-ce
apt-get install -y docker-ce docker-ce-cli containerd.io
## Enable Docker at startup
sudo systemctl enable --now docker
# Install jq for scripting
sudo apt-get update -y
sudo apt-get install -y jq
## Initialize the config file with empty json if it doesn't exist
if [ ! -f "${DOCKER_DAEMON_CONFIG_FILE}" ]; then
    mkdir -p $(dirname "${DOCKER_DAEMON_CONFIG_FILE}")
    echo '{}' >"${DOCKER_DAEMON_CONFIG_FILE}"
fi
## Point Docker storage to mounted volume
tmp_config=$(mktemp)
trap "rm -f ${tmp_config}" EXIT
sudo cat "${DOCKER_DAEMON_CONFIG_FILE}" | sudo jq --arg DATA_ROOT "${DOCKER_DATA_ROOT}" '.["data-root"]=$DATA_ROOT' >"${tmp_config}"
sudo cat "${tmp_config}" >"${DOCKER_DAEMON_CONFIG_FILE}"
## Restart Docker daemon to pick up new changes
sudo systemctl restart --now docker
# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
curl -L "https://raw.githubusercontent.com/docker/compose/${DOCKER_COMPOSE_VERSION}/contrib/completion/bash/docker-compose" -o /etc/bash_completion.d/docker-compose
# Start Sourcegraph with Docker Compose
cd "${DEPLOY_SOURCEGRAPH_DOCKER_CHECKOUT}"/docker-compose
docker-compose up -d --remove-orphans
