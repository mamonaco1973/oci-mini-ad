#!/bin/bash
# ==============================================================================
# validate.sh - Mini-AD Quick Start Validation (OCI)
# ------------------------------------------------------------------------------
# Purpose:
#   - Reads OCI compute instance public IPs from Terraform state outputs.
#   - Prints connection endpoints for RDP and SSH access.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Pull public IPs from Terraform state
# ------------------------------------------------------------------------------
cd 02-servers

linux_ip=$(terraform output -raw linux_public_ip 2>/dev/null || echo "")
windows_ip=$(terraform output -raw windows_public_ip 2>/dev/null || echo "")

cd ..

# ------------------------------------------------------------------------------
# Quick Start Output
# ------------------------------------------------------------------------------
echo ""
echo "============================================================================"
echo "Mini-AD Quick Start - Validation Output"
echo "============================================================================"
echo ""

if [ -n "${linux_ip}" ]; then
  echo "NOTE: Linux SSH Host:    ${linux_ip}"
  echo "      SSH command:       ssh -i 01-directory/keys/Private_Key ubuntu@${linux_ip}"
else
  echo "WARN: linux-ad-instance public IP not found"
fi

if [ -n "${windows_ip}" ]; then
  echo "NOTE: Windows RDP Host:  ${windows_ip}"
else
  echo "WARN: windows-ad-instance public IP not found"
fi

echo ""
echo "NOTE: Validation complete."
echo ""
