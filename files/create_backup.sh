#!/usr/bin/env bash

# Set common variables used throughout the script.
region=""
name=""
backup_bucket_name=""
backup_retention_count=""
backup_schedule=""

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --region) region="$2"; shift ;;
    --name) name="$2"; shift ;;
    --backup_bucket_name) backup_bucket_name="$2"; shift ;;
    --backup_retention_count) backup_retention_count="$2"; shift ;;
    --backup_schedule) backup_schedule="$2"; shift;;
    *) directories+=("$1") ;;
  esac
  shift
done

# Configure the GraphDB backup cron job
cat <<-EOF > /usr/bin/graphdb_backup.sh
#!/bin/bash

set -euxo pipefail

# Use the values from the variables
region="$region"
name="$name"
backup_bucket_name="$backup_bucket_name"
backup_retention_count="$backup_retention_count"
backup_schedule="$backup_schedule"

GRAPHDB_CONNECTOR_PORT="\${GRAPHDB_CONNECTOR_PORT:-7200}"
GRAPHDB_ADMIN_PASSWORD="\$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/admin_password" --with-decryption | jq -r .Parameter.Value)"
NODE_STATE="\$(curl --silent --fail --user "admin:\$GRAPHDB_ADMIN_PASSWORD" localhost:${GRAPHDB_CONNECTOR_PORT}/rest/cluster/node/status | jq -r .nodeState)"

if [ "\$NODE_STATE" != "LEADER" ]; then
  echo "current node is not a leader, but \$NODE_STATE"
  exit 0
fi

function trigger_backup {
  local backup_name="\$(date +'%Y-%m-%d_%H-%M-%S').tar"

  curl \
    -vvv --fail \
    --user "admin:\$GRAPHDB_ADMIN_PASSWORD" \
    --url localhost:${GRAPHDB_CONNECTOR_PORT}/rest/recovery/cloud-backup \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --data-binary @- <<-DATA
    {
      "backupOptions": { "backupSystemData": true },
      "bucketUri": "s3:///${backup_bucket_name}/\$backup_name?region=${region}"
    }
DATA
}

function rotate_backups {
  all_files="\$(aws --cli-connect-timeout 300 s3api list-objects --bucket ${backup_bucket_name} --query 'Contents' | jq .)"
  count="\$(echo \$all_files | jq length)"
  delete_count="\$((count - ${backup_retention_count} - 1))"

  for i in \$(seq 0 \$delete_count); do
    key="\$(echo \$all_files | jq -r .[\$i].Key)"

    aws --cli-connect-timeout 300 s3 rm s3://${backup_bucket_name}/\$key
  done
}

if ! trigger_backup; then
  echo "failed to create backup"
  exit 1
fi

rotate_backups

EOF

chmod +x /usr/bin/graphdb_backup.sh
echo "${backup_schedule} graphdb /usr/bin/graphdb_backup" > /etc/cron.d/graphdb_backup
