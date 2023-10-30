#!/usr/bin/env bash

# Configure the GraphDB backup cron job

cat <<-EOF > /usr/bin/graphdb_backup
#!/bin/bash

set -euxo pipefail

GRAPHDB_ADMIN_PASSWORD="\$(aws --cli-connect-timeout 300 ssm get-parameter --region ${region} --name "/${name}/graphdb/admin_password" --with-decryption | jq -r .Parameter.Value)"
NODE_STATE="\$(curl --silent --fail --user "admin:\$GRAPHDB_ADMIN_PASSWORD" localhost:7201/rest/cluster/node/status | jq -r .nodeState)"

if [ "\$NODE_STATE" != "LEADER" ]; then
  echo "current node is not a leader, but \$NODE_STATE"
  exit 0
fi

function trigger_backup {
  local backup_name="\$(date +'%Y-%m-%d_%H-%M-%S').tar"

  curl \
    -vvv --fail \
    --user "admin:\$GRAPHDB_ADMIN_PASSWORD" \
    --url localhost:7201/rest/recovery/cloud-backup \
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

chmod +x /usr/bin/graphdb_backup
# This cron expression schedules the job to run every day at midnight, without any restrictions on the day of the month, month, or day of the week.
echo "0 0 * * * root ${backup_name} graphdb /usr/bin/graphdb_backup" | sudo tee /etc/cron.d/graphdb_backup