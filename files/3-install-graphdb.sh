#!/usr/bin/env bash

set -euxo pipefail

# Create the GraphDB user (skip if a provisioner retry already created it)
id -u graphdb &>/dev/null || useradd --comment "GraphDB Service User" --create-home --system --shell /bin/bash --user-group graphdb

# Create GraphDB directories
mkdir -p /etc/graphdb \
         /etc/graphdb-cluster-proxy \
         /var/opt/graphdb/node \
         /var/opt/graphdb/cluster-proxy

# Download and install GraphDB (skip if a provisioner retry already installed it,
# since the source dist dir is consumed by the mv below and can't be moved twice)
if [[ ! -d /opt/graphdb-${GRAPHDB_VERSION} ]]; then
  cd /tmp
  curl -O https://maven.ontotext.com/repository/owlim-releases/com/ontotext/graphdb/graphdb/"${GRAPHDB_VERSION}"/graphdb-"${GRAPHDB_VERSION}"-dist.zip

  unzip -q graphdb-"${GRAPHDB_VERSION}"-dist.zip
  rm graphdb-"${GRAPHDB_VERSION}"-dist.zip
  mv graphdb-"${GRAPHDB_VERSION}" /opt/graphdb-"${GRAPHDB_VERSION}"
fi
ln -sfn /opt/graphdb-"${GRAPHDB_VERSION}" /opt/graphdb

cp /tmp/graphdb.env /etc/graphdb/graphdb.env
cp /tmp/graphdb-cluster-proxy.env /etc/graphdb/graphdb-cluster-proxy.env

chown -R graphdb:graphdb /etc/graphdb \
                         /etc/graphdb-cluster-proxy \
                         /opt/graphdb \
                         /opt/graphdb-${GRAPHDB_VERSION} \
                         /var/opt/graphdb

# Configure systemd for GraphDB and GraphDB proxy
cp /tmp/graphdb-cluster-proxy.service /lib/systemd/system/graphdb-cluster-proxy.service
cp /tmp/graphdb.service /lib/systemd/system/graphdb.service

systemctl daemon-reload
systemctl enable graphdb.service
systemctl start graphdb.service

# Clean up the config/unit files staged in /tmp by the packer file provisioner.
# Safe ONLY because this is the last line of the last provisioner script: if a
# later step fails, the shell provisioner retries the whole chain from
# 1-setup.sh, and 1-setup.sh/3-install-graphdb.sh's cp's need these files still
# in /tmp to be retry-safe. If you add steps after this block (here or in a new
# script appended to build.pkr.hcl's scripts list), move this cleanup to run
# after them instead, or the next retry will fail on a missing cp source again.
rm -f /tmp/prometheus.yaml /tmp/cloudwatch-agent-config.json \
      /tmp/graphdb.env /tmp/graphdb-cluster-proxy.env \
      /tmp/graphdb.service /tmp/graphdb-cluster-proxy.service
