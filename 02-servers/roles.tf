# ==============================================================================
# Instance Principal: Linux AD Client
# ------------------------------------------------------------------------------
# Grants the linux-ad-instance permission to read its own admin password from
# the Vault at runtime, so the raw password is never embedded in instance
# metadata or user_data.
# ==============================================================================

# Dynamic groups must be anchored in the root tenancy, not a compartment.
resource "oci_identity_dynamic_group" "linux_client" {
  compartment_id = var.tenancy_ocid
  name           = "mini-ad-linux-client-dg"
  description    = "Grants linux-ad-instance instance principal for Vault access"
  matching_rule  = "instance.id = '${oci_core_instance.linux_ad_instance.id}'"
}

# Policy is scoped to the compartment — dynamic group is tenancy-level but
# the allow statement targets only the specific compartment's secrets.
resource "oci_identity_policy" "linux_vault_read" {
  compartment_id = local.compartment_ocid
  name           = "mini-ad-linux-vault-read"
  description    = "Allow linux AD client to read secrets from the AD vault"

  statements = [
    "Allow dynamic-group mini-ad-linux-client-dg to read secret-family in compartment id ${local.compartment_ocid}"
  ]
}
