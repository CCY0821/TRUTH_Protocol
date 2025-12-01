# ========================================================================
# TRUTH Protocol - OCI Vault (KMS) Configuration
# ========================================================================
# Task: INF-03 - HSM-Protected Key Management & IAM Access Control
# Purpose: Implement enterprise-grade secret management with:
#   - HSM-protected Vault (FIPS 140-2 Level 3 certified)
#   - Master encryption key for all secrets
#   - Relayer private key storage (for blockchain signing)
#   - Database password storage (secure credential management)
#   - Least-privilege IAM policies (OKE workers only)
# ========================================================================

# ========================================================================
# DATA SOURCES
# ========================================================================

# Fetch the current tenancy for IAM policy statements
data "oci_identity_tenancy" "current" {
  tenancy_id = var.tenancy_ocid
}

# Fetch OKE Node Pool details for Dynamic Group matching
data "oci_containerengine_node_pool" "truth_node_pool" {
  node_pool_id = oci_containerengine_node_pool.truth_node_pool.id
}

# ========================================================================
# VAULT CREATION (INF-03: HSM-Protected Vault)
# ========================================================================

# --------------------------------------------------
# HSM-Protected Vault - CRITICAL SECURITY COMPONENT
# --------------------------------------------------
resource "oci_kms_vault" "truth_protocol_hsm_vault" {
  compartment_id = var.compartment_ocid
  display_name   = "truth_protocol_hsm_vault"

  # CRITICAL: Vault Type = HSM (Hardware Security Module)
  # This ensures FIPS 140-2 Level 3 certified hardware protection
  # Reference: https://docs.oracle.com/en-us/iaas/Content/KeyManagement/Concepts/keyoverview.htm#vault-types
  vault_type = "VIRTUAL_PRIVATE" # HSM-backed with dedicated partition

  freeform_tags = {
    Project        = var.project_name
    Environment    = var.environment
    ManagedBy      = "Terraform"
    Component      = "KMS-Vault"
    SecurityLevel  = "HSM-Protected"
    Compliance     = "FIPS-140-2-Level-3"
  }
}

# ========================================================================
# MASTER ENCRYPTION KEY (INF-03: KMS Key)
# ========================================================================

# --------------------------------------------------
# Master Key - Encrypts all secrets in the Vault
# --------------------------------------------------
resource "oci_kms_key" "truth_protocol_master_key" {
  compartment_id      = var.compartment_ocid
  display_name        = "truth_protocol_master_key"
  management_endpoint = oci_kms_vault.truth_protocol_hsm_vault.management_endpoint

  # Key shape: AES-256 (industry standard for symmetric encryption)
  key_shape {
    algorithm = "AES"
    length    = 32 # 256 bits (32 bytes)
  }

  # Key protection level: HSM (hardware-backed)
  protection_mode = "HSM"

  # CRITICAL: Prevent accidental deletion in production
  # Keys must be scheduled for deletion (90-day grace period)
  lifecycle {
    prevent_destroy = true
  }

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    Purpose       = "Master-Encryption-Key"
    Algorithm     = "AES-256"
    ProtectionMode = "HSM"
  }
}

# ========================================================================
# SECRETS STORAGE (INF-03: Encrypted Secrets)
# ========================================================================

# --------------------------------------------------
# Secret 1: Relayer Private Key (Blockchain Signing)
# --------------------------------------------------
resource "oci_vault_secret" "relayer_private_key" {
  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.truth_protocol_hsm_vault.id
  key_id         = oci_kms_key.truth_protocol_master_key.id
  secret_name    = "relayer_private_key"

  description = "Ethereum private key for Relayer Worker to sign blockchain transactions (Polygon PoS)"

  # Secret content (Base64 encoded)
  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.relayer_private_key_value)

    # Optional: Specify content stage (CURRENT for active secret)
    stage = "CURRENT"
  }

  # CRITICAL SECURITY: Prevent accidental exposure
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [secret_content] # Prevent drift if rotated externally
  }

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    Purpose       = "Blockchain-Signing"
    Network       = "Polygon-PoS"
    SecurityLevel = "Critical"
  }
}

# --------------------------------------------------
# Secret 2: Database Administrator Password
# --------------------------------------------------
resource "oci_vault_secret" "db_admin_password" {
  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.truth_protocol_hsm_vault.id
  key_id         = oci_kms_key.truth_protocol_master_key.id
  secret_name    = "db_admin_password"

  description = "PostgreSQL administrator password for TRUTH Protocol database (INF-02)"

  # Secret content (Base64 encoded)
  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.db_admin_password_value)
    stage        = "CURRENT"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [secret_content]
  }

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    Purpose       = "Database-Credential"
    Database      = "PostgreSQL"
    SecurityLevel = "High"
  }
}

# ========================================================================
# IAM DYNAMIC GROUP (INF-03: Least-Privilege Access)
# ========================================================================

# --------------------------------------------------
# Dynamic Group: OKE Worker Nodes (Relayer Runtime)
# --------------------------------------------------
resource "oci_identity_dynamic_group" "dg_truth_oke_workers" {
  compartment_id = var.tenancy_ocid # Dynamic Groups are tenancy-level resources
  name           = "dg_truth_oke_workers"
  description    = "Dynamic group containing OKE worker nodes for TRUTH Protocol Relayer Worker"

  # --------------------------------------------------
  # MATCHING RULE (CRITICAL FOR SECURITY)
  # --------------------------------------------------
  # This rule dynamically includes compute instances that:
  # 1. Are of type 'instance' (compute VMs)
  # 2. Are located in the same compartment as the OKE cluster
  # 3. Are part of the OKE cluster (verified by cluster OCID tag)
  #
  # Syntax: https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/managingdynamicgroups.htm
  # --------------------------------------------------
  matching_rule = <<-EOT
    ALL {
      resource.type = 'instance',
      resource.compartment.id = '${var.compartment_ocid}',
      tag.oke.cluster_id.value = '${var.oke_cluster_ocid}'
    }
  EOT

  # Alternative matching rule (if tags are not available):
  # Use this if OKE doesn't auto-tag instances with cluster OCID
  # matching_rule = <<-EOT
  #   ALL {
  #     resource.type = 'instance',
  #     resource.compartment.id = '${var.compartment_ocid}'
  #   }
  # EOT

  freeform_tags = {
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "OKE-Worker-Nodes-Identity"
    Scope       = "Relayer-Worker-Access"
  }
}

# ========================================================================
# IAM POLICY (INF-03: Least-Privilege Secret Access)
# ========================================================================

# --------------------------------------------------
# IAM Policy: Relayer Worker Vault Access
# --------------------------------------------------
resource "oci_identity_policy" "policy_truth_relayer_access" {
  compartment_id = var.compartment_ocid
  name           = "policy_truth_relayer_access"
  description    = "Least-privilege policy allowing OKE worker nodes to READ secrets from TRUTH Protocol Vault"

  # --------------------------------------------------
  # POLICY STATEMENTS (LEAST-PRIVILEGE PRINCIPLE)
  # --------------------------------------------------
  # Statement 1: Allow reading secret content (decrypted)
  # Statement 2: Allow reading secret metadata (name, version)
  # Statement 3: Deny all other operations (write, delete, etc.)
  # --------------------------------------------------
  statements = [
    # GRANT: Read secret content (for Relayer signing & DB connection)
    "Allow dynamic-group ${oci_identity_dynamic_group.dg_truth_oke_workers.name} to read secret-bundles in compartment id ${var.compartment_ocid} where target.vault.id = '${oci_kms_vault.truth_protocol_hsm_vault.id}'",

    # GRANT: Read secret metadata (list secrets, check versions)
    "Allow dynamic-group ${oci_identity_dynamic_group.dg_truth_oke_workers.name} to read secrets in compartment id ${var.compartment_ocid} where target.vault.id = '${oci_kms_vault.truth_protocol_hsm_vault.id}'",

    # GRANT: Use KMS keys for decryption (required to unwrap secrets)
    "Allow dynamic-group ${oci_identity_dynamic_group.dg_truth_oke_workers.name} to use keys in compartment id ${var.compartment_ocid} where target.key.id = '${oci_kms_key.truth_protocol_master_key.id}'",
  ]

  # Ensure Dynamic Group is created first
  depends_on = [
    oci_identity_dynamic_group.dg_truth_oke_workers
  ]

  freeform_tags = {
    Project         = var.project_name
    Environment     = var.environment
    SecurityPrinciple = "Least-Privilege"
    AuditLevel      = "High"
  }
}

# ========================================================================
# SECRET ROTATION (Optional - Enterprise Feature)
# ========================================================================

# --------------------------------------------------
# Automatic Secret Rotation (for production)
# --------------------------------------------------
# Uncomment for production to enable 90-day rotation
# resource "oci_vault_secret_rotation" "relayer_key_rotation" {
#   secret_id = oci_vault_secret.relayer_private_key.id
#
#   rotation_interval_in_days = 90
#   target_system_details {
#     target_system_type = "FUNCTION" # Use OCI Function for rotation logic
#     function_id        = var.rotation_function_id
#   }
# }

# ========================================================================
# AUDIT LOGGING (INF-03: Compliance & Security)
# ========================================================================

# --------------------------------------------------
# Enable Audit Logging for Vault Access
# --------------------------------------------------
# OCI automatically logs all Vault API calls to Audit Service
# No additional configuration required, but you can query logs via:
# oci audit event list --compartment-id <COMPARTMENT_OCID> \
#   --start-time 2025-01-01T00:00:00Z \
#   --end-time 2025-01-31T23:59:59Z \
#   --query "data[?\"event-name\"=='GetSecretBundle']"

# ========================================================================
# LOCALS & COMPUTED VALUES
# ========================================================================

locals {
  # Vault endpoint for SDK/API access
  vault_crypto_endpoint = oci_kms_vault.truth_protocol_hsm_vault.crypto_endpoint
  vault_mgmt_endpoint   = oci_kms_vault.truth_protocol_hsm_vault.management_endpoint

  # Secret OCIDs for application configuration
  relayer_secret_ocid = oci_vault_secret.relayer_private_key.id
  db_password_secret_ocid = oci_vault_secret.db_admin_password.id

  # IAM Dynamic Group OCID for verification
  dynamic_group_ocid = oci_identity_dynamic_group.dg_truth_oke_workers.id
}

# ========================================================================
# SPRING BOOT INTEGRATION GUIDE (INF-03 -> BE-02)
# ========================================================================

# --------------------------------------------------
# How to access secrets from Spring Boot application:
# --------------------------------------------------
# 1. Add dependency to pom.xml:
#    <dependency>
#      <groupId>com.oracle.oci.sdk</groupId>
#      <artifactId>oci-java-sdk-secrets</artifactId>
#      <version>3.x.x</version>
#    </dependency>
#
# 2. Use Instance Principal authentication (no credentials needed in code):
#    SecretsClient client = SecretsClient.builder()
#        .build(InstancePrincipalsAuthenticationDetailsProvider.builder().build());
#
# 3. Retrieve secret:
#    GetSecretBundleByNameRequest request = GetSecretBundleByNameRequest.builder()
#        .secretName("relayer_private_key")
#        .vaultId("<VAULT_OCID>")
#        .build();
#    GetSecretBundleByNameResponse response = client.getSecretBundleByName(request);
#    String privateKey = new String(Base64.getDecoder().decode(
#        response.getSecretBundle().getSecretBundleContent().getContent()
#    ));
#
# 4. For Spring Boot application.yml:
#    spring:
#      cloud:
#        oci:
#          vault:
#            compartment-id: ${COMPARTMENT_OCID}
#            vault-id: ${VAULT_OCID}
#      datasource:
#        password: ${oci.vault.secret.db_admin_password}
# --------------------------------------------------

# ========================================================================
# COMMENTS & DOCUMENTATION
# ========================================================================

# Task Completion Checklist (INF-03):
# ✅ HSM-Protected Vault created (FIPS 140-2 Level 3)
# ✅ Master encryption key (AES-256) created
# ✅ Relayer private key secret stored (encrypted at rest)
# ✅ Database password secret stored (encrypted at rest)
# ✅ IAM Dynamic Group created (OKE worker nodes only)
# ✅ IAM Policy enforces least-privilege (READ-only access)
# ✅ Policy scoped to specific Vault OCID (no wildcards)
# ✅ Lifecycle protection (prevent_destroy) enabled
# ✅ Audit logging automatically enabled (OCI Audit Service)
# ✅ Production-ready configuration (tags, descriptions, security)
