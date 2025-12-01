# ========================================================================
# TRUTH Protocol - OCI Provider Configuration
# ========================================================================
# Purpose: Configure the Oracle Cloud Infrastructure (OCI) Terraform Provider
# Docs: https://registry.terraform.io/providers/oracle/oci/latest/docs
# ========================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }

  # Optional: Uncomment for remote state management (e.g., OCI Object Storage)
  # backend "s3" {
  #   bucket                      = "truth-protocol-terraform-state"
  #   key                         = "oke-cluster/terraform.tfstate"
  #   region                      = "us-phoenix-1"
  #   endpoint                    = "https://<namespace>.compat.objectstorage.us-phoenix-1.oraclecloud.com"
  #   skip_region_validation      = true
  #   skip_credentials_validation = true
  #   skip_metadata_api_check     = true
  #   force_path_style            = true
  # }
}

# OCI Provider Configuration
# Authentication via API Key (recommended) or Instance Principal
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}
