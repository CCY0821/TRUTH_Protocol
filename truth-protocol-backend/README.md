# TRUTH Protocol Backend

> Trusted Physical Asset Traceability Platform - Spring Boot 3 Backend Service

[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.x-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Java](https://img.shields.io/badge/Java-21-orange.svg)](https://openjdk.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-blue.svg)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [API Endpoints](#api-endpoints)
- [Testing](#testing)
- [Deployment](#deployment)
- [Advanced Topics](#advanced-topics)
- [Contributing](#contributing)

---

## 🎯 Overview

**TRUTH Protocol** is a decentralized platform for minting and verifying **Soulbound Tokens (SBTs)** that represent physical asset certifications. The backend service handles user authentication, credit management, asynchronous credential minting, blockchain integration, and permanent metadata storage.

### Key Features

- 🔐 **JWT Authentication** - Secure stateless authentication with role-based access control
- 💳 **Credits System** - Atomic credit deduction with pessimistic locking
- 🔄 **Async Minting** - Spring Batch for scalable credential processing
- ⛓️ **Blockchain Integration** - Web3j for Polygon PoS transaction signing
- 📦 **Permanent Storage** - Arweave for immutable metadata storage
- 🔔 **Auto Confirmation** - Scheduled task for blockchain transaction monitoring
- ☁️ **OCI Vault** - Secure key management with Instance Principal auth

### Invisible Tech Philosophy

Users interact with a simple REST API without needing to understand:
- Blockchain transaction complexities
- Gas fees and nonce management
- Metadata storage locations
- Asynchronous processing queues

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    REST API Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │Auth          │  │Credential    │  │Batch Job     │      │
│  │Controller    │  │Controller    │  │Controller    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                   Service Layer                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │AuthService   │  │Credential    │  │Confirmation  │      │
│  │(BCrypt)      │  │Service       │  │Service       │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│              Repository Layer (JPA)                          │
│  ┌──────────────┐  ┌──────────────┐                         │
│  │User          │  │Credential    │                         │
│  │Repository    │  │Repository    │                         │
│  └──────────────┘  └──────────────┘                         │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                PostgreSQL Database                           │
│  ┌──────────────┐  ┌──────────────┐                         │
│  │users         │  │credentials   │                         │
│  │(BCrypt hash) │  │(state machine│                         │
│  └──────────────┘  └──────────────┘                         │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│              Async Workers (Background)                       │
├──────────────────────────────────────────────────────────────┤
│  Spring Batch Job (Manual/Scheduled)                         │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ QUEUED → Arweave Upload → Blockchain TX → PENDING  │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                               │
│  @Scheduled Confirmation Service (Every 60s)                 │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ PENDING → Check Confirmations → Extract tokenId    │    │
│  │         → CONFIRMED                                 │    │
│  └─────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│            External Integrations                              │
├──────────────────────────────────────────────────────────────┤
│  • OCI Vault (Relayer Private Key)                           │
│  • Arweave (Permanent Metadata Storage)                      │
│  • Polygon PoS (SBT Smart Contract)                          │
└──────────────────────────────────────────────────────────────┘
```

### Credential Lifecycle

```
User Request → QUEUED → PENDING → CONFIRMED
               ↓        ↓         ↓
            (created) (tx sent) (tokenId extracted)
```

---

## 🛠️ Tech Stack

### Core Framework
- **Spring Boot 3** - Application framework
- **Spring Security 6** - JWT authentication & authorization
- **Spring Data JPA** - Database access layer
- **Spring Batch** - Asynchronous job processing
- **Spring Scheduling** - Cron-based tasks

### Database
- **PostgreSQL 14+** - Primary database
- **Flyway** - Database migration management
- **HikariCP** - Connection pooling

### Blockchain & Storage
- **Web3j 4.9+** - Ethereum/Polygon interaction
- **WebClient** - Arweave HTTP client
- **OCI SDK** - Vault secret management

### Security
- **BCrypt** - Password hashing (cost factor 10)
- **JJWT** - JWT token generation & validation
- **Instance Principal** - OCI authentication

### Build & Testing
- **Gradle 8.x** - Build tool
- **JUnit 5** - Testing framework
- **Mockito** - Mocking framework

---

## 📋 Prerequisites

### Required
- **Java 21** or higher ([Download OpenJDK](https://adoptium.net/))
- **PostgreSQL 14+** ([Download](https://www.postgresql.org/download/))
- **Gradle 8.x** (included via wrapper)

### Optional (for production)
- **Docker** ([Download](https://www.docker.com/))
- **OCI Account** (for Vault and deployment)
- **Polygon RPC Access** (Alchemy, Infura, or self-hosted node)

### Verify Installation

```bash
# Check Java version
java -version
# Expected: openjdk 21.x.x

# Check PostgreSQL
psql --version
# Expected: psql (PostgreSQL) 14.x

# Check Gradle (via wrapper)
./gradlew --version
# Expected: Gradle 8.x
```

---

## 🚀 Getting Started

### 1. Clone Repository

```bash
git clone https://github.com/your-org/truth-protocol-backend.git
cd truth-protocol-backend
```

### 2. Database Setup

```bash
# Create database
createdb truthprotocol

# Or using psql
psql -U postgres
CREATE DATABASE truthprotocol;
\q
```

### 3. Configure Environment Variables

Create `.env` file or set environment variables:

```bash
# Database
export DB_PASSWORD="your-secure-password"

# Security
export JWT_SECRET=$(openssl rand -base64 32)
export JWT_EXPIRATION=86400000  # 24 hours

# Blockchain
export POLYGON_RPC_URL="https://rpc-mumbai.maticvigil.com"
export POLYGON_CHAIN_ID=80001  # Mumbai Testnet
export SBT_CONTRACT_ADDRESS="0x..."

# OCI Vault (Production only)
export OCI_COMPARTMENT_OCID="ocid1.compartment.oc1..aaaaaa"
export OCI_VAULT_ID="ocid1.vault.oc1.phx.aaaaaa"
```

### 4. Build & Run

```bash
# Build project
./gradlew clean build

# Run application
./gradlew bootRun

# Or with specific profile
./gradlew bootRun --args='--spring.profiles.active=dev'
```

### 5. Verify Deployment

Open browser and navigate to:
- **Swagger UI**: http://localhost:8080/swagger-ui.html
- **Health Check**: http://localhost:8080/actuator/health

Expected health response:
```json
{
  "status": "UP"
}
```

---

## ⚙️ Configuration

### Application Profiles

The application supports multiple profiles:

- **default** - Production settings
- **dev** - Development with verbose logging
- **test** - Testing configuration

Activate profile:
```bash
# Via command line
java -jar app.jar --spring.profiles.active=dev

# Via environment variable
export SPRING_PROFILES_ACTIVE=dev
```

### Key Configuration Files

- **`application.yml`** - Main configuration
- **`application-dev.yml`** - Development overrides
- **`application-prod.yml`** - Production overrides

### Essential Properties

#### Database Configuration
```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/truthprotocol
    username: truthadmin
    password: ${DB_PASSWORD}
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
```

#### JWT Configuration
```yaml
app:
  security:
    jwt:
      secret: ${JWT_SECRET}
      expiration: ${JWT_EXPIRATION:86400000}  # 24 hours
```

#### Blockchain Configuration
```yaml
app:
  relayer:
    rpc-url: ${POLYGON_RPC_URL}
    chain-id: ${POLYGON_CHAIN_ID}
    contract:
      sbt: ${SBT_CONTRACT_ADDRESS}
```

#### OCI Vault Configuration
```yaml
oci:
  vault:
    compartment-id: ${OCI_COMPARTMENT_OCID}
    vault-id: ${OCI_VAULT_ID}
    secrets:
      relayer-private-key: relayer_private_key
```

#### Scheduling Configuration
```yaml
spring:
  task:
    scheduling:
      pool:
        size: 2
      thread-name-prefix: "truth-scheduler-"
```

---

## 🔌 API Endpoints

### Documentation
- **Swagger UI**: `GET /swagger-ui.html`
- **OpenAPI Spec**: `GET /v3/api-docs`

### Authentication

#### Login
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "issuer@example.com",
  "password": "SecurePass123!"
}
```

Response:
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "tokenType": "Bearer",
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "email": "issuer@example.com",
  "role": "ISSUER"
}
```

### Credential Minting

#### Mint Credential
```http
POST /api/v1/credentials/mint
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json

{
  "recipientWalletAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
  "issuerRefId": "CERT-2024-001",
  "metadata": {
    "title": "Organic Certification",
    "description": "USDA Organic Certificate",
    "attributes": [
      {
        "trait_type": "Certification Body",
        "value": "USDA"
      }
    ]
  }
}
```

Response:
```json
{
  "jobId": "550e8400-e29b-41d4-a716-446655440001",
  "status": "QUEUED",
  "message": "Credential minting request accepted..."
}
```

**Required Role**: `ISSUER`

### Batch Job Management

#### Trigger Minting Job (Admin Only)
```http
POST /api/v1/batch/mint
Authorization: Bearer {ADMIN_JWT_TOKEN}
```

Response:
```json
{
  "message": "Minting job triggered successfully"
}
```

**Required Role**: `ADMIN`

### Health & Monitoring

#### Health Check
```http
GET /actuator/health
```

Response:
```json
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP"
    },
    "diskSpace": {
      "status": "UP"
    }
  }
}
```

#### Metrics
```http
GET /actuator/metrics
GET /actuator/prometheus  # Prometheus format
```

---

## 🧪 Testing

### Run All Tests

```bash
./gradlew test
```

### Run Specific Test Class

```bash
./gradlew test --tests com.truthprotocol.service.AuthServiceTest
```

### Generate Coverage Report

```bash
./gradlew jacocoTestReport

# View report
open build/reports/jacoco/test/html/index.html
```

### Integration Tests

```bash
./gradlew integrationTest
```

### Test Configuration

Configure test database in `application-test.yml`:

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/truthprotocol_test
  jpa:
    hibernate:
      ddl-auto: create-drop
```

---

## 🐳 Deployment

### Docker Build

#### Using Spring Boot Build Image (Recommended)

```bash
# Build optimized layered image
./gradlew bootBuildImage --imageName=truth-protocol-backend:latest

# Run container
docker run -p 8080:8080 \
  -e DB_PASSWORD=secure123 \
  -e JWT_SECRET=your-secret \
  truth-protocol-backend:latest
```

#### Using Dockerfile

```dockerfile
# Multi-stage build
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app
COPY . .
RUN ./gradlew clean build -x test

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

Build and run:
```bash
docker build -t truth-protocol-backend:latest .
docker run -p 8080:8080 truth-protocol-backend:latest
```

### Docker Compose

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:14-alpine
    environment:
      POSTGRES_DB: truthprotocol
      POSTGRES_USER: truthadmin
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  backend:
    image: truth-protocol-backend:latest
    depends_on:
      - postgres
    environment:
      DB_PASSWORD: ${DB_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
      POLYGON_RPC_URL: ${POLYGON_RPC_URL}
    ports:
      - "8080:8080"

volumes:
  postgres_data:
```

Run:
```bash
docker-compose up -d
```

### Kubernetes Deployment

See `k8s/` directory for Kubernetes manifests:
- `deployment.yaml` - Application deployment
- `service.yaml` - Load balancer service
- `configmap.yaml` - Configuration
- `secrets.yaml` - Sensitive data

Deploy:
```bash
kubectl apply -f k8s/
```

---

## 🔬 Advanced Topics

### Concurrency Safety

#### Pessimistic Locking for Credit Deduction

To prevent race conditions when deducting credits, we use JPA pessimistic locking:

```java
@Query("SELECT u FROM User u WHERE u.id = :id")
@Lock(LockModeType.PESSIMISTIC_WRITE)
Optional<User> findByIdForUpdate(@Param("id") UUID id);
```

This ensures atomic credit deduction:
1. Lock user record
2. Check balance
3. Deduct credits
4. Save user
5. Release lock (on transaction commit)

**Database Lock**: `SELECT ... FOR UPDATE`

### Asynchronous Processing Flow

#### Batch Job (QUEUED → PENDING)

```java
@Bean
public Job mintingJob() {
    return jobBuilder
        .start(mintingStep())
        .build();
}
```

**Process**:
1. **ItemReader**: Query QUEUED credentials (paginated)
2. **ItemProcessor**: 
   - Upload metadata to Arweave
   - Sign and broadcast blockchain transaction
   - Update status to PENDING
3. **ItemWriter**: Batch save all processed credentials

**Chunk Size**: 10 credentials per transaction

#### Scheduled Confirmation (PENDING → CONFIRMED)

```java
@Scheduled(fixedRate = 60000)  // Every 60 seconds
public void processPendingCredentials() {
    // 1. Query PENDING credentials
    // 2. Check transaction confirmations (>= 12 blocks)
    // 3. Extract tokenId from event logs
    // 4. Update to CONFIRMED
}
```

**Confirmation Requirements**:
- Minimum confirmations: 12 blocks (~24 seconds on Polygon)
- Token ID extracted from `Minted(uint256 tokenId, address recipient)` event

### Web3 Transaction Signing

#### Key Retrieval from OCI Vault

```java
// Instance Principal authentication (no credentials needed)
InstancePrincipalsAuthenticationDetailsProvider provider = 
    InstancePrincipalsAuthenticationDetailsProvider.builder().build();

SecretsClient client = SecretsClient.builder().build(provider);
String privateKey = fetchSecretFromVault(client, secretId);
```

#### Transaction Signing (EIP-155)

```java
// 1. Create credentials
Credentials credentials = Credentials.create(privateKey);

// 2. Get nonce
BigInteger nonce = web3j.ethGetTransactionCount(address, LATEST).send();

// 3. Build transaction
RawTransaction tx = RawTransaction.createTransaction(
    nonce, gasPrice, gasLimit, contractAddress, value, data
);

// 4. Sign with chain ID (EIP-155)
byte[] signedTx = TransactionEncoder.signMessage(tx, chainId, credentials);

// 5. Broadcast
String txHash = web3j.ethSendRawTransaction(Numeric.toHexString(signedTx)).send();
```

### Arweave Metadata Upload

#### Upload Process

```java
// 1. Serialize metadata JSON
String json = objectMapper.writeValueAsString(metadata);

// 2. Create Arweave transaction
Transaction tx = new Transaction();
tx.setData(json.getBytes());
tx.addTag("Content-Type", "application/json");

// 3. Sign with Arweave wallet
tx.sign(jwk);

// 4. Submit to gateway
arweave.transactions.post(tx);

// 5. Return transaction ID (permanent URI)
return tx.getId();  // ar://{txId}
```

**Cost**: ~$0.001-$0.01 per SBT metadata (1-10 KB)

### Database Indexing Strategy

```sql
-- Status index for batch queries
CREATE INDEX idx_credentials_status ON credentials(status);

-- Issuer index for dashboard
CREATE INDEX idx_credentials_issuer_id ON credentials(issuer_id);

-- Composite index for confirmation service
CREATE INDEX idx_credentials_pending ON credentials(status, tx_hash)
  WHERE status = 'PENDING' AND tx_hash IS NOT NULL;
```

### Security Best Practices

- ✅ **No secrets in code** - All sensitive data in environment variables or OCI Vault
- ✅ **BCrypt password hashing** - Cost factor 10 (adjustable)
- ✅ **JWT expiration** - 24 hours (configurable)
- ✅ **CORS configuration** - Restrict origins in production
- ✅ **SQL injection prevention** - Parameterized queries via JPA
- ✅ **Rate limiting** - TODO: Add Spring Cloud Gateway or Nginx
- ✅ **HTTPS only** - Enforce in production

---

## 🤝 Contributing

### Development Workflow

1. Create feature branch: `git checkout -b feature/your-feature`
2. Make changes and commit: `git commit -am 'Add feature'`
3. Run tests: `./gradlew test`
4. Push branch: `git push origin feature/your-feature`
5. Create Pull Request

### Code Style

- Follow [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html)
- Use Lombok for boilerplate reduction
- Write comprehensive JavaDoc for public APIs
- Maintain test coverage > 80%

### Commit Message Convention

```
type(scope): subject

body

footer
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

Example:
```
feat(auth): add password reset functionality

Implement password reset flow with email verification.
Includes new REST endpoint and service layer.

Closes #123
```

---

## 📊 Monitoring & Observability

### Actuator Endpoints

- `/actuator/health` - Health status
- `/actuator/metrics` - Application metrics
- `/actuator/prometheus` - Prometheus-compatible metrics
- `/actuator/loggers` - Log level management
- `/actuator/threaddump` - Thread dump

### Metrics Integration

#### Prometheus

```yaml
management:
  metrics:
    export:
      prometheus:
        enabled: true
```

Scrape config:
```yaml
scrape_configs:
  - job_name: 'truth-protocol-backend'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['localhost:8080']
```

#### Grafana Dashboard

Import dashboard ID: `12900` (Spring Boot 2.x/3.x Dashboard)

---

## 📚 Additional Resources

### Documentation
- [Spring Boot Reference](https://docs.spring.io/spring-boot/docs/current/reference/html/)
- [Spring Security Guide](https://docs.spring.io/spring-security/reference/)
- [Web3j Documentation](https://docs.web3j.io/)
- [Arweave Docs](https://docs.arweave.org/)

### Tools
- [Swagger UI](http://localhost:8080/swagger-ui.html) - API Testing
- [PostgreSQL GUI](https://www.pgadmin.org/) - Database Management
- [Polygon Scan](https://mumbai.polygonscan.com/) - Blockchain Explorer

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Team

- **Backend Lead** - Spring Boot & Architecture
- **Blockchain Engineer** - Web3j Integration
- **DevOps Engineer** - OCI & Kubernetes

---

## 🆘 Support

For issues and questions:
- **Issues**: [GitHub Issues](https://github.com/your-org/truth-protocol-backend/issues)
- **Email**: support@truthprotocol.io
- **Documentation**: [Wiki](https://github.com/your-org/truth-protocol-backend/wiki)

---

**Built with ❤️ by the TRUTH Protocol Team**
