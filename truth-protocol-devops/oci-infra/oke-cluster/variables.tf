# ========================================================================
# TRUTH Protocol - Terraform Variables Definition
# ========================================================================
# Purpose: Define all configurable variables for OCI infrastructure
# Security: Sensitive values should be provided via environment variables
#           or terraform.tfvars (DO NOT commit terraform.tfvars to Git)
# ========================================================================

# --------------------------------------------------
# OCI Authentication Variables
# --------------------------------------------------

variable "tenancy_ocid" {
  description = "OCI Tenancy OCID"
  type        = string
  sensitive   = true
}

variable "user_ocid" {
  description = "OCI User OCID"
  type        = string
  sensitive   = true
}

variable "fingerprint" {
  description = "OCI API Key Fingerprint"
  type        = string
  sensitive   = true
}

variable "private_key_path" {
  description = "Path to OCI API Private Key"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "region" {
  description = "OCI Region (e.g., us-phoenix-1, ap-seoul-1)"
  type        = string
  default     = "us-phoenix-1"
}

variable "compartment_ocid" {
  description = "OCI Compartment OCID for resource deployment"
  type        = string
  sensitive   = true
}

# --------------------------------------------------
# Network Configuration
# --------------------------------------------------

variable "vcn_cidr_block" {
  description = "CIDR block for VCN (Virtual Cloud Network)"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vcn_cidr_block, 0))
    error_message = "VCN CIDR block must be a valid IPv4 CIDR notation."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR block for Public Subnet (Load Balancer, Ingress)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for Private Subnet (OKE Worker Nodes, DB)"
  type        = string
  default     = "10.0.2.0/24"
}

# --------------------------------------------------
# OKE Cluster Configuration
# --------------------------------------------------

variable "cluster_name" {
  description = "Name of the OKE (Oracle Kubernetes Engine) Cluster"
  type        = string
  default     = "truth-protocol-oke-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for OKE cluster (e.g., v1.28.2)"
  type        = string
  default     = "v1.28.2"
}

variable "oke_endpoint_type" {
  description = "OKE API Endpoint type (PRIVATE or PUBLIC)"
  type        = string
  default     = "PRIVATE"

  validation {
    condition     = contains(["PRIVATE", "PUBLIC"], var.oke_endpoint_type)
    error_message = "OKE endpoint type must be either PRIVATE or PUBLIC."
  }
}

variable "node_pool_size" {
  description = "Number of worker nodes in the default node pool"
  type        = number
  default     = 3

  validation {
    condition     = var.node_pool_size >= 1 && var.node_pool_size <= 10
    error_message = "Node pool size must be between 1 and 10."
  }
}

variable "node_shape" {
  description = "Compute shape for OKE worker nodes (e.g., VM.Standard.E4.Flex)"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "node_ocpus" {
  description = "Number of OCPUs for flexible shapes"
  type        = number
  default     = 2
}

variable "node_memory_gb" {
  description = "Memory in GB for flexible shapes"
  type        = number
  default     = 16
}

variable "node_boot_volume_size_gb" {
  description = "Boot volume size in GB for worker nodes"
  type        = number
  default     = 100
}

# --------------------------------------------------
# Project Metadata
# --------------------------------------------------

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "TRUTH-Protocol"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# --------------------------------------------------
# Security & Compliance
# --------------------------------------------------

variable "enable_pod_security_policy" {
  description = "Enable Kubernetes Pod Security Policy (PSP)"
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Enable Kubernetes Network Policy (via Calico)"
  type        = bool
  default     = true
}

# --------------------------------------------------
# High Availability & DR
# --------------------------------------------------

variable "availability_domains" {
  description = "List of Availability Domains for node distribution"
  type        = list(string)
  default     = []
}

# --------------------------------------------------
# Database Configuration (PostgreSQL)
# --------------------------------------------------

variable "db_system_name" {
  description = "Name of the PostgreSQL database system"
  type        = string
  default     = "truth-protocol-db"
}

variable "db_version" {
  description = "PostgreSQL version (e.g., 14, 15)"
  type        = string
  default     = "15"

  validation {
    condition     = contains(["14", "15", "16"], var.db_version)
    error_message = "PostgreSQL version must be 14, 15, or 16."
  }
}

variable "db_shape" {
  description = "Database compute shape"
  type        = string
  default     = "PostgreSQL.VM.Standard.E4.Flex.2.32GB"
}

variable "db_instance_count" {
  description = "Number of database instances (1 for dev, 3 for prod HA)"
  type        = number
  default     = 1

  validation {
    condition     = var.db_instance_count >= 1 && var.db_instance_count <= 3
    error_message = "Database instance count must be between 1 and 3."
  }
}

variable "db_ocpu_count" {
  description = "Number of OCPUs for database instance"
  type        = number
  default     = 2
}

variable "db_memory_gb" {
  description = "Memory in GB for database instance"
  type        = number
  default     = 32
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "truthprotocol"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.db_name))
    error_message = "Database name must start with a letter and contain only lowercase letters, numbers, and underscores."
  }
}

variable "db_admin_username" {
  description = "Database administrator username"
  type        = string
  default     = "truthadmin"
  sensitive   = true
}

variable "db_admin_password" {
  description = "Database administrator password (SENSITIVE - use OCI Vault in production)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_admin_password) >= 12
    error_message = "Database password must be at least 12 characters long."
  }
}

variable "db_private_ip" {
  description = "Private IP address for database (within private subnet CIDR)"
  type        = string
  default     = "10.0.2.10"

  validation {
    condition     = can(regex("^10\\.0\\.2\\.", var.db_private_ip))
    error_message = "Database private IP must be within the private subnet CIDR (10.0.2.0/24)."
  }
}

variable "db_backup_retention_days" {
  description = "Database backup retention period in days (INF-02 requirement: 30 days)"
  type        = number
  default     = 30

  validation {
    condition     = var.db_backup_retention_days >= 7 && var.db_backup_retention_days <= 90
    error_message = "Backup retention must be between 7 and 90 days."
  }
}

variable "db_max_connections" {
  description = "Maximum number of concurrent database connections"
  type        = number
  default     = 200

  validation {
    condition     = var.db_max_connections >= 50 && var.db_max_connections <= 1000
    error_message = "Max connections must be between 50 and 1000."
  }
}

# --------------------------------------------------
# Monitoring & Alarms
# --------------------------------------------------

variable "alarm_notification_topic_id" {
  description = "OCID of the notification topic for database alarms (optional)"
  type        = string
  default     = ""
}

# --------------------------------------------------
# Vault & Secrets Configuration (INF-03)
# --------------------------------------------------

variable "vault_name" {
  description = "Name of the OCI Vault (HSM-protected)"
  type        = string
  default     = "truth_protocol_hsm_vault"
}

variable "master_key_name" {
  description = "Name of the master encryption key"
  type        = string
  default     = "truth_protocol_master_key"
}

variable "relayer_private_key_value" {
  description = "Ethereum private key for Relayer Worker (CRITICAL - NEVER COMMIT TO GIT)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.relayer_private_key_value) == 64 || length(var.relayer_private_key_value) == 66
    error_message = "Ethereum private key must be 64 hex characters (or 66 with 0x prefix)."
  }
}

variable "db_admin_password_value" {
  description = "PostgreSQL administrator password (same as db_admin_password, but used for Vault storage)"
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition     = var.db_admin_password_value == "" || length(var.db_admin_password_value) >= 12
    error_message = "Database password must be at least 12 characters long if provided."
  }
}

variable "enable_secret_rotation" {
  description = "Enable automatic secret rotation (90-day interval)"
  type        = bool
  default     = false
}

variable "rotation_function_id" {
  description = "OCID of OCI Function for secret rotation (required if enable_secret_rotation = true)"
  type        = string
  default     = ""
}
