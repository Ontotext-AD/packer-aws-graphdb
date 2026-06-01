#!/usr/bin/env bash

set -euxo pipefail

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

unzip -q graphdb-"${GRAPHDB_VERSION}"-dist.zip
rm graphdb-"${GRAPHDB_VERSION}"-dist.zip
mv graphdb-"${GRAPHDB_VERSION}" /opt/graphdb-"${GRAPHDB_VERSION}"
ln -s /opt/graphdb-"${GRAPHDB_VERSION}" /opt/graphdb

mv /tmp/graphdb.env /etc/graphdb/graphdb.env
mv /tmp/graphdb-cluster-proxy.env /etc/graphdb/graphdb-cluster-proxy.env

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
