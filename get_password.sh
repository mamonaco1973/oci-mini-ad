#!/bin/bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <user>"
  echo "Valid users: admin, jsmith, edavis, rpatel, akumar"
  exit 1
fi

USER="$1"
TFSTATE="01-directory/terraform.tfstate"

if [ ! -f "$TFSTATE" ]; then
  echo "ERROR: $TFSTATE not found — has 01-directory been applied?"
  exit 1
fi

PASSWORD=$(jq -r --arg name "${USER}_password" '
  .resources[]
  | select(.type == "random_password" and .name == $name)
  | .instances[0].attributes.result
' "$TFSTATE")

if [ -z "$PASSWORD" ] || [ "$PASSWORD" = "null" ]; then
  echo "ERROR: No password found for user '$USER'"
  echo "Valid users: admin, jsmith, edavis, rpatel, akumar"
  exit 1
fi

echo "$PASSWORD"
