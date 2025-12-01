# TRUTH Protocol - OCI Infrastructure (OKE Cluster)

## Overview

This Terraform module deploys the **TRUTH Protocol OCI Infrastructure** including:

- **VCN (Virtual Cloud Network)** with CIDR `10.0.0.0/16`
- **Public Subnet** (`10.0.1.0/24`) for Load Balancers & Ingress
- **Private Subnet** (`10.0.2.0/24`) for OKE Worker Nodes & Database
- **OKE Cluster** (Oracle Kubernetes Engine) with **Private Control Plane**
- **Networking Components**: Internet Gateway, NAT Gateway, Service Gateway
- **Security**: Security Lists, Route Tables, Pod Security Policy

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                  OCI Region (us-phoenix-1)                  │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐   │
│  │  VCN: truth_protocol_vcn (10.0.0.0/16)             │   │
│  │                                                      │   │
│  │  ┌──────────────────┐    ┌──────────────────────┐  │   │
│  │  │  Public Subnet   │    │  Private Subnet      │  │   │
│  │  │  (10.0.1.0/24)   │    │  (10.0.2.0/24)       │  │   │
│  │  │                  │    │                      │  │   │
│  │  │  - Load Balancer │    │  - OKE Worker Nodes  │  │   │
│  │  │  - Ingress       │    │  - Database          │  │   │
│  │  │                  │    │  - OKE Control Plane │  │   │
│  │  └────────┬─────────┘    └──────────┬───────────┘  │   │
│  │           │                          │              │   │
│  │    Internet Gateway            NAT Gateway          │   │
│  │           │                    Service Gateway      │   │
│  └───────────┼────────────────────────┼────────────────┘   │
│              │                        │                    │
│          Internet              OCI Services                │
└─────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### 1. Install Terraform

Download and install Terraform >= 1.5.0:

```bash
# macOS (via Homebrew)
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installation
terraform version
```

### 2. Install OCI CLI

```bash
# macOS/Linux
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Configure OCI CLI
oci setup config
```

### 3. Generate OCI API Keys

```bash
# Create .oci directory
mkdir -p ~/.oci

# Generate API key pair
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem

# Get fingerprint
openssl rsa -pubout -outform DER -in ~/.oci/oci_api_key.pem | openssl md5 -c

# Upload public key to OCI Console: Profile > API Keys > Add API Key
```

### 4. Prepare Variables File

```bash
# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your OCI credentials
vim terraform.tfvars
```

---

## Deployment Steps

### Step 1: Initialize Terraform

```bash
cd truth-protocol-devops/oci-infra/oke-cluster
terraform init
```

### Step 2: Validate Configuration

```bash
# Check syntax
terraform validate

# Format code
terraform fmt

# Preview changes
terraform plan
```

### Step 3: Deploy Infrastructure

```bash
# Apply configuration (will prompt for confirmation)
terraform apply

# Auto-approve (use with caution)
terraform apply -auto-approve
```

Expected output:

```
Apply complete! Resources: 15 added, 0 changed, 0 destroyed.

Outputs:

oke_cluster_ocid = "ocid1.cluster.oc1.phx.aaaaa..."
deployment_summary = {
  cluster_name    = "truth-protocol-oke-cluster"
  cluster_version = "v1.28.2"
  environment     = "dev"
  node_count      = 3
  project         = "TRUTH-Protocol"
  region          = "us-phoenix-1"
}
```

### Step 4: Configure kubectl Access

```bash
# Generate kubeconfig (output from terraform)
oci ce cluster create-kubeconfig \
  --cluster-id <OKE_CLUSTER_OCID> \
  --file $HOME/.kube/config \
  --region us-phoenix-1 \
  --token-version 2.0.0

# Verify connection
kubectl get nodes
kubectl cluster-info
```

**Note**: If using **Private Endpoint**, you must access via:

- **Bastion Host** in the same VCN
- **VPN Connection** to the VCN
- **OCI Cloud Shell** (already in VCN)

---

## Post-Deployment Tasks

### 1. Install Kubernetes Dashboard (Optional)

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Create admin user
kubectl create serviceaccount dashboard-admin -n kubernetes-dashboard
kubectl create clusterrolebinding dashboard-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=kubernetes-dashboard:dashboard-admin

# Get access token
kubectl -n kubernetes-dashboard create token dashboard-admin
```

### 2. Install NGINX Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Verify Load Balancer creation
kubectl get svc -n ingress-nginx
```

### 3. Install Cert-Manager (for TLS)

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

---

## Database Configuration (INF-02)

This module deploys a **PostgreSQL database** in the **Private Subnet** with enterprise-grade security and backup policies.

### Database Architecture

```
┌─────────────────────────────────────────────────────┐
│  Private Subnet (10.0.2.0/24)                       │
│                                                      │
│  ┌──────────────────┐       ┌──────────────────┐   │
│  │  OKE Worker Node │───────│  PostgreSQL DB   │   │
│  │  (10.0.2.x)      │  TCP  │  (10.0.2.10)     │   │
│  └──────────────────┘  5432  │  Port: 5432      │   │
│                               │  Version: 15     │   │
│  ✅ Allowed Access            └──────────────────┘   │
│                                                      │
│  ┌──────────────────┐                               │
│  │  Public Subnet   │       ❌ Access Denied        │
│  │  (10.0.1.0/24)   │────X                          │
│  └──────────────────┘                               │
└─────────────────────────────────────────────────────┘
```

### Security Features (INF-02 Compliance)

✅ **Private-Only Access**: Database has NO public IP
✅ **Network Isolation**: Security List restricts access to OKE cluster only (10.0.2.0/24)
✅ **Encryption**: TLS in-transit + OCI managed encryption at-rest
✅ **Backup Policy**: Daily backups with 30-day retention
✅ **PITR Support**: WAL archiving every 5 minutes (RPO < 15 min)

### Database Connection

After deployment, retrieve the connection string:

```bash
# Get database endpoint
terraform output db_private_endpoint

# Get JDBC URL for Spring Boot
terraform output db_jdbc_url

# Get full Spring Boot configuration
terraform output db_spring_boot_config
```

**Example Output:**

```
db_hostname = "10.0.2.10"
db_port = "5432"
db_jdbc_url = "jdbc:postgresql://10.0.2.10:5432/truthprotocol?ssl=true&sslmode=require"
```

### Connecting from Spring Boot (Backend)

Add to `application.yml`:

```yaml
spring:
  datasource:
    url: jdbc:postgresql://10.0.2.10:5432/truthprotocol?ssl=true&sslmode=require
    username: truthadmin
    password: ${DB_PASSWORD} # Load from OCI Vault (INF-03)
    driver-class-name: org.postgresql.Driver
  jpa:
    database-platform: org.hibernate.dialect.PostgreSQLDialect
    hibernate:
      ddl-auto: validate # Use Flyway for schema migrations
```

### Testing Database Connection

From a **Pod inside OKE cluster**:

```bash
# Deploy a PostgreSQL client pod
kubectl run -it --rm psql-client --image=postgres:15 --restart=Never -- bash

# Connect to database
psql "postgresql://truthadmin:PASSWORD@10.0.2.10:5432/truthprotocol?sslmode=require"

# Run test query
SELECT version();
```

**Note**: Connection will FAIL from outside the VCN (this is correct security behavior).

### Backup & Recovery

#### Manual Backup

```bash
# Create on-demand backup
oci psql backup create \
  --db-system-id <DB_SYSTEM_OCID> \
  --display-name "manual-backup-$(date +%Y%m%d)"
```

#### Point-in-Time Recovery (PITR)

```bash
# Restore to specific timestamp
oci psql db-system restore \
  --db-system-id <DB_SYSTEM_OCID> \
  --recovery-point-time "2025-01-15T10:30:00Z"
```

#### Backup Verification

```bash
# List all backups
terraform output db_system_id | xargs -I {} oci psql backup list --db-system-id {}

# Check backup retention
terraform output db_backup_retention_days
```

### Database Monitoring

The module automatically creates monitoring alarms:

| Alarm               | Threshold   | Action                        |
| ------------------- | ----------- | ----------------------------- |
| CPU Utilization     | > 80%       | CRITICAL alert                |
| Storage Utilization | > 85%       | WARNING alert                 |
| Connection Count    | > 180 (90%) | WARNING (approaching max 200) |

View metrics in OCI Console: **Observability & Management** > **Monitoring**

### Database Maintenance

#### Update PostgreSQL Configuration

```bash
# Edit db.tf to modify configuration
vim db.tf

# Apply changes
terraform plan
terraform apply
```

#### Scale Database Resources

```bash
# Edit terraform.tfvars
db_ocpu_count = 4      # Increase from 2 to 4 OCPUs
db_memory_gb  = 64     # Increase from 32 to 64 GB

# Apply
terraform apply
```

#### Enable High Availability (Production)

```bash
# Edit terraform.tfvars
db_instance_count = 3  # Enable multi-instance HA
environment = "prod"

# Apply
terraform apply
```

### Database Security Checklist

Before going to production:

- [ ] Change default `db_admin_password` in `terraform.tfvars`
- [ ] Migrate password to OCI Vault (see INF-03)
- [ ] Enable database audit logging
- [ ] Configure automated security patching
- [ ] Set up cross-region backup replication (DR)
- [ ] Create read-only database user for reporting
- [ ] Enable query performance insights
- [ ] Configure connection pooling in Spring Boot (HikariCP)

---

## Vault & Secrets Management (INF-03)

This module deploys an **HSM-protected Vault** (FIPS 140-2 Level 3 certified) for secure key management and implements **least-privilege IAM policies** for secret access.

### Vault Architecture

```
┌─────────────────────────────────────────────────────────┐
│  OCI Vault (HSM-Protected)                              │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Master Key (AES-256)                             │  │
│  │  └─ Encrypts all secrets                          │  │
│  └───────────────────────────────────────────────────┘  │
│                                                          │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Secrets                                          │  │
│  │  ├─ relayer_private_key (Blockchain signing)     │  │
│  │  └─ db_admin_password (PostgreSQL credentials)   │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                         ▲
                         │ READ-only access
                         │
┌────────────────────────┴────────────────────────────────┐
│  IAM Dynamic Group: dg_truth_oke_workers                │
│  └─ Matches: OKE Worker Node instances                 │
│                                                          │
│  IAM Policy: policy_truth_relayer_access                │
│  └─ Allows: Read secret-bundles, Use master key        │
└─────────────────────────────────────────────────────────┘
```

### Security Features (INF-03 Compliance)

✅ **HSM Protection**: Vault backed by FIPS 140-2 Level 3 certified hardware
✅ **Master Key Encryption**: AES-256 encryption for all secrets
✅ **Least-Privilege Access**: IAM policy grants READ-only permission to OKE workers
✅ **Dynamic Group Matching**: Automatically includes OKE worker nodes (no manual management)
✅ **Audit Logging**: All secret access logged to OCI Audit Service
✅ **Lifecycle Protection**: `prevent_destroy` enabled on Vault and secrets

### Deploying Vault & Secrets

#### Step 1: Generate Relayer Private Key

```bash
# Option 1: Generate new Ethereum key (secp256k1)
openssl ecparam -name secp256k1 -genkey -noout -out relayer_private.pem
openssl ec -in relayer_private.pem -text -noout | grep 'priv:' -A 3 | tail -n +2 | tr -d '\n: '

# Option 2: Use existing MetaMask/Hardhat wallet
# Export private key from MetaMask (remove 0x prefix)

# Save to environment variable (NEVER commit to Git!)
export TF_VAR_relayer_private_key_value="your_64_char_hex_key"
```

#### Step 2: Configure Secrets in terraform.tfvars

```bash
# Edit terraform.tfvars (CRITICAL: This file is gitignored)
vim terraform.tfvars

# Add:
relayer_private_key_value = "abc123..."  # Your real private key
db_admin_password_value = "SecurePassword123!"  # Database password
```

#### Step 3: Deploy Vault

```bash
# Deploy Vault infrastructure
terraform plan -target=oci_kms_vault.truth_protocol_hsm_vault
terraform apply -target=oci_kms_vault.truth_protocol_hsm_vault

# Deploy secrets
terraform apply
```

#### Step 4: Verify Deployment

```bash
# Get Vault details
terraform output vault_id
terraform output vault_security_summary

# Test secret access from OKE worker node (via kubectl exec)
kubectl run -it --rm vault-test --image=oraclelinux:8 --restart=Never -- bash

# Inside the pod, install OCI CLI
curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh | bash

# Read secret using Instance Principal
oci secrets secret-bundle get \
  --secret-id <SECRET_OCID> \
  --auth instance_principal
```

### Accessing Secrets from Spring Boot

The module outputs a ready-to-use Spring Boot configuration. Add to `application.yml`:

```yaml
# Get configuration
terraform output spring_boot_vault_config

# Example output:
oci:
  vault:
    compartment-id: ocid1.compartment...
    vault-id: ocid1.vault...
    secrets:
      relayer-private-key: relayer_private_key
      db-password: db_admin_password

spring:
  cloud:
    oci:
      config:
        instance-principal:
          enabled: true  # Authenticate using Instance Principal (no credentials needed)
  datasource:
    password: ${oci.vault.secrets.db-password}  # Dynamically loaded from Vault
```

#### Java Code Example

```java
import com.oracle.bmc.auth.InstancePrincipalsAuthenticationDetailsProvider;
import com.oracle.bmc.secrets.SecretsClient;
import com.oracle.bmc.secrets.requests.GetSecretBundleByNameRequest;
import com.oracle.bmc.secrets.responses.GetSecretBundleByNameResponse;

import java.util.Base64;

public class VaultService {
    private final SecretsClient secretsClient;

    public VaultService() {
        // Authenticate using Instance Principal (OKE worker node identity)
        this.secretsClient = SecretsClient.builder()
            .build(InstancePrincipalsAuthenticationDetailsProvider.builder().build());
    }

    public String getRelayerPrivateKey(String vaultId) {
        GetSecretBundleByNameRequest request = GetSecretBundleByNameRequest.builder()
            .secretName("relayer_private_key")
            .vaultId(vaultId)
            .build();

        GetSecretBundleByNameResponse response = secretsClient.getSecretBundleByName(request);

        String base64Content = response.getSecretBundle()
            .getSecretBundleContent()
            .getContent();

        return new String(Base64.getDecoder().decode(base64Content));
    }
}
```

### IAM Dynamic Group Matching Rule

The Dynamic Group automatically includes OKE worker nodes using this rule:

```hcl
ALL {
  resource.type = 'instance',
  resource.compartment.id = '<COMPARTMENT_OCID>',
  tag.oke.cluster_id.value = '<OKE_CLUSTER_OCID>'
}
```

**How it works:**
1. OCI automatically tags OKE worker instances with `oke.cluster_id`
2. Dynamic Group matches instances with this tag
3. IAM policy grants secret access to the Dynamic Group
4. No manual instance management required (auto-scales with cluster)

### Secret Rotation (Production)

For production environments, enable automatic secret rotation:

```bash
# Edit terraform.tfvars
enable_secret_rotation = true
rotation_function_id = "ocid1.fnfunc.oc1.phx.aaaa..."  # Your OCI Function OCID

# Apply changes
terraform apply
```

**Rotation Process:**
1. OCI Vault triggers rotation every 90 days
2. OCI Function generates new secret value
3. Vault creates new secret version (old version remains accessible)
4. Application automatically uses latest version
5. Old versions retired after 30 days

### Security Best Practices

#### Production Checklist

- [ ] Replace default `relayer_private_key_value` with real key
- [ ] Store secrets in environment variables (not terraform.tfvars)
- [ ] Enable secret rotation for production
- [ ] Set up cross-region Vault replication (DR)
- [ ] Configure Vault deletion protection (prevent accidental deletion)
- [ ] Enable OCI Audit logging alerts for secret access
- [ ] Review IAM policy statements (least-privilege)
- [ ] Test secret access from OKE pods before deployment
- [ ] Document secret recovery procedures
- [ ] Configure secret expiration alerts

#### Environment Variable Deployment

Instead of `terraform.tfvars`, use environment variables:

```bash
# Set secrets via environment variables
export TF_VAR_relayer_private_key_value="your_private_key"
export TF_VAR_db_admin_password_value="your_db_password"

# Deploy without exposing secrets in files
terraform apply
```

### Monitoring & Audit

#### View Secret Access Logs

```bash
# Query OCI Audit Service for secret access events
oci audit event list \
  --compartment-id <COMPARTMENT_OCID> \
  --start-time 2025-01-01T00:00:00Z \
  --end-time 2025-01-31T23:59:59Z \
  --query "data[?\"event-name\"=='GetSecretBundle'].{time:\"event-time\",user:\"principal-name\",secret:\"resource-name\"}" \
  --output table
```

#### Set Up Alerts

```bash
# Create notification topic
oci ons topic create --name vault-access-alerts --compartment-id <OCID>

# Create alarm rule for unusual secret access
oci monitoring alarm create \
  --display-name "High Secret Access Rate" \
  --compartment-id <COMPARTMENT_OCID> \
  --namespace oci_vaults \
  --query "SecretAccess[1m].count() > 100" \
  --severity CRITICAL
```

### Troubleshooting

#### Issue: "Instance Principal authentication failed"

**Solution**: Verify Dynamic Group includes OKE worker instances:

```bash
# Check instance tags
oci compute instance get --instance-id <INSTANCE_OCID> --query 'data."defined-tags"'

# Verify Dynamic Group matching rule
terraform output dynamic_group_id
oci iam dynamic-group get --dynamic-group-id <DYNAMIC_GROUP_OCID>
```

#### Issue: "Permission denied reading secret"

**Solution**: Verify IAM policy grants access:

```bash
# Check IAM policy statements
terraform output iam_policy_statements

# Test secret access manually
oci secrets secret-bundle get \
  --secret-id <SECRET_OCID> \
  --auth instance_principal
```

#### Issue: "Secret not found"

**Solution**: Verify secret exists in Vault:

```bash
# List all secrets in Vault
terraform output vault_id
oci vault secret list --compartment-id <COMPARTMENT_OCID> --vault-id <VAULT_OCID>

# Check secret OCID
terraform output relayer_private_key_secret_id
```

### Cost Estimation (Vault)

**Monthly Costs:**

| Resource                  | Quantity | Unit Price (US) | Monthly Cost |
| ------------------------- | -------- | --------------- | ------------ |
| OCI Vault (HSM)          | 1        | $1.00/vault     | $1.00        |
| Master Key               | 1        | $1.00/key       | $1.00        |
| Secrets (active versions)| 2        | $0.05/version   | $0.10        |
| Secret access (10K/day)  | 300K     | $0.03/10K calls | $0.90        |
| **Total**                |          |                 | **~$3.00**   |

**Note**: HSM-protected Vaults are significantly more expensive than software-protected Vaults, but provide FIPS 140-2 Level 3 compliance required for financial/blockchain applications.

---

## Infrastructure Outputs

### OKE Cluster Outputs

| Output                   | Description                                 |
| ------------------------ | ------------------------------------------- |
| `oke_cluster_ocid`       | OKE Cluster OCID (for IAM & DB access)      |
| `vcn_id`                 | VCN OCID                                    |
| `public_subnet_id`       | Public Subnet OCID (Load Balancer)          |
| `private_subnet_id`      | Private Subnet OCID (Worker Nodes, DB)      |
| `kubeconfig_command`     | Command to generate kubectl config          |
| `deployment_summary`     | Summary of deployed resources               |

### Database Outputs (INF-02)

| Output                      | Description                                      |
| --------------------------- | ------------------------------------------------ |
| `db_system_id`              | PostgreSQL Database System OCID                  |
| `db_hostname`               | Database private IP (e.g., 10.0.2.10)            |
| `db_port`                   | Database port (5432)                             |
| `db_jdbc_url`               | JDBC connection URL for Spring Boot              |
| `db_connection_string`      | Standard PostgreSQL connection string            |
| `db_spring_boot_config`     | Complete Spring Boot datasource configuration    |
| `db_deployment_summary`     | Summary of DB deployment (backup, encryption, HA)|

---

## Cost Estimation

**Estimated Monthly Cost (Development Environment)**:

| Resource                | Quantity | Unit Price (US)    | Monthly Cost |
| ----------------------- | -------- | ------------------ | ------------ |
| OKE Cluster (Free Tier) | 1        | $0.00              | $0.00        |
| VM.Standard.E4.Flex     | 3 nodes  | $0.03/OCPU-hour    | ~$129.60     |
| PostgreSQL DB (2 OCPU)  | 1        | $0.068/OCPU-hour   | ~$97.92      |
| DB Storage (100GB)      | 100 GB   | $0.17/GB-month     | ~$17.00      |
| Load Balancer           | 1        | $0.0225/hour       | ~$16.20      |
| NAT Gateway             | 1        | $0.045/hour        | ~$32.40      |
| **Total**               |          |                    | **~$293.12** |

**Production Cost** (with autoscaling + HA database): **~$700-1200/month**

**Cost Breakdown by Component:**
- **OKE Infrastructure**: ~$178/month (nodes + networking)
- **PostgreSQL Database**: ~$115/month (compute + storage + backups)
- **Scaling Multiplier**: 2-4x for production (HA, redundancy, performance)

---

## Maintenance & Operations

### Update Kubernetes Version

```bash
# Check available versions
oci ce cluster-options get --cluster-option-id all

# Update variables.tf
kubernetes_version = "v1.29.1"

# Apply changes
terraform plan
terraform apply
```

### Scale Node Pool

```bash
# Edit terraform.tfvars
node_pool_size = 5

# Apply
terraform apply
```

### Destroy Infrastructure

```bash
# Preview deletion
terraform plan -destroy

# Delete all resources (CAUTION: IRREVERSIBLE)
terraform destroy
```

---

## Troubleshooting

### Issue: "Error 401: NotAuthenticated"

**Solution**: Verify OCI credentials in `terraform.tfvars`:

```bash
# Test OCI CLI authentication
oci iam region list
```

### Issue: "Error: subnet not found"

**Solution**: Ensure VCN and subnets are created before OKE cluster:

```bash
terraform apply -target=oci_core_vcn.truth_protocol_vcn
terraform apply
```

### Issue: "Cannot connect to kubectl"

**Solution**: Regenerate kubeconfig:

```bash
rm ~/.kube/config
oci ce cluster create-kubeconfig --cluster-id <CLUSTER_OCID> --file ~/.kube/config
```

---

## Security Best Practices

1. **Private Control Plane**: Always use `PRIVATE` endpoint for production
2. **Secrets Management**: Use OCI Vault for sensitive data (see `vault-config/`)
3. **Network Segmentation**: Keep databases in private subnet
4. **Pod Security**: Enable Pod Security Policy & Network Policy
5. **RBAC**: Use Kubernetes Role-Based Access Control
6. **TLS**: Enforce HTTPS via Cert-Manager & Ingress

---

## Next Steps

After deploying OKE infrastructure, proceed to:

1. **[INF-02] Deploy PostgreSQL Database** → `../db.tf`
2. **[INF-03] Configure OCI Vault** → `../vault-config/`
3. **[BE-01] Deploy Spring Boot API** → `../../truth-protocol-backend/`

---

## Support & References

- **OCI Terraform Provider**: https://registry.terraform.io/providers/oracle/oci/latest/docs
- **OKE Documentation**: https://docs.oracle.com/en-us/iaas/Content/ContEng/home.htm
- **Kubernetes Best Practices**: https://kubernetes.io/docs/setup/best-practices/
- **TRUTH Protocol Architecture**: See `TRUTH Protocol - APP 架構書.md`

---

## License

Copyright © 2025 TRUTH Protocol. All rights reserved.
