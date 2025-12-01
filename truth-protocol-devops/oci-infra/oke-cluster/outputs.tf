# ========================================================================
# TRUTH Protocol - Terraform Outputs
# ========================================================================
# Purpose: Export critical resource identifiers for:
#   1. Subsequent infrastructure modules (DB, Vault, etc.)
#   2. CI/CD pipelines (kubectl configuration)
#   3. Operational monitoring & troubleshooting
# ========================================================================

# --------------------------------------------------
# VCN & Network Outputs
# --------------------------------------------------

output "vcn_id" {
  description = "OCID of the VCN (Virtual Cloud Network)"
  value       = oci_core_vcn.truth_protocol_vcn.id
}

output "vcn_cidr_block" {
  description = "CIDR block of the VCN"
  value       = oci_core_vcn.truth_protocol_vcn.cidr_blocks[0]
}

output "public_subnet_id" {
  description = "OCID of the Public Subnet (Load Balancer)"
  value       = oci_core_subnet.public_subnet.id
}

output "private_subnet_id" {
  description = "OCID of the Private Subnet (OKE Worker Nodes, DB)"
  value       = oci_core_subnet.private_subnet.id
}

output "internet_gateway_id" {
  description = "OCID of the Internet Gateway"
  value       = oci_core_internet_gateway.truth_igw.id
}

output "nat_gateway_id" {
  description = "OCID of the NAT Gateway"
  value       = oci_core_nat_gateway.truth_nat.id
}

output "service_gateway_id" {
  description = "OCID of the Service Gateway"
  value       = oci_core_service_gateway.truth_service_gw.id
}

# --------------------------------------------------
# OKE Cluster Outputs
# --------------------------------------------------

output "oke_cluster_ocid" {
  description = "OCID of the OKE Cluster (for DB access control & IAM)"
  value       = oci_containerengine_cluster.truth_oke_cluster.id
}

output "oke_cluster_name" {
  description = "Name of the OKE Cluster"
  value       = oci_containerengine_cluster.truth_oke_cluster.name
}

output "oke_cluster_kubernetes_version" {
  description = "Kubernetes version of the OKE Cluster"
  value       = oci_containerengine_cluster.truth_oke_cluster.kubernetes_version
}

output "oke_cluster_endpoint" {
  description = "Kubernetes API endpoint (PRIVATE - requires bastion or VPN)"
  value       = oci_containerengine_cluster.truth_oke_cluster.endpoints[0].private_endpoint
  sensitive   = true
}

output "oke_cluster_ca_certificate" {
  description = "CA certificate for Kubernetes API (Base64 encoded)"
  value = base64decode(
    oci_containerengine_cluster.truth_oke_cluster.kubernetes_network_config[0].cluster_certificate_authority_data
  )
  sensitive = true
}

# --------------------------------------------------
# Node Pool Outputs
# --------------------------------------------------

output "node_pool_id" {
  description = "OCID of the default Node Pool"
  value       = oci_containerengine_node_pool.truth_node_pool.id
}

output "node_pool_name" {
  description = "Name of the Node Pool"
  value       = oci_containerengine_node_pool.truth_node_pool.name
}

output "node_pool_size" {
  description = "Number of worker nodes in the pool"
  value       = oci_containerengine_node_pool.truth_node_pool.node_config_details[0].size
}

output "node_shape" {
  description = "Compute shape of worker nodes"
  value       = oci_containerengine_node_pool.truth_node_pool.node_shape
}

# --------------------------------------------------
# Operational & Troubleshooting Outputs
# --------------------------------------------------

output "availability_domains" {
  description = "List of Availability Domains used for node distribution"
  value       = data.oci_identity_availability_domains.ads.availability_domains[*].name
}

output "kubeconfig_command" {
  description = "Command to generate kubeconfig file for kubectl access"
  value = format(
    "oci ce cluster create-kubeconfig --cluster-id %s --file $HOME/.kube/config --region %s --token-version 2.0.0",
    oci_containerengine_cluster.truth_oke_cluster.id,
    var.region
  )
}

# --------------------------------------------------
# Summary Output (for quick reference)
# --------------------------------------------------

output "deployment_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    project            = var.project_name
    environment        = var.environment
    region             = var.region
    vcn_cidr           = oci_core_vcn.truth_protocol_vcn.cidr_blocks[0]
    cluster_name       = oci_containerengine_cluster.truth_oke_cluster.name
    cluster_version    = oci_containerengine_cluster.truth_oke_cluster.kubernetes_version
    node_count         = oci_containerengine_node_pool.truth_node_pool.node_config_details[0].size
    endpoint_type      = var.oke_endpoint_type
    deployed_timestamp = timestamp()
  }
}

# ========================================================================
# DATABASE OUTPUTS (INF-02)
# ========================================================================

# --------------------------------------------------
# PostgreSQL Database Outputs
# --------------------------------------------------

output "db_system_id" {
  description = "OCID of the PostgreSQL Database System"
  value       = oci_psql_db_system.truth_protocol_db.id
}

output "db_system_name" {
  description = "Name of the PostgreSQL Database System"
  value       = oci_psql_db_system.truth_protocol_db.display_name
}

output "db_version" {
  description = "PostgreSQL version"
  value       = oci_psql_db_system.truth_protocol_db.db_version
}

output "db_private_endpoint" {
  description = "Private endpoint for PostgreSQL database (hostname:port)"
  value       = local.db_private_endpoint
  sensitive   = true
}

output "db_hostname" {
  description = "PostgreSQL database hostname (private IP)"
  value       = local.db_hostname
  sensitive   = true
}

output "db_port" {
  description = "PostgreSQL database port"
  value       = local.db_port
}

output "db_name" {
  description = "Initial database name"
  value       = var.db_name
}

output "db_admin_username" {
  description = "Database administrator username"
  value       = var.db_admin_username
  sensitive   = true
}

# --------------------------------------------------
# Database Connection Strings (for Spring Boot)
# --------------------------------------------------

output "db_connection_string" {
  description = "PostgreSQL connection string (password masked - retrieve from OCI Vault)"
  value       = local.db_connection_string
  sensitive   = true
}

output "db_jdbc_url" {
  description = "JDBC connection URL for Spring Boot application.yml"
  value       = local.db_jdbc_url
  sensitive   = true
}

output "db_spring_boot_config" {
  description = "Spring Boot application.yml database configuration snippet"
  value = <<-EOT
    spring:
      datasource:
        url: ${local.db_jdbc_url}
        username: ${var.db_admin_username}
        password: ${"{cipher}VAULT_ENCRYPTED_PASSWORD"} # Use OCI Vault in production
        driver-class-name: org.postgresql.Driver
      jpa:
        database-platform: org.hibernate.dialect.PostgreSQLDialect
        hibernate:
          ddl-auto: validate # Use Flyway for migrations
        properties:
          hibernate:
            format_sql: true
            jdbc:
              time_zone: UTC
  EOT
  sensitive   = true
}

# --------------------------------------------------
# Database Security & Network Outputs
# --------------------------------------------------

output "db_security_list_id" {
  description = "OCID of the Database Security List"
  value       = oci_core_security_list.truth_db_security_list.id
}

output "db_allowed_cidr" {
  description = "CIDR block allowed to access database (Private Subnet only)"
  value       = var.private_subnet_cidr
}

# --------------------------------------------------
# Database Backup & Recovery Outputs
# --------------------------------------------------

output "db_backup_retention_days" {
  description = "Database backup retention period in days"
  value       = var.db_backup_retention_days
}

output "db_pitr_enabled" {
  description = "Point-in-Time Recovery (PITR) enabled status"
  value       = true
}

output "db_rpo_minutes" {
  description = "Recovery Point Objective (RPO) in minutes"
  value       = 15 # Achieved via WAL archiving every 5 minutes
}

# --------------------------------------------------
# Database Configuration Summary
# --------------------------------------------------

output "db_deployment_summary" {
  description = "Summary of database deployment (INF-02)"
  value = {
    db_name              = var.db_name
    db_version           = var.db_version
    deployment_subnet    = "Private Subnet (10.0.2.0/24)"
    access_restriction   = "OKE Cluster Only (No Public Access)"
    backup_retention     = "${var.db_backup_retention_days} days"
    pitr_enabled         = true
    rpo_target           = "< 15 minutes"
    instance_count       = var.db_instance_count
    high_availability    = var.db_instance_count > 1 ? "Enabled" : "Disabled"
    encryption_at_rest   = "Enabled (OCI managed)"
    encryption_in_transit = "Enabled (TLS required)"
  }
}

# ========================================================================
# VAULT & SECRETS OUTPUTS (INF-03)
# ========================================================================

# --------------------------------------------------
# Vault Outputs
# --------------------------------------------------

output "vault_id" {
  description = "OCID of the HSM-protected Vault"
  value       = oci_kms_vault.truth_protocol_hsm_vault.id
}

output "vault_name" {
  description = "Name of the Vault"
  value       = oci_kms_vault.truth_protocol_hsm_vault.display_name
}

output "vault_type" {
  description = "Vault protection type (VIRTUAL_PRIVATE = HSM-backed)"
  value       = oci_kms_vault.truth_protocol_hsm_vault.vault_type
}

output "vault_crypto_endpoint" {
  description = "Vault crypto endpoint for encryption/decryption operations"
  value       = oci_kms_vault.truth_protocol_hsm_vault.crypto_endpoint
  sensitive   = true
}

output "vault_management_endpoint" {
  description = "Vault management endpoint for key/secret management"
  value       = oci_kms_vault.truth_protocol_hsm_vault.management_endpoint
  sensitive   = true
}

# --------------------------------------------------
# Master Key Outputs
# --------------------------------------------------

output "master_key_id" {
  description = "OCID of the master encryption key (AES-256)"
  value       = oci_kms_key.truth_protocol_master_key.id
  sensitive   = true
}

output "master_key_algorithm" {
  description = "Master key encryption algorithm"
  value       = "AES-256"
}

output "master_key_protection_mode" {
  description = "Master key protection mode (HSM = hardware-backed)"
  value       = oci_kms_key.truth_protocol_master_key.protection_mode
}

# --------------------------------------------------
# Secrets Outputs
# --------------------------------------------------

output "relayer_private_key_secret_id" {
  description = "OCID of the Relayer private key secret"
  value       = oci_vault_secret.relayer_private_key.id
  sensitive   = true
}

output "db_password_secret_id" {
  description = "OCID of the database password secret"
  value       = oci_vault_secret.db_admin_password.id
  sensitive   = true
}

output "secret_names" {
  description = "Map of secret names to their purposes"
  value = {
    relayer_key = oci_vault_secret.relayer_private_key.secret_name
    db_password = oci_vault_secret.db_admin_password.secret_name
  }
}

# --------------------------------------------------
# IAM Outputs
# --------------------------------------------------

output "dynamic_group_id" {
  description = "OCID of the IAM Dynamic Group for OKE worker nodes"
  value       = oci_identity_dynamic_group.dg_truth_oke_workers.id
}

output "dynamic_group_name" {
  description = "Name of the IAM Dynamic Group"
  value       = oci_identity_dynamic_group.dg_truth_oke_workers.name
}

output "iam_policy_id" {
  description = "OCID of the IAM policy for Vault access"
  value       = oci_identity_policy.policy_truth_relayer_access.id
}

output "iam_policy_statements" {
  description = "IAM policy statements (for audit/review)"
  value       = oci_identity_policy.policy_truth_relayer_access.statements
}

# --------------------------------------------------
# Spring Boot Integration Outputs
# --------------------------------------------------

output "spring_boot_vault_config" {
  description = "Spring Boot configuration for OCI Vault integration"
  value = <<-EOT
    # Add to application.yml (Spring Boot)
    oci:
      vault:
        compartment-id: ${var.compartment_ocid}
        vault-id: ${oci_kms_vault.truth_protocol_hsm_vault.id}
        secrets:
          relayer-private-key: ${oci_vault_secret.relayer_private_key.secret_name}
          db-password: ${oci_vault_secret.db_admin_password.secret_name}

    spring:
      cloud:
        oci:
          config:
            instance-principal:
              enabled: true  # Use Instance Principal for authentication
      datasource:
        password: $${oci.vault.secrets.db-password}  # Dynamically loaded from Vault
  EOT
  sensitive   = true
}

output "oci_cli_secret_read_commands" {
  description = "OCI CLI commands to read secrets (for testing)"
  value = <<-EOT
    # Read Relayer private key
    oci secrets secret-bundle get --secret-id ${oci_vault_secret.relayer_private_key.id} --stage CURRENT

    # Read Database password
    oci secrets secret-bundle get --secret-id ${oci_vault_secret.db_admin_password.id} --stage CURRENT

    # Decode secret content (pipe to jq and base64)
    oci secrets secret-bundle get --secret-id ${oci_vault_secret.relayer_private_key.id} --query 'data."secret-bundle-content".content' --raw-output | base64 -d
  EOT
  sensitive   = true
}

# --------------------------------------------------
# Security Compliance Summary
# --------------------------------------------------

output "vault_security_summary" {
  description = "Summary of Vault security configuration (INF-03)"
  value = {
    vault_protection       = "HSM (FIPS 140-2 Level 3)"
    encryption_algorithm   = "AES-256"
    secret_count          = 2
    iam_dynamic_group     = oci_identity_dynamic_group.dg_truth_oke_workers.name
    access_control        = "Least-Privilege (READ-only)"
    audit_logging         = "Enabled (OCI Audit Service)"
    lifecycle_protection  = "Enabled (prevent_destroy)"
    secret_rotation       = var.enable_secret_rotation ? "Enabled (90-day)" : "Disabled"
  }
}
