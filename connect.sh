#!/bin/bash
set -uo pipefail

REGION="us-ashburn-1"
KEY="01-directory/keys/Private_Key"

BASTION_ID=$(cd 01-directory && terraform output -raw bastion_id)
DC_IP=$(cd 01-directory && terraform output -raw dc_private_ip)
TARGET_IP="${1:-$DC_IP}"

echo "DEBUG: Target IP  : $TARGET_IP"
echo "DEBUG: Bastion ID : $BASTION_ID"

PUB_KEY_CONTENT=$(tr -d '\n\r' < "${KEY}.pub")
echo "DEBUG: Pub key length: ${#PUB_KEY_CONTENT}"

TARGET_DETAILS="{\"targetResourcePrivateIpAddress\": \"${TARGET_IP}\", \"targetResourcePort\": 22, \"sessionType\": \"PORT_FORWARDING\"}"
KEY_DETAILS="{\"publicKeyContent\": \"${PUB_KEY_CONTENT}\"}"

echo "DEBUG: target-details: $TARGET_DETAILS"
echo "DEBUG: key-details preview: ${KEY_DETAILS:0:60}..."
echo "DEBUG: Running oci bastion session create..."

RAW_OUTPUT=$(oci bastion session create \
  --bastion-id "$BASTION_ID" \
  --key-details "$KEY_DETAILS" \
  --target-details "$TARGET_DETAILS" \
  --session-ttl-in-seconds 10800 2>&1) || true

echo "DEBUG: Exit code: $?"
echo "DEBUG: Raw output:"
echo "$RAW_OUTPUT"
echo "DEBUG: --- end raw output ---"
