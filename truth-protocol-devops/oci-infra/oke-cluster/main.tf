# ========================================================================
# TRUTH Protocol - OCI Infrastructure (OKE Cluster)
# ========================================================================
# Task: INF-01 - OCI Cloud Environment & Kubernetes (OKE) Initialization
# Purpose: Deploy a production-ready Kubernetes cluster on OCI with:
#   - VCN (Virtual Cloud Network)
#   - Public Subnet (Load Balancer, Ingress)
#   - Private Subnet (OKE Worker Nodes, Database)
#   - OKE Cluster (Private Control Plane)
#   - Secure networking (IGW, NAT, Service Gateway)
# ========================================================================

# ========================================================================
# DATA SOURCES
# ========================================================================

# Fetch available Availability Domains in the region
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Fetch the latest Oracle Linux image for OKE worker nodes
data "oci_core_images" "oracle_linux" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.node_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Fetch OCI Services (for Service Gateway)
data "oci_core_services" "all_oci_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

# ========================================================================
# NETWORK INFRASTRUCTURE
# ========================================================================

# --------------------------------------------------
# VCN (Virtual Cloud Network)
# --------------------------------------------------
resource "oci_core_vcn" "truth_protocol_vcn" {
  compartment_id = var.compartment_ocid
  display_name   = "truth_protocol_vcn"
  dns_label      = "truthvcn"
  cidr_blocks    = [var.vcn_cidr_block]

  freeform_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# --------------------------------------------------
# Internet Gateway (for Public Subnet)
# --------------------------------------------------
resource "oci_core_internet_gateway" "truth_igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.truth_protocol_vcn.id
  display_name   = "truth_protocol_igw"
  enabled        = true

  freeform_tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# --------------------------------------------------
# NAT Gateway (for Private Subnet outbound traffic)
# --------------------------------------------------
resource "oci_core_nat_gateway" "truth_nat" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.truth_protocol_vcn.id
  display_name   = "truth_protocol_nat"
  block_traffic  = false

  freeform_tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# --------------------------------------------------
# Service Gateway (for OCI Service access)
# --------------------------------------------------
resource "oci_core_service_gateway" "truth_service_gw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.truth_protocol_vcn.id
  display_name   = "truth_protocol_service_gw"

  services {
    service_id = data.oci_core_services.all_oci_services.services[0].id
  }

  freeform_tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# ========================================================================
# ROUTE TABLES
# ========================================================================

# --------------------------------------------------
# Public Subnet Route Table (via Internet Gateway)
# --------------------------------------------------
resource "oci_core_route_table" "public_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.truth_protocol_vcn.id
  display_name   = "truth_public_rt"

  route_rules {
    network_entity_id = oci_core_internet_gateway.truth_igw.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    description       = "Default route to Internet"
  }

  freeform_tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# --------------------------------------------------
# Private Subnet Route Table (via NAT + Service Gateway)
# --------------------------------------------------
resource "oci_core_route_table" "private_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.truth_protocol_vcn.id
  display_name   = "truth_private_rt"

  # Route internet-bound traffic via NAT Gateway
  route_rules {
    network_entity_id = oci_core_nat_gateway.truth_nat.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    description       = "Internet via NAT (for updates/Docker pulls)"
  }

  # Route OCI service traffic via Service Gateway
  route_rules {
    network_entity_id = oci_core_service_gateway.truth_service_gw.id
    destination       = data.oci_core_services.all_oci_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    description       = "OCI Services (Object Storage, DB, Vault)"
  }

  freeform_tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# ========================================================================
# SECURITY LISTS
# ========================================================================

# --------------------------------------------------
# Public Subnet Security List
# --------------------------------------------------
resource "oci_core_security_list" "public_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.truth_protocol_vcn.id
  display_name   = "truth_public_sl"

  # Egress: Allow all outbound traffic
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
    description = "Allow all outbound"
  }

  # Ingress: Allow HTTP (80) from Internet
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    stateless   = false
    description = "HTTP from Internet"

    tcp_options {
      min = 80
      max = 80
    }
  }

  # Ingress: Allow HTTPS (443) from Internet
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    stateless   = false
    description = "HTTPS from Internet"

    tcp_options {
      min = 443
      max = 443
    }
  }

  freeform_tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# --------------------------------------------------
# Private Subnet Security List
# --------------------------------------------------
resource "oci_core_security_list" "private_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.truth_protocol_vcn.id
  display_name   = "truth_private_sl"

  # Egress: Allow all outbound traffic
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
    description = "Allow all outbound"
  }

  # Ingress: Allow all traffic from VCN (internal communication)
  ingress_security_rules {
    protocol    = "all"
    source      = var.vcn_cidr_block
    stateless   = false
    description = "Allow all from VCN (Kubernetes, DB, internal services)"
  }

  # Ingress: Allow Kubernetes API (6443) from Public Subnet
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = var.public_subnet_cidr
    stateless   = false
    description = "Kubernetes API access"

    tcp_options {
      min = 6443
      max = 6443
    }
  }

  # Ingress: Allow NodePort services (30000-32767)
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = var.vcn_cidr_block
    stateless   = false
    description = "Kubernetes NodePort range"

    tcp_options {
      min = 30000
      max = 32767
    }
  }

  freeform_tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# ========================================================================
# SUBNETS
# ========================================================================

# --------------------------------------------------
# Public Subnet (Load Balancer, Ingress Controller)
# --------------------------------------------------
resource "oci_core_subnet" "public_subnet" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.truth_protocol_vcn.id
  cidr_block        = var.public_subnet_cidr
  display_name      = "truth_public_subnet"
  dns_label         = "truthpublic"
  route_table_id    = oci_core_route_table.public_rt.id
  security_list_ids = [oci_core_security_list.public_sl.id]

  # Public subnet requires internet access
  prohibit_public_ip_on_vnic = false

  freeform_tags = {
    Project     = var.project_name
    Environment = var.environment
    Tier        = "Public"
  }
}

# --------------------------------------------------
# Private Subnet (OKE Worker Nodes, Database)
# --------------------------------------------------
resource "oci_core_subnet" "private_subnet" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.truth_protocol_vcn.id
  cidr_block        = var.private_subnet_cidr
  display_name      = "truth_private_subnet"
  dns_label         = "truthprivate"
  route_table_id    = oci_core_route_table.private_rt.id
  security_list_ids = [oci_core_security_list.private_sl.id]

  # Private subnet - no direct internet access
  prohibit_public_ip_on_vnic = true

  freeform_tags = {
    Project     = var.project_name
    Environment = var.environment
    Tier        = "Private"
  }
}

# ========================================================================
# OKE CLUSTER (Oracle Kubernetes Engine)
# ========================================================================

resource "oci_containerengine_cluster" "truth_oke_cluster" {
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.kubernetes_version
  name               = var.cluster_name
  vcn_id             = oci_core_vcn.truth_protocol_vcn.id

  # --------------------------------------------------
  # Control Plane Configuration (PRIVATE for security)
  # --------------------------------------------------
  endpoint_config {
    is_public_ip_enabled = var.oke_endpoint_type == "PUBLIC" ? true : false
    subnet_id            = oci_core_subnet.private_subnet.id
  }

  # --------------------------------------------------
  # Cluster Options (Security & Networking)
  # --------------------------------------------------
  options {
    service_lb_subnet_ids = [oci_core_subnet.public_subnet.id]

    # Add-ons
    add_ons {
      is_kubernetes_dashboard_enabled = false # Disable for security (use kubectl/Lens)
      is_tiller_enabled               = false # Helm 3 doesn't need Tiller
    }

    # Pod Security Policy (Enterprise security requirement)
    admission_controller_options {
      is_pod_security_policy_enabled = var.enable_pod_security_policy
    }

    # Network Policy (Calico for micro-segmentation)
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16" # Default Kubernetes pod CIDR
      services_cidr = "10.96.0.0/16"  # Default Kubernetes service CIDR
    }
  }

  freeform_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Component   = "OKE-Cluster"
  }
}

# ========================================================================
# OKE NODE POOL (Worker Nodes)
# ========================================================================

resource "oci_containerengine_node_pool" "truth_node_pool" {
  cluster_id         = oci_containerengine_cluster.truth_oke_cluster.id
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.kubernetes_version
  name               = "truth-protocol-node-pool"

  # --------------------------------------------------
  # Node Configuration (VM Shape & Resources)
  # --------------------------------------------------
  node_shape = var.node_shape

  # Flexible shape configuration (for VM.Standard.E4.Flex)
  node_shape_config {
    ocpus         = var.node_ocpus
    memory_in_gbs = var.node_memory_gb
  }

  # --------------------------------------------------
  # Node Source Details (Oracle Linux 8 Image)
  # --------------------------------------------------
  node_source_details {
    source_type = "IMAGE"
    image_id    = data.oci_core_images.oracle_linux.images[0].id

    # Boot volume size
    boot_volume_size_in_gbs = var.node_boot_volume_size_gb
  }

  # --------------------------------------------------
  # Node Pool Placement (High Availability)
  # --------------------------------------------------
  node_config_details {
    size = var.node_pool_size

    # Deploy nodes in Private Subnet
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.private_subnet.id
    }

    # Additional placement for multi-AD HA (if available)
    dynamic "placement_configs" {
      for_each = length(data.oci_identity_availability_domains.ads.availability_domains) > 1 ? [1] : []
      content {
        availability_domain = data.oci_identity_availability_domains.ads.availability_domains[1].name
        subnet_id           = oci_core_subnet.private_subnet.id
      }
    }

    # Worker node labels (for pod scheduling)
    freeform_tags = {
      Project     = var.project_name
      Environment = var.environment
      NodeRole    = "worker"
    }
  }

  # --------------------------------------------------
  # SSH Access (for troubleshooting - use bastion in production)
  # --------------------------------------------------
  ssh_public_key = file("~/.ssh/id_rsa.pub") # Update with your SSH key path

  freeform_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Component   = "OKE-NodePool"
  }
}

# ========================================================================
# LOCALS & COMPUTED VALUES
# ========================================================================

locals {
  # Common tags to be applied to all resources
  common_tags = {
    Project       = var.project_name
    Environment   = var.environment
    ManagedBy     = "Terraform"
    TerraformPath = "truth-protocol-devops/oci-infra/oke-cluster"
  }

  # Cluster FQDN (for DNS configuration)
  cluster_endpoint = oci_containerengine_cluster.truth_oke_cluster.endpoints[0].private_endpoint
}
