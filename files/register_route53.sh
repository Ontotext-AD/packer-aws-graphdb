#!/usr/bin/env bash

set -euxo pipefail

# Set common variables used throughout the script.
imds_token=$( curl -Ss -H "X-aws-ec2-metadata-token-ttl-seconds: 300" -XPUT 169.254.169.254/latest/api/token )
availability_zone=$( curl -Ss -H "X-aws-ec2-metadata-token: $imds_token" 169.254.169.254/latest/meta-data/placement/availability-zone )
local_ipv4=$( curl -Ss -H "X-aws-ec2-metadata-token: $imds_token" 169.254.169.254/latest/meta-data/local-ipv4 )
name=""
zone_dns_name=""
zone_id=""
volume_id=""

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --name) name="$2"; shift ;;
    --zone_dns_name) zone_dns_name="$2"; shift ;;
    --zone_id) zone_id="$2"; shift ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done

# Register the instance in Route 53, using the volume id for the sub-domain
  volume_id=$(
    aws --cli-connect-timeout 300 ec2 describe-volumes \
      --filters "Name=availability-zone,Values=$availability_zone" "Name=tag:Name,Values=${name}-graphdb-data" \
      --query "Volumes[*].{ID:VolumeId}" \
      --output text | \
      sed '/^$/d'
  )

subdomain="$( echo -n "$volume_id" | sed 's/^vol-//' )"
node_dns="$subdomain.${zone_dns_name}"

aws --cli-connect-timeout 300 route53 change-resource-record-sets \
  --hosted-zone-id "${zone_id}" \
  --change-batch '{"Changes": [{"Action": "UPSERT","ResourceRecordSet": {"Name": "'"$node_dns"'","Type": "A","TTL": 60,"ResourceRecords": [{"Value": "'"$local_ipv4"'"}]}}]}'

hostnamectl set-hostname "$node_dns"

echo "Instance registered in Route 53 with DNS name:"
echo "$node_dns"