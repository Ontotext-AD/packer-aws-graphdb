#!/usr/bin/env bash

set -euxo pipefail

until ping -c 1 google.com &> /dev/null; do
  echo "waiting for outbound connectivity"
  sleep 5
done

# Set common variables used throughout the script.
imds_token=$( curl -Ss -H "X-aws-ec2-metadata-token-ttl-seconds: 300" -XPUT 169.254.169.254/latest/api/token )
instance_id=$( curl -Ss -H "X-aws-ec2-metadata-token: $imds_token" 169.254.169.254/latest/meta-data/instance-id )
availability_zone=$( curl -Ss -H "X-aws-ec2-metadata-token: $imds_token" 169.254.169.254/latest/meta-data/placement/availability-zone )
volume_id=""

# Search for an available EBS volume to attach to the instance. Wait one minute for a volume to become available,
# if no volume is found - create new one, attach, format and mount the volume.

for i in $(seq 1 6); do

  volume_id=$(
    aws --cli-connect-timeout 300 ec2 describe-volumes \
      --filters "Name=status,Values=available" "Name=availability-zone,Values=$availability_zone" "Name=tag:Name,Values=${name}-graphdb-data" \
      --query "Volumes[*].{ID:VolumeId}" \
      --output text | \
      sed '/^$/d'
  )

  if [ -z "${volume_id:-}" ]; then
    echo 'ebs volume not yet available'
    sleep 10
  else
    break
  fi
done

if [ -z "${volume_id:-}" ]; then

# If the volume type is GP3, then we need to provide a value for the "throughput" parameter.
 if [ "${ebs_volume_type}" == "gp3"] || ["${ebs_volume_type}" == "gp2" ]; then
      volume_id=$(
        aws --cli-connect-timeout 300 ec2 create-volume \
          --availability-zone "$availability_zone" \
          --encrypted \
          --kms-key-id "${ebs_kms_key_arn}" \
          --volume-type "${ebs_volume_type}" \
          --size "${ebs_volume_size}" \
          --iops "${ebs_volume_iops}" \
          --throughput "${ebs_volume_throughput}" \
          --tag-specifications "ResourceType=volume,Tags=[{Key=Name,Value=${name}-graphdb-data}]" | \
          jq -r .VolumeId
      )
    else
      volume_id=$(
        aws --cli-connect-timeout 300 ec2 create-volume \
          --availability-zone "$availability_zone" \
          --encrypted \
          --kms-key-id "${ebs_kms_key_arn}" \
          --volume-type "${ebs_volume_type}" \
          --size "${ebs_volume_size}" \
          --iops "${ebs_volume_iops}" \
          --tag-specifications "ResourceType=volume,Tags=[{Key=Name,Value=${name}-graphdb-data}]" | \
          jq -r .VolumeId
      )
    fi

  aws --cli-connect-timeout 300 ec2 wait volume-available --volume-ids "$volume_id"
fi

aws --cli-connect-timeout 300 ec2 attach-volume \
  --volume-id "$volume_id" \
  --instance-id "$instance_id" \
  --device "${device_name}"

# Handle the EBS volume used for the GraphDB data directory
# beware, here be dragons...
# read these articles:
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html
# https://github.com/oogali/ebs-automatic-nvme-mapping/blob/master/README.md

# this variable comes from terraform, and it's what we specified in the launch template as the device mapping for the ebs
# because this might be attached under a different name, we'll need to search for it
device_mapping_full="${device_name}"
device_mapping_short="$(echo $device_mapping_full | cut -d'/' -f3)"

graphdb_device=""

# the device might not be available immediately, wait a while
for i in $(seq 1 12); do
  for volume in $(find /dev | grep -i 'nvme[0-21]n1$'); do
    # extract the specified device from the vendor-specific data
    # read https://github.com/oogali/ebs-automatic-nvme-mapping/blob/master/README.md, for more information
    real_device=$(nvme id-ctrl --raw-binary $volume | cut -c3073-3104 | tr -s ' ' | sed 's/ $//g')
    if [ "$device_mapping_full" = "$real_device" ] || [ "$device_mapping_short" = "$real_device" ]; then
      graphdb_device="$volume"
      break
    fi
  done

  if [ -n "$graphdb_device" ]; then
    break
  fi
  sleep 5
done

# create a file system if there isn't any
if [ "$graphdb_device: data" = "$(file -s $graphdb_device)" ]; then
  mkfs -t ext4 $graphdb_device
fi

disk_mount_point="/var/opt/graphdb"

# Check if the disk is already mounted
if ! mount | grep -q "$graphdb_device"; then
  echo "The disk at $graphdb_device is not mounted."

  # Create the mount point if it doesn't exist
  if [ ! -d "$disk_mount_point" ]; then
    mkdir -p "$disk_mount_point"
  fi

  # Add an entry to the fstab file to automatically mount the disk
  if ! grep -q "$graphdb_device" /etc/fstab; then
    echo "$graphdb_device $disk_mount_point ext4 defaults 0 2" >> /etc/fstab
  fi

  # Mount the disk
  mount "$disk_mount_point"
  echo "The disk at $graphdb_device is now mounted at $disk_mount_point."
else
  echo "The disk at $graphdb_device is already mounted."
fi

# Ensure data folders exist
mkdir -p $disk_mount_point/node $disk_mount_point/cluster-proxy

# this is needed because after the disc attachment folder owner is reverted
chown -R graphdb:graphdb $disk_mount_point