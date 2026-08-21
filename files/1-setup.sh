#!/usr/bin/env bash

set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

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
APT_OPTS=(-o DPkg::Lock::Timeout=300 -o Acquire::Retries=3 -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30)

apt-get "${APT_OPTS[@]}" update -y
apt-get "${APT_OPTS[@]}" install -y bash-completion jq nvme-cli temurin-21-jdk unzip

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

rm -rf ./aws
unzip -q awscliv2.zip
./aws/install --update
rm -rf ./awscliv2.zip ./aws

/usr/local/bin/aws --version

dpkg -i -E ./amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

# Copy the prometheus and cloudwatch configurations
mkdir -p /etc/prometheus || true
cp /tmp/prometheus.yaml /etc/prometheus/prometheus.yaml
mkdir -p /etc/graphdb/ || true
cp /tmp/cloudwatch-agent-config.json /etc/graphdb/cloudwatch-agent-config.json

# Disable the agent by default, should be enabled explicitly in the EC2 if needed.
amazon-cloudwatch-agent-ctl -a stop
