#!/bin/bash
set -uo pipefail

REGION="us-ashburn-1"
KEY="01-directory/keys/Private_Key"

BASTION_ID=$(cd 01-directory && terraform output -raw bastion_id)
DC_IP=$(cd 01-directory && terraform output -raw dc_private_ip)
TARGET_IP="${1:-$DC_IP}"

echo "DEBUG: Target IP  : $TARGET_IP"
echo "DEBUG: Bastion ID : $BASTION_ID"
echo "DEBUG: Key file   : $KEY"
echo "DEBUG: Pub key    : ${KEY}.pub"

PUB_KEY_CONTENT=$(tr -d '\n\r' < "${KEY}.pub")
echo "DEBUG: Pub key length: ${#PUB_KEY_CONTENT}"
echo "DEBUG: Pub key preview: ${PUB_KEY_CONTENT:0:40}..."

KEY_DETAILS="{\"publicKeyContent\": \"${PUB_KEY_CONTENT}\"}"
echo "DEBUG: key-details preview: ${KEY_DETAILS:0:60}..."

echo "DEBUG: Running oci bastion session create-port-forwarding..."

RAW_OUTPUT=$(oci bastion session create-port-forwarding \
  --bastion-id "$BASTION_ID" \
  --target-private-ip "$TARGET_IP" \
  --target-port 22 \
  --key-details "$KEY_DETAILS" \
  --session-ttl-in-seconds 10800 2>&1) || true

echo "DEBUG: Exit code: $?"
echo "DEBUG: Raw output:"
echo "$RAW_OUTPUT"
echo "DEBUG: --- end raw output ---"

SESSION_OCID=$(echo "$RAW_OUTPUT" | grep -o '"id": "[^"]*"' | head -1 | cut -d'"' -f4 || true)
echo "DEBUG: Extracted SESSION_OCID: '$SESSION_OCID'"
