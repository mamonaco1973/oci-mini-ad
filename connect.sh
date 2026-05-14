#!/bin/bash
set -uo pipefail

LOCAL_PORT=2222

BASTION_ID=$(cd 01-directory && terraform output -raw bastion_id)
DC_IP=$(cd 01-directory && terraform output -raw dc_private_ip)
TARGET_IP="${1:-$DC_IP}"

echo "Target: $TARGET_IP"

# Retrieve ubuntu password from vault for the inner SSH connection
VAULT_ID=$(cd 01-directory && terraform output -raw vault_id 2>/dev/null || echo "")
UBUNTU_PASS=""
if [ -n "$VAULT_ID" ]; then
  UBUNTU_PASS=$(oci secrets secret-bundle get-secret-bundle-by-name \
    --vault-id "$VAULT_ID" \
    --secret-name "mini-ad-admin" 2>/dev/null \
    | jq -r '.data."secret-bundle-content".content' | base64 -d || echo "")
fi

# Generate a temporary RSA key for the bastion tunnel.
# OCI Bastion rejects ECDSA — temp RSA key avoids dependency on the
# Terraform-managed key pair entirely.
TMP_KEY=$(mktemp /tmp/bastion_key_XXXXXX)
ssh-keygen -t rsa -b 4096 -f "$TMP_KEY" -N "" -q
chmod 600 "$TMP_KEY"

cleanup() {
  rm -f "$TMP_KEY" "${TMP_KEY}.pub"
  kill "$TUNNEL_PID" 2>/dev/null || true
}
trap cleanup EXIT

echo "Creating bastion session..."

TARGET_DETAILS="{\"targetResourcePrivateIpAddress\": \"${TARGET_IP}\", \"targetResourcePort\": 22, \"sessionType\": \"PORT_FORWARDING\"}"

SESSION_JSON=$(oci bastion session create \
  --bastion-id "$BASTION_ID" \
  --target-resource-details "$TARGET_DETAILS" \
  --key-type PUB \
  --ssh-public-key-file "${TMP_KEY}.pub" \
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

TUNNEL_CMD=$(echo "$SESSION_DATA" | jq -r '.data["ssh-metadata"].command' \
  | sed "s|<privateKey>|${TMP_KEY}|g" \
  | sed "s|<localPort>|${LOCAL_PORT}|g")

echo "Opening tunnel..."
eval "$TUNNEL_CMD -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" &
TUNNEL_PID=$!
sleep 3

if [ -n "$UBUNTU_PASS" ]; then
  echo "Password: $UBUNTU_PASS"
fi

ssh -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o PasswordAuthentication=yes \
  -o PubkeyAuthentication=no \
  -p "$LOCAL_PORT" \
  ubuntu@localhost
