#!/bin/bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <user>"
  echo "Valid users: admin, jsmith, edavis, rpatel, akumar"
  exit 1
fi

USER="$1"

VAULT_ID=$(cd 01-directory && terraform output -raw vault_id 2>/dev/null || echo "")

if [ -z "$VAULT_ID" ]; then
  echo "ERROR: vault_id not found — has 01-directory been applied?"
  exit 1
fi

SECRET_JSON=$(oci secrets secret-bundle get-secret-bundle-by-name \
  --vault-id "$VAULT_ID" \
  --secret-name "${USER}_ad_credentials" \
  2>/dev/null \
  | jq -r '.data."secret-bundle-content".content' \
  | base64 -d)

if [ -z "$SECRET_JSON" ]; then
  echo "ERROR: No secret found for user '$USER'"
  echo "Valid users: admin, jsmith, edavis, rpatel, akumar"
  exit 1
fi

USERNAME=$(echo "$SECRET_JSON" | jq -r '.username')
PASSWORD=$(echo "$SECRET_JSON" | jq -r '.password')

echo "Username : ${USERNAME}"
echo "Password : ${PASSWORD}"
