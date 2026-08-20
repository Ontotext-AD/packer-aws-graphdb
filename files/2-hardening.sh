#!/usr/bin/env bash

set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

APT_OPTS=(-o DPkg::Lock::Timeout=300 -o Acquire::Retries=3 -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30)

apt-get "${APT_OPTS[@]}" -y full-upgrade
apt-get "${APT_OPTS[@]}" -y install --only-upgrade kmod linux-image-virtual || true
apt-get "${APT_OPTS[@]}" -y autoremove
apt-get "${APT_OPTS[@]}" -y clean

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
