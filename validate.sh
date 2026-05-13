#!/bin/bash
# ==============================================================================
# validate.sh - Mini-AD Quick Start Validation (OCI)
# ------------------------------------------------------------------------------
# Purpose:
#   - Reads bastion OCID and DC private IP from Terraform state.
#   - Prints OCI CLI + SSH commands for connecting to the private DC.
# ==============================================================================

set -euo pipefail

cd 01-directory

BASTION_ID=$(terraform output -raw bastion_id 2>/dev/null || echo "")
DC_PRIVATE_IP=$(terraform output -raw dc_private_ip 2>/dev/null || echo "")
KEY="./keys/Private_Key"

cd ..

echo ""
echo "============================================================================"
echo "Mini-AD Quick Start - Connection Instructions"
echo "============================================================================"
echo ""

if [ -z "$BASTION_ID" ] || [ -z "$DC_PRIVATE_IP" ]; then
  echo "WARN: Could not read bastion_id or dc_private_ip from Terraform state."
  echo "      Run 'terraform output' in 01-directory to diagnose."
  exit 1
fi

echo "Bastion ID  : $BASTION_ID"
echo "DC IP       : $DC_PRIVATE_IP"
echo "Private Key : 01-directory/$KEY"
echo ""
echo "----------------------------------------------------------------------------"
echo "Step 1: Create a port-forwarding bastion session (TTL = 3 hours)"
echo "----------------------------------------------------------------------------"
echo ""
echo "  oci bastion session create-port-forwarding \\"
echo "    --bastion-id $BASTION_ID \\"
echo "    --target-private-ip $DC_PRIVATE_IP \\"
echo "    --target-port 22 \\"
echo "    --ssh-public-key-file 01-directory/${KEY}.pub \\"
echo "    --session-ttl-in-seconds 10800"
echo ""
echo "  Wait for the session to reach ACTIVE state, then copy the session OCID."
echo ""
echo "----------------------------------------------------------------------------"
echo "Step 2: SSH to the DC through the bastion tunnel"
echo "----------------------------------------------------------------------------"
echo ""
echo "  Replace <SESSION_OCID> and <REGION> with your values:"
echo ""
echo "  ssh -i 01-directory/$KEY \\"
echo "    -o StrictHostKeyChecking=no \\"
echo "    -o ProxyCommand='ssh -W %h:%p -p 22 <SESSION_OCID>@host.bastion.<REGION>.oci.oraclecloud.com -i 01-directory/$KEY' \\"
echo "    ubuntu@$DC_PRIVATE_IP"
echo ""
echo "  Example region: us-ashburn-1"
echo ""
echo "============================================================================"
echo ""
