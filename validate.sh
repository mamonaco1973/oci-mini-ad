#!/bin/bash
# ==============================================================================
# validate.sh - Mini-AD Quick Start Validation (OCI)
# ==============================================================================

set -euo pipefail

cd 01-directory

BASTION_ID=$(terraform output -raw bastion_id 2>/dev/null || echo "")
DC_IP=$(terraform output -raw dc_private_ip 2>/dev/null || echo "")

cd ..

echo ""
echo "============================================================================"
echo "Mini-AD - Deployment Summary"
echo "============================================================================"
echo ""
echo "  DC Private IP : $DC_IP"
echo "  Bastion ID    : $BASTION_ID"
echo ""
echo "  Connect       : ./connect.sh"
echo "  Get password  : ./get_password.sh <user>"
echo ""
echo "============================================================================"
echo ""
