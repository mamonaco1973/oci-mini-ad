# ==============================================================================
# OCI Vault
# Stores all generated AD passwords as versioned secrets.
# NOTE: On destroy, OCI schedules the vault for deletion (minimum 7 days).
# The random suffix ensures a fresh deploy never collides with a
# pending-deletion vault from a previous destroy.
# ==============================================================================

resource "random_id" "vault_suffix" {
  byte_length = 4
}

resource "oci_kms_vault" "ad_vault" {
  compartment_id = var.compartment_ocid
  display_name   = "mini-ad-vault-${random_id.vault_suffix.hex}"
  vault_type     = "DEFAULT"
}

resource "oci_kms_key" "ad_key" {
  compartment_id      = var.compartment_ocid
  display_name        = "mini-ad-key"
  management_endpoint = oci_kms_vault.ad_vault.management_endpoint

  key_shape {
    algorithm = "AES"
    length    = 32
  }
}

# ==============================================================================
# Secrets — one per AD account
# ==============================================================================

resource "oci_vault_secret" "admin_password" {
  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.ad_vault.id
  key_id         = oci_kms_key.ad_key.id
  secret_name    = "admin_ad_credentials"

  secret_content {
    content_type = "BASE64"
    content = base64encode(jsonencode({
      username = "Admin@${var.dns_zone}"
      password = random_password.admin_password.result
    }))
  }
}

resource "oci_vault_secret" "jsmith_password" {
  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.ad_vault.id
  key_id         = oci_kms_key.ad_key.id
  secret_name    = "jsmith_ad_credentials"

  secret_content {
    content_type = "BASE64"
    content = base64encode(jsonencode({
      username = "jsmith@${var.dns_zone}"
      password = random_password.jsmith_password.result
    }))
  }
}

resource "oci_vault_secret" "edavis_password" {
  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.ad_vault.id
  key_id         = oci_kms_key.ad_key.id
  secret_name    = "edavis_ad_credentials"

  secret_content {
    content_type = "BASE64"
    content = base64encode(jsonencode({
      username = "edavis@${var.dns_zone}"
      password = random_password.edavis_password.result
    }))
  }
}

resource "oci_vault_secret" "rpatel_password" {
  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.ad_vault.id
  key_id         = oci_kms_key.ad_key.id
  secret_name    = "rpatel_ad_credentials"

  secret_content {
    content_type = "BASE64"
    content = base64encode(jsonencode({
      username = "rpatel@${var.dns_zone}"
      password = random_password.rpatel_password.result
    }))
  }
}

resource "oci_vault_secret" "akumar_password" {
  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.ad_vault.id
  key_id         = oci_kms_key.ad_key.id
  secret_name    = "akumar_ad_credentials"

  secret_content {
    content_type = "BASE64"
    content = base64encode(jsonencode({
      username = "akumar@${var.dns_zone}"
      password = random_password.akumar_password.result
    }))
  }
}
