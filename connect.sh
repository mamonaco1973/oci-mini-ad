#!/bin/bash
set -uo pipefail

REGION="us-ashburn-1"
KEY="01-directory/keys/Private_Key"

BASTION_ID=$(cd 01-directory && terraform output -raw bastion_id)
DC_IP=$(cd 01-directory && terraform output -raw dc_private_ip)
TARGET_IP="${1:-$DC_IP}"

echo "DEBUG: Target IP  : $TARGET_IP"
echo "DEBUG: Bastion ID : $BASTION_ID"
echo "DEBUG: Running oci bastion session create..."

RAW_OUTPUT=$(oci bastion session create-port-forwarding-session-target-resource-private-ip-address \
  --bastion-id "$BASTION_ID" \
  --ssh-public-key-file "${KEY}.pub" \
  --target-private-ip "$TARGET_IP" \
  --target-port 22 \
  --session-ttl-in-seconds 10800 2>&1) || true

echo "DEBUG: Exit code: $?"
echo "DEBUG: Raw output:"
echo "$RAW_OUTPUT"
echo "DEBUG: --- end raw output ---"
