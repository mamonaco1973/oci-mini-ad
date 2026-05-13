#!/bin/bash
# ==============================================================================
# get_password.sh - Retrieve AD account password from Terraform state
# ------------------------------------------------------------------------------
# Usage:
#   ./get_password.sh <user>
#
# Valid users: admin, jsmith, edavis, rpatel, akumar
# ==============================================================================

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <user>"
  echo "Valid users: admin, jsmith, edavis, rpatel, akumar"
  exit 1
fi

USER="$1"

valid_users=("admin" "jsmith" "edavis" "rpatel" "akumar")
found=false
for u in "${valid_users[@]}"; do
  [ "$u" = "$USER" ] && found=true && break
done

if [ "$found" = false ]; then
  echo "ERROR: Unknown user '$USER'"
  echo "Valid users: admin, jsmith, edavis, rpatel, akumar"
  exit 1
fi

cd 01-directory
terraform output -raw "${USER}_password"
echo ""
