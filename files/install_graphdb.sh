#!/bin/bash

set -euxo pipefail

until ping -c 1 google.com &>/dev/null; do
  echo "waiting for outbound connectivity"
  sleep 5
done

timedatectl set-timezone UTC

# Temurin setup
echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print $2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
mkdir -p /etc/apt/keyrings
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc

# Install Tools
apt-get -o DPkg::Lock::Timeout=300 update -y
apt-get -o DPkg::Lock::Timeout=300 install -y bash-completion jq nvme-cli temurin-21-jdk unzip
snap install yq

# Get the server architecture and corresponding AWS CLI
server_arch=$(uname -m)

if [[ "$server_arch" == "x86_64" ]]; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  curl "https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb" -o "amazon-cloudwatch-agent.deb"
elif [[ "$server_arch" == "aarch64" ]]; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
  curl "https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/arm64/latest/amazon-cloudwatch-agent.deb" -o "amazon-cloudwatch-agent.deb"
else
  echo "Unknown server architecture: $server_arch."
  exit 1
fi

unzip -q awscliv2.zip
./aws/install
rm -rf ./awscliv2.zip ./aws

dpkg -i -E ./amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

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

mv /tmp/graphdb.env /etc/graphdb/graphdb.env

chown -R graphdb:graphdb /etc/graphdb \
                         /etc/graphdb-cluster-proxy \
                         /opt/graphdb \
                         /opt/graphdb-${GRAPHDB_VERSION} \
                         /var/opt/graphdb

# Configure systemd for GraphDB and GraphDB proxy
mv /tmp/graphdb-cluster-proxy.service /lib/systemd/system/graphdb-cluster-proxy.service
mv /tmp/graphdb.service /lib/systemd/system/graphdb.service

# Move the prometheus and cloudwatch configurations
mkdir "/etc/prometheus"
mv /tmp/prometheus.yaml /etc/prometheus/prometheus.yaml
mv /tmp/cloudwatch-agent-config.json /etc/graphdb/cloudwatch-agent-config.json
# Disable the agent by default, should be enabled explicitly in the EC2 if needed.
amazon-cloudwatch-agent-ctl -a stop

systemctl daemon-reload
systemctl enable graphdb.service
systemctl start graphdb.service
