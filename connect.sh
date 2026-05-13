#!/bin/bash
set -uo pipefail

REGION="us-ashburn-1"
KEY="01-directory/keys/Private_Key"
LOCAL_PORT=2222

BASTION_ID=$(cd 01-directory && terraform output -raw bastion_id)
DC_IP=$(cd 01-directory && terraform output -raw dc_private_ip)
TARGET_IP="${1:-$DC_IP}"

echo "Target: $TARGET_IP"
echo "Creating bastion session..."

TARGET_DETAILS="{\"targetResourcePrivateIpAddress\": \"${TARGET_IP}\", \"targetResourcePort\": 22, \"sessionType\": \"PORT_FORWARDING\"}"

SESSION_JSON=$(oci bastion session create \
  --bastion-id "$BASTION_ID" \
  --target-resource-details "$TARGET_DETAILS" \
  --key-type PUB \
  --ssh-public-key-file "${KEY}.pub" \
  --session-ttl-in-seconds 10800)

SESSION_ID=$(echo "$SESSION_JSON" | jq -r '.data.id')
echo "Session: $SESSION_ID"
echo "Waiting for ACTIVE..."

while true; do
  SESSION_DATA=$(oci bastion session get --session-id "$SESSION_ID")
  STATE=$(echo "$SESSION_DATA" | jq -r '.data["lifecycle-state"]')
  echo "  $STATE"
  [ "$STATE" = "ACTIVE" ] && break
  sleep 10
done

echo "DEBUG: ssh-metadata:"
echo "$SESSION_DATA" | jq '.data["ssh-metadata"]'
