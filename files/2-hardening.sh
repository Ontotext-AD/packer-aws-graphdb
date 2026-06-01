#!/usr/bin/env bash

set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get -o DPkg::Lock::Timeout=300 -y full-upgrade
apt-get -o DPkg::Lock::Timeout=300 -y install --only-upgrade kmod linux-image-virtual || true
apt-get -o DPkg::Lock::Timeout=300 -y autoremove
apt-get -o DPkg::Lock::Timeout=300 -y clean

cat >/etc/modprobe.d/99-hardening-blocklist.conf <<'EOF'
# Copy Fail
install algif_aead /bin/false
blacklist algif_aead

# Dirty Frag
install esp4 /bin/false
blacklist esp4
install esp6 /bin/false
blacklist esp6
install rxrpc /bin/false
blacklist rxrpc
EOF

for m in algif_aead esp4 esp6 rxrpc; do
  rmmod "$m" 2>/dev/null || true
done

update-initramfs -u -k all
