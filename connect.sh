#!/bin/bash
# ==============================================================================
# connect.sh - SSH to a private OCI instance via Bastion
# ------------------------------------------------------------------------------
# Usage:
#   ./connect.sh              # connects to the AD DC (default)
#   ./connect.sh <private-ip> # connects to any private instance
# ==============================================================================

set -euo pipefail

REGION="us-ashburn-1"
KEY="01-directory/keys/Private_Key"

# ------------------------------------------------------------------------------
# Read bastion ID and DC private IP from Terraform state
# ------------------------------------------------------------------------------
BASTION_ID=$(cd 01-directory && terraform output -raw bastion_id)
DC_IP=$(cd 01-directory && terraform output -raw dc_private_ip)
TARGET_IP="${1:-$DC_IP}"

echo "NOTE: Target IP  : $TARGET_IP"
echo "NOTE: Bastion ID : $BASTION_ID"

# ------------------------------------------------------------------------------
# Create port-forwarding session
# ------------------------------------------------------------------------------
echo "NOTE: Creating bastion session..."

PUB_KEY_CONTENT=$(tr -d '\n\r' < "${KEY}.pub")

SESSION_OCID=$(oci bastion session create-port-forwarding \
  --bastion-id "$BASTION_ID" \
  --target-private-ip "$TARGET_IP" \
  --target-port 22 \
  --key-details "{\"publicKeyContent\": \"${PUB_KEY_CONTENT}\"}" \
  --session-ttl-in-seconds 10800 \
  --query 'data.id' \
  --raw-output)

if [ -z "$SESSION_OCID" ] || [ "$SESSION_OCID" = "null" ]; then
  echo "ERROR: Failed to create bastion session."
  exit 1
fi

echo "NOTE: Session ID : $SESSION_OCID"

# ------------------------------------------------------------------------------
# Poll until ACTIVE
# ------------------------------------------------------------------------------
echo "NOTE: Waiting for session to become ACTIVE..."

until [ "$(oci bastion session get \
  --session-id "$SESSION_OCID" \
  --query 'data."lifecycle-state"' \
  --raw-output)" = "ACTIVE" ]; do
  echo "NOTE: Not ready yet, retrying in 5s..."
  sleep 5
done

echo "NOTE: Connecting to $TARGET_IP..."

# ------------------------------------------------------------------------------
# SSH through the bastion tunnel
# ------------------------------------------------------------------------------
ssh -i "$KEY" \
  -o StrictHostKeyChecking=no \
  -o ProxyCommand="ssh -i ${KEY} -W %h:%p -p 22 ${SESSION_OCID}@host.bastion.${REGION}.oci.oraclecloud.com -o StrictHostKeyChecking=no" \
  ubuntu@"$TARGET_IP"
