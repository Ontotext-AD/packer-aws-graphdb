#!/bin/bash

set -euxo pipefail

until ping -c 1 google.com &> /dev/null; do
  echo "waiting for outbound connectivity"
  sleep 5
done

timedatectl set-timezone UTC

# 1. Install Tools
#apt-get update -y 
apt update && apt upgrade -y
apt-get -o DPkg::Lock::Timeout=300 install -y unzip jq nvme-cli openjdk-11-jdk bash-completion

# Create the GraphDB user
useradd --comment "GraphDB Service User" --create-home --system --shell /bin/bash --user-group graphdb

# Create GraphDB directories
mkdir -p /var/opt/graphdb/data /var/opt/graphdb/logs /etc/graphdb /etc/graphdb-cluster-proxy /var/opt/graphdb-cluster-proxy/logs

cd /tmp
curl -O https://maven.ontotext.com/repository/owlim-releases/com/ontotext/graphdb/graphdb/"${GRAPHDB_VERSION}"/graphdb-"${GRAPHDB_VERSION}"-dist.zip

unzip graphdb-"${GRAPHDB_VERSION}"-dist.zip
rm graphdb-"${GRAPHDB_VERSION}"-dist.zip
mv graphdb-"${GRAPHDB_VERSION}" /opt/graphdb-"${GRAPHDB_VERSION}"
ln -s /opt/graphdb-"${GRAPHDB_VERSION}" /opt/graphdb

chown -R graphdb:graphdb /var/opt/graphdb/data /var/opt/graphdb/logs /etc/graphdb /opt/graphdb /opt/graphdb-${GRAPHDB_VERSION} /etc/graphdb-cluster-proxy /var/opt/graphdb-cluster-proxy/logs

mv /tmp/graphdb.properties /etc/graphdb/graphdb.properties
mv /tmp/graphdb-cluster-proxy.service /lib/systemd/system/graphdb-cluster-proxy.service
mv /tmp/graphdb.service /lib/systemd/system/graphdb.service

systemctl daemon-reload

systemctl enable graphdb.service
systemctl start graphdb.service
