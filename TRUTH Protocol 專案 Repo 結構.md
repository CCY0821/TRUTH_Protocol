### <a name="_vsmth95nyq6o"></a> **TRUTH Protocol 專案 Repo 結構**
### <a name="_fwfyjut3ylkv"></a>**1. truth-protocol-backend (Spring Boot API & Relayer Worker)**
truth-protocol-backend/

├── .github/

│   └── workflows/

│       └── build\_test.yml         # CI/CD: Gradle Build, Test, Checkstyle/Detekt

├── src/

│   ├── main/

│   │   ├── java/com/truth/...     # 核心 Java 程式碼 (Controller/Service/RelayerWorker)

│   │   └── resources/

│   │       ├── application.yml              # 基礎配置 (共用)

│   │       ├── application-dev.yml          # 本地開發配置 (Local DB, Mock Service)

│   │       ├── application-staging.yml      # 預生產環境配置

│   │       ├── application-prod.yml         # 正式生產環境配置

│   │       ├── openapi.yaml                 # OpenAPI 3.0 規格書 (BE-02)

│   │       └── db/migration/

│   │           └── V1\_\_init.sql             # Flyway 初始腳本 (BE-03)

│   └── test/...                   # 單元測試與 BDD 測試

├── build.gradle                   # Gradle 配置

├── Dockerfile                     # 應用程式 Docker Image

├── .gitignore                     # 忽略編譯檔案、IDE 設定

├── README.md                      # 專案說明、API 使用指南

└── CONTRIBUTING.md                # 開發規範與分支策略

#### <a name="_k6d8h65y33ay"></a>**2. truth-protocol-frontend (Flutter Mobile App)**
truth-protocol-frontend/

├── .github/

│   └── workflows/

│       └── build\_test.yml         # CI/CD: Flutter Build/Test/Format

├── lib/

│   ├── core/...                   # Riverpod 狀態管理、API Client

│   ├── features/...               # Verifier/Issuer UI 模組

│   └── main.dart

├── assets/

│   ├── images/                    # 應用程式圖示、Logo

│   └── lotties/                   # 動畫檔案

├── l10n/

│   └── app\_en.arb                 # 多語系資源檔 (i18n)

├── test/...                       # Widget Test, Unit Test

├── pubspec.yaml                   # Dart/Flutter 依賴

├── .gitignore                     # 忽略 .dart\_tool, build/

└── README.md                      # App 簡介與安裝/運行說明

#### <a name="_mjdb9l30wwab"></a>**3. truth-protocol-smart-contract (Solidity)**
truth-protocol-smart-contract/

├── contracts/

│   ├── IdentityContract.sol         # KYC 狀態錨定合約

│   └── TruthSBT.sol                 # ERC-721 不可轉移憑證 (SC-01)

├── test/...                       # Hardhat/Foundry 單元測試

├── scripts/                       # 部署腳本

├── build/

│   └── artifacts/                 # 合約編譯輸出的 JSON/ABI

├── hardhat.config.js              # Hardhat/Foundry 配置

├── .env.example                   # RPC URL, Etherscan API Key 範例

├── .gitignore                     # 忽略 node\_modules, .env, cache, artifacts

└── README.md                      # 合約結構與部署指南

#### <a name="_yw43z0l7geqj"></a>**4. truth-protocol-devops (IaC, Security & Ops)**
truth-protocol-devops/

├── oci-infra/

│   ├── vault-config/

│   │   ├── vault.tf               # Vault/Master Key/Secret 定義 (INF-03)

│   │   ├── iam\_policy.tf          # IAM 存取策略

│   │   └── ...

│   ├── oke-cluster/

│   │   ├── oke.tf                 # OKE VCN/Cluster 配置 (INF-01)

│   │   └── db.tf                  # PostgreSQL 部署與備份 (INF-02)

│   ├── main.tf

│   ├── variables.tf

│   └── .gitignore                 # 核心：忽略 \*.tfstate, .terraform/

├── monitoring/

│   ├── grafana/

│   └── prometheus/

│       └── alert\_rules.yml        # SLO 告警規則 (INF-04)

├── compliance/

│   └── kyc\_data\_retention\_policy.md # 法遵文件 (PM-01)

├── runbook/

│   └── rollback\_runbook.md        # 運維手冊 (PM-01)

└── README.md                      # 基礎設施部署流程 (Terraform Apply 指令)

