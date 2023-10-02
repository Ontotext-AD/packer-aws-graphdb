#!/bin/bash

set -euxo pipefail

until ping -c 1 google.com &>/dev/null; do
  echo "waiting for outbound connectivity"
  sleep 5
done

timedatectl set-timezone UTC

# Shred authorized_keys
shred -u /root/.ssh/authorized_keys /home/ubuntu/.ssh/authorized_keys

# Install Tools
apt-get -o DPkg::Lock::Timeout=300 update -y
apt-get -o DPkg::Lock::Timeout=300 install -y bash-completion jq nvme-cli openjdk-11-jdk unzip

# Get the server architecture and corresponding AWS CLI
server_arch=$(uname -m)

if [[ "$server_arch" == "x86_64" ]]; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
elif [[ "$server_arch" == "aarch64" ]]; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
else
  echo "Unknown server architecture: $server_arch."
  exit 1
fi

unzip -q awscliv2.zip
./aws/install
rm -rf ./awscliv2.zip ./aws

# Create the GraphDB user
useradd --comment "GraphDB Service User" --create-home --system --shell /bin/bash --user-group graphdb

# Create GraphDB directories
mkdir -p /etc/graphdb \
         /etc/graphdb-cluster-proxy \
         /var/opt/graphdb/node \
         /var/opt/graphdb/cluster-proxy

# Download and install GraphDB
cd /tmp
curl -O https://maven.ontotext.com/repository/owlim-releases/com/ontotext/graphdb/graphdb/"${GRAPHDB_VERSION}"/graphdb-"${GRAPHDB_VERSION}"-dist.zip

unzip graphdb-"${GRAPHDB_VERSION}"-dist.zip
rm graphdb-"${GRAPHDB_VERSION}"-dist.zip
mv graphdb-"${GRAPHDB_VERSION}" /opt/graphdb-"${GRAPHDB_VERSION}"
ln -s /opt/graphdb-"${GRAPHDB_VERSION}" /opt/graphdb

chown -R graphdb:graphdb /etc/graphdb \
                         /etc/graphdb-cluster-proxy \
                         /opt/graphdb \
                         /opt/graphdb-${GRAPHDB_VERSION} \
                         /var/opt/graphdb

# Configure systemd for GraphDB and GraphDB proxy
mv /tmp/graphdb-cluster-proxy.service /lib/systemd/system/graphdb-cluster-proxy.service
mv /tmp/graphdb.service /lib/systemd/system/graphdb.service

systemctl daemon-reload
systemctl enable graphdb.service
systemctl start graphdb.service
