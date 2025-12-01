# <a id="_xbwao8r3fyfq"></a>__TRUTH Protocol \- APP 架構書 \(Architecture Document\) 總覽__

## <a id="_h18jkp20wuhv"></a>__專案核心與哲學__

__項目__

__描述__

__核心目標__

建立一個__只有真實資訊的社群__，實現實體資產與身份的不可篡改認證。

__核心哲學__

__Invisible Tech \(隱形科技\)__：將所有區塊鏈複雜性（Gas Fee、錢包、Hash）完全封裝，提供 Web2 級別的流暢體驗。

__商業模式__

__SaaS 預付模式__：發行者 \(B端\) 以法幣購買點數 \(Credits\)，平台高毛利營運。

__核心機制__

__Gas 抽象化__：後端 __Relayer \(Spring Boot Worker\)__ 代為支付 Gas Fee，Issuer 僅消耗 Credits。

__數據儲存__

__永久性__：Metadata 上傳至 Arweave，確保真實資訊不會消失。

## <a id="_a11raewuron"></a>__1\. 系統架構與技術棧 \(Architecture & Stack\)__

__層級 \(Layer\)__

__技術選型__

__關鍵功能__

__企業級優勢__

__前端 \(App\)__

__Flutter \(Dart\) / Riverpod__

跨平台 UI、掃碼驗證 \(mobile\_scanner\)。

高效能，單一程式碼庫。

__後端 \(API/Worker\)__

__Spring Boot \(Java\)__

KYC 驗證、Credits 扣除、JWT Auth、__Relayer Worker \(Spring Batch\)__。

企業級穩定性、強大併發處理能力。

__資料庫 \(Index\)__

__PostgreSQL \(OCI DB\)__

快速查詢憑證狀態 \(Cache\)、Credits 餘額。

高可用性、索引優化 \(讀取 P95 < 300ms\)。

__雲端平台__

__Oracle Cloud \(OCI\)__

OKE \(Kubernetes\)、Load Balancer、__OCI Vault__ \(KMS\)。

企業級託管與安全。

__區塊鏈__

__Polygon PoS__

鑄造 __SBT \(Soulbound Token\)__。

極低 Gas 費與快速確認。

__儲存層__

__Arweave / IPFS__

憑證 Metadata 永久存儲。

數據不可篡改。

## <a id="_9puc8vof6iwa"></a>__2\. 關鍵流程與安全規範 \(Process & Security\)__

### <a id="_oper6cbovn4z"></a>__2\.1 核心用例規格：發行 SBT \(UC\-01 Minting\)__

__步驟__

__關鍵點__

__流程控制__

__前置條件__

__Issuer 必須通過 Spring Boot 整合的 KYC 驗證。__

__新 Identity Contract__ 鏈上錨定。

__交易處理__

API 預扣 Credits，將任務推送至 __Spring Batch/JMS Queue__。

確保交易順序 \(Nonce\)，避免 Gas Race。

__異步上鏈__

__Relayer Worker__ 呼叫 __OCI Vault__ 簽名，並提交到 Polygon。

__強制 Signer\-as\-a\-service__，私鑰不落地。

__錯誤處理__

若上鏈失敗，Worker 執行 __Gas Price 調整重試__；若重試失敗，__Credit 自動回滾 \(Rollback\)__。

提高系統容錯性。

### <a id="_7vaavi4df6qn"></a>__2\.2 安全性與法遵 \(Security & Compliance\)__

__領域__

__執行規範__

__金鑰管理__

Relayer 私鑰必須儲存在 __OCI Vault \(HSM\)__ 中，且建議使用 __Multisig__ 管理合約權限。

__傳輸安全__

全程 TLS/HTTPS，Flutter App 實施 Certificate Pinning。

__數據法遵__

制定 __KYC 資料保留期與刪除流程__，確保符合個資法規，並在 DB Schema 中加入 data\_retention\_date 欄位。

__認證標準__

採用 JWT 進行 API 認證，定義 Auth Scopes \(如 issuer:mint\)。

## <a id="_ashx6iovt8aw"></a>__3\. 營運服務承諾 \(SLA, SLO, SLI\)__

__指標 \(SLI\)__

__內部目標 \(SLO\)__

__對外承諾 \(SLA\)__

__運維門檻 \(Alerting Threshold\)__

__API 可用性__

99\.95% Uptime

__99\.9% Uptime__ \(每月停機 < 43m\)

\-

__驗證速度 \(P95\)__

< 300 ms

__< 1000 ms__

P95 > 300ms 觸發 Warning

__發行上鏈時效__

< 3 分鐘

__< 10 分鐘__

任務滯留 Queue > 5分鐘觸發 Warning

__Relayer 穩定性__

99\.9% Success Rate

__99% Success Rate__

失敗率 > 1% 觸發 Critical \(Pager\)

__DB 恢復__

RPO < 1 分鐘

__RPO < 15 分鐘__

確保 WAL 歸檔與保留政策落實。

## <a id="_1odq5ef0dzd3"></a>__4\. 開發與交付規範 \(DevOps & Process\)__

__領域__

__規範/工具__

__API 契約__

輸出 __OpenAPI 3\.0 YAML__ 規格書，包含詳細的 Error Schema 與範例。

__測試驗收__

執行 BDD 測試，並以 __k6 壓力測試腳本__ 設定 __500 QPS 讀取__ 為驗收標準。

__部署流程__

使用 OCI DevOps CI/CD，部署至 OKE，確保可回滾。

__運維應對__

撰寫 __上線/回滾 Runbook__，並制定 On\-call 輪值表，以應對緊急狀況。

__資料庫__

使用 Flyway 進行版本控制，__PostgreSQL 索引__ \(如 idx\_credentials\_token\_id\) 必須嚴格執行。

# <a id="_thhs1krldsn1"></a>__TRUTH Protocol \- APP 架構書 \(Architecture Document\) v1\.0__

## <a id="_jynutp4cixql"></a>__1\. 專案概要 \(Project Summary\)__

### <a id="_z7lhrx9su27z"></a>__1\.1 專案目的 \(Why\)__

建立一個只有真實資訊的社群，透過區塊鏈技術實現實體資產與身份的不可篡改認證 1。目標是消除假資訊，並在 Web2 的使用者體驗下提供 Web3 的信任機制。

### <a id="_mltdu1wmbggp"></a>__1\.2 問題痛點__

- __Web3 門檻過高：__ 用戶不理解錢包、助記詞與 Gas Fee，導致普及困難。
- __信任成本高昂：__ 傳統證書容易偽造，查證困難且耗時。

### <a id="_5i9p7tz9eeey"></a>__1\.3 主要功能簡述__

- __Verifier \(C端\)：__ 啟動即掃碼，驗證資產真偽，顯示綠色認證標章 2。
- __Issuer \(B端\)：__ 購買點數 \(Credits\)，通過 KYC 後發行不可篡改的 SBT 憑證 3。
- __Holder \(持有者\)：__ 管理個人資產憑證，生成 QR Code 分享。

### <a id="_z1l8otxk0a9m"></a>__1\.4 產品定位 & 目標用戶__

- __定位：__ Web3 通用溯源與認證平台 \(SaaS 模式\)。
- __用戶：__ 企業/發證機構 \(Issuer\)、一般大眾 \(Verifier/Holder\)。

### <a id="_mjaksdx2hhw0"></a>__1\.5 專案範圍 \(Scope\)__

- __In Scope:__ Flutter Mobile App \(iOS/Android\)、Spring Boot 後端 API、Relayer \(中繼服務\)、Polygon 智能合約部署、OCI 雲端環境建置。
- __Out of Scope:__ 二級市場交易功能 \(Marketplace\)、加密貨幣錢包託管 \(用戶無需感知錢包\)。

## <a id="_mikss1euit2h"></a>__2\. 系統架構 \(High\-Level Architecture\)__

### <a id="_6ylw2z1qtzkr"></a>__2\.1 系統架構圖__

採用 __混合架構 \(Hybrid Architecture\)__：前端極簡、後端託管、鏈上錨定 4。

- __Client:__ Flutter Mobile App
- __Gateway:__ OCI API Gateway / Load Balancer
- __Backend:__ Spring Boot Application \(API \+ Worker\)
- __Database:__ OCI Database for PostgreSQL
- __Blockchain:__ Polygon PoS \(L2\) & Arweave \(Storage\) 5

### <a id="_9irwyy4yep8m"></a>__2\.2 資料流示意圖 \(Data Flow\)__

1. __發行請求：__ App \(Issuer\) \-> API Gateway \-> Spring Boot \(Auth/Credits Check\) \-> __寫入 DB \(Pending\)__。
2. __非同步上鏈：__ Spring Batch \(Worker\) \-> 讀取 Pending 任務 \-> 簽名 \(Relayer Key\) \-> __Polygon \(Mint SBT\)__ & __Arweave \(Metadata\)__ 6666。
3. __狀態更新：__ 鏈上確認 \-> Worker 更新 DB 狀態 \(Confirmed\) \-> WebSocket 推送 App。
4. __驗證請求：__ App \(Verifier\) \-> 掃描 QR \-> API 查詢 DB \(秒開體驗\) 7。

### <a id="_jpzm46g9o2ay"></a>__2\.3 系統邏輯分層__

- __Presentation Layer:__ Flutter UI & State Management\.
- __Application Layer:__ Spring Boot Service \(業務邏輯、KYC、計費\)。
- __Infrastructure Layer:__ Web3j \(區塊鏈交互\)、OCI SDK。

## <a id="_o6awkvkhzq3y"></a>__3\. APP 前端架構 \(Flutter\)__

### <a id="_i8fvym5qgb2"></a>__3\.1 UI 架構__

- __Component Tree:__ 原子化設計 \(Atoms, Molecules, Organisms\)。
- __Navigation:__ 使用 go\_router 進行深層連結 \(Deep Link\) 管理，便於分享憑證連結。
- __頁面設計:__
	- VerifierScreen \(首頁/相機\) 8
	- IssuerDashboard \(後台/表單\) 9
	- WalletView \(資產卡片\) 10

### <a id="_oxp68ilf2h0t"></a>__3\.2 State Management 架構__

- __方案：__ __Flutter Riverpod__ 11。
- __理由：__ 編譯時安全、無 context 依賴、易於測試，適合管理複雜的異步狀態 \(如鏈上交易狀態\)。
- __規則：__
	- Global: User Session, Theme, Connection Status\.
	- Local: Form Input, Scanner State\.
- __非同步流程:__ 使用 AsyncValue 處理 Data/Loading/Error 狀態，統一錯誤彈窗邏輯。

### <a id="_es6wvuo5cb6q"></a>__3\.3 Service / Repository Layer__

- __API Service:__ 使用 Dio 封裝 HTTP 請求，攔截器處理 Token 刷新。
- __Local Storage:__ 使用 Hive 或 SharedPreferences 緩存用戶設定與離線憑證數據。
- __Web3 Service:__ web3dart 12 用於本地生成臨時簽名 \(若需\) 或驗證數據完整性。
- __Scanner:__ mobile\_scanner 13 實現高效 QR 掃描。

### <a id="_ck59ys7wujaf"></a>__3\.4 安全性__

- __Secure Storage:__ 使用 flutter\_secure\_storage 存儲 JWT Token。
- __Transport:__ 強制 HTTPS，並透過 Certificate Pinning 防止中間人攻擊。

## <a id="_41c0zc95kk6u"></a>__4\. 後端架構 \(Spring Boot\)__

### <a id="_zc47huv2hh1x"></a>__4\.1 系統分層__

- __Controller:__ 處理 HTTP 請求與驗證 \(Validation\)。
- __Service:__ 核心業務邏輯 \(KYC 流程、扣點邏輯、SBT 鑄造指令\)。
- __Repository:__ JPA / Hibernate 存取 PostgreSQL。
- __Web3 Manager:__ 封裝 Web3j，管理 Nonce 與 Gas Price。

### <a id="_wah7cj2429eq"></a>__4\.2 API 設計__

- __標準:__ RESTful API \(v1\)。
- __回傳格式:__ \{ "code": 200, "message": "success", "data": \{\.\.\.\} \}。
- __Rate Limit:__ 使用 Bucket4j 或 OCI API Gateway 限制請求頻率。

### <a id="_2uoe3yhj7x7h"></a>__4\.3 資料庫 Schema \(PostgreSQL\)__

- __ERD 核心實體:__
	- Users: \(ID, Email, PasswordHash, KYC\_Status, Role\)
	- Credits: \(UserID, Balance\) 14
	- Credentials: \(ID, TokenID, OwnerID, MetadataHash, ContractAddr, Status\)
	- Transactions: \(TxHash, Nonce, GasUsed, Status\)

### <a id="_9lprp7aazxdl"></a>__4\.4 Background Jobs \(The Relayer\)__

- __技術:__ __Spring Batch__ 或 __Spring Integration__。
- __職責:__ 替代原 Node\.js 的 Redis Queue。
	- __Queue:__ 處理鏈上交易請求，確保先進先出 \(FIFO\) 以維持 Nonce 順序 15。
	- __Retry:__ 自動重試機制 \(處理鏈上擁塞或 RPC 錯誤\)。

### <a id="_3i5xjv5lxoqv"></a>__4\.5 第三方服務__

- __KYC Service:__ 整合第三方身分驗證 API。
- __Storage:__ Arweave \(透過 Arweave HTTP API\) \+ OCI Object Storage \(備份\)。

## <a id="_f2m8k3mzpnap"></a>__5\. DevOps 與部署架構__

### <a id="_gjoovit0n36z"></a>__5\.1 CI/CD Pipeline__

- __工具:__ GitHub Actions 或 OCI DevOps。
- __流程:__ Code Push \-> Unit Test \-> Build Docker Image \-> Push to OCI Registry \-> Deploy to OKE \(Kubernetes\)。

### <a id="_lwf2jlrktfq3"></a>__5\.2 Environment 設計__

- __Dev:__ 連接 Polygon Amoy Testnet。
- __Prod:__ 連接 Polygon Mainnet。
- __Secrets:__ 使用 __OCI Vault__ 管理 API Keys 和 Database Password。

### <a id="_wwxd3xempvl3"></a>__5\.3 雲端架構 \(OCI\)__

- __Compute:__ OCI Container Engine for Kubernetes \(OKE\) 託管 Spring Boot 微服務。
- __Database:__ OCI Database with PostgreSQL Compatibility。
- __Load Balancer:__ OCI Load Balancer 分流流量。
- __Monitoring:__ OCI Monitoring & Logging Analytics。

### <a id="_zhmt8m2h3wz9"></a>__5\.4 災難復原 \(DR Plan\)__

- __DB:__ 啟用 OCI 自動備份與跨區域複製 \(Cross\-Region Replication\)。
- __RPO/RTO:__ 目標 RPO < 15分鐘, RTO < 1小時。

## <a id="_lofkn1tm3y6"></a>__6\. 安全性架構__

### <a id="_3c0ugxpv2l3h"></a>__6\.1 身份認證__

- __OAuth2 / JWT:__ 用戶登入後獲取 Access Token 與 Refresh Token。
- __Session:__ Token 有效期短 \(e\.g\., 1小時\)，Refresh Token 存於 HttpOnly Cookie 或 Secure Storage。

### <a id="_h1d7ag6c09qc"></a>__6\.2 錢包與私鑰管理 \(核心安全\)__

- __Relayer Private Key:__ 這是系統最高權限 \(Minter Role\)。
- __方案:__ __嚴禁__硬編碼。必須存儲於 __OCI Vault \(KMS\)__ 中，Spring Boot 僅在簽名時透過 API 調用 Vault 獲取簽名結果 \(或在記憶體中極短暫解密\)。

### <a id="_hs14k67yg96r"></a>__6\.3 資料加密__

- __傳輸中:__ TLS 1\.2/1\.3。
- __靜態:__ 資料庫開啟 TDE \(Transparent Data Encryption\)。

## <a id="_91phvny2tubk"></a>__7\. 非功能性需求 \(NFR\)__

- __可用性 \(Availability\):__ 99\.9% \(依賴 OCI SLA\)。
- __性能 \(Performance\):__ 驗證查詢 \(Scan\) 回應時間 < 500ms \(讀 DB，不讀鏈\)。
- __擴充性 \(Scalability\):__ Spring Boot 支援水平擴展 \(Horizontal Scaling\) 以應對高併發發行請求。
- __成本 \(Cost\):__ 優化 Gas 策略，利用 Polygon 離峰時段上鏈。

## <a id="_2jrhl4heoioa"></a>__8\. Logging / Monitoring__

- __Log 格式:__ JSON 格式，包含 TraceID, UserID, Level, Message。
- __Crash Report:__ Flutter 端整合 __Sentry__ 或 __Firebase Crashlytics__。
- __Metrics:__ 使用 __Prometheus__ 收集 JVM 與 API 指標，__Grafana__ 進行視覺化監控。
- __警示:__ 當 Relayer 錢包 MATIC 餘額低於閾值時，發送 Slack/Email 警報。

## <a id="_h26h46qw4sq3"></a>__9\. 測試策略 \(Testing Strategy\)__

### <a id="_fzjb88y67q8w"></a>__9\.1 單元測試 \(Unit Test\)__

- __Backend:__ JUnit 5 \+ Mockito \(覆蓋 Service 層邏輯，特別是 Credits 扣除邏輯\)。
- __Frontend:__ flutter\_test \(覆蓋 UI 組件與 Provider 狀態\)。

### <a id="_id3pqu9wnoca"></a>__9\.2 API 測試__

- 使用 Postman Collection 進行自動化 API 流程測試。

### <a id="_jq5jf0fiyuz4"></a>__9\.3 BDD 測試 \(關鍵\)__

- 依據 "Gherkin" 腳本執行驗收測試 16。
- 工具：__Cucumber for Java__。確保 "Given Issuer has credits\.\.\." 等場景通過驗證。

## <a id="_hkt0tesip7it"></a>__10\. 專案規範 \(Coding Standards\)__

- __Java:__ Google Java Style Guide\.
- __Dart:__ Effective Dart\.
- __Git:__ Conventional Commits \(e\.g\., feat: add kyc verification, fix: gas estimation error\)\.
- __Code Review:__ 所有 PR 需至少 1 位資深開發者核准，並通過 CI pipeline。

## <a id="_c50gx9jvu65y"></a>__11\. 風險評估 \(Risk Assessment\)__

__風險項目__

__可能性__

__影響程度__

__緩解策略__

__區塊鏈擁塞__

中

高

實作 Spring Batch 隊列與 Gas Price 動態調整機制 17。

__私鑰洩漏__

低

極高

使用 OCI Vault，權限最小化原則，多重簽名 \(Multisig\) 管理合約管理員。

__法規合規 \(KYC\)__

中

高

整合第三方合規 KYC 服務，確保 Issuer 實名。

__資料不一致__

低

中

鏈上與 DB 狀態同步機制 \(Watcher Service\)。

## <a id="_lqnhn8l21aob"></a>__12\. WBS \(工作分解結構\) 簡述__

1. __Phase 1: Protocol & Cloud \(Week 1\)__ \- OCI 環境搭建、合約部署。
2. __Phase 2: Relayer & API \(Week 2\)__ \- Spring Boot 核心、KYC 整合。
3. __Phase 3: App Development \(Week 3\-4\)__ \- Flutter UI、掃碼功能。
4. __Phase 4: Integration \(Week 5\)__ \- BDD 測試、壓力測試。

## <a id="_bm58s6q72esb"></a>__13\. 用例規格 \(Use Case Specifications\)__

### <a id="_yp28g53rgztx"></a>__13\.1 核心用例圖 \(Use Case Diagram\)__

*\(文字描述示意，實作時將轉換為 UML 圖\)*

- __Issuer \(發行者\):__ 註冊與 KYC、購買點數、__發行憑證 \(Mint\)__、撤銷憑證、查看發行紀錄。
- __Verifier \(驗證者/消費者\):__ __掃碼驗證 \(Scan\)__、查看憑證詳情、舉報偽造 \(可選\)。
- __Holder \(持有者\):__ 查看我的錢包、生成分享 QR Code、隱藏特定資訊。
- __Relayer \(系統/後端\):__ 監聽隊列、簽名交易、補發交易 \(Retry\)、更新鏈上狀態。

### <a id="_80efs7jmnw6o"></a>__13\.2 詳細用例規格：UC\-01 發行憑證 \(Issuer Minting\)__

這不僅是發行，更是商業模式的核心 \(Credits Consumption\)。

__項目__

__內容__

__用例名稱__

__UC\-01: 發行不可篡改憑證 \(Mint SBT\)__

__參與者__

Issuer, System \(API \+ Relayer\)

__前置條件 \(Pre\-conditions\)__

1\. Issuer 已登入且通過 __KYC__。

2\. Issuer 的 __Credits 餘額 > 1__。

__主要流程 \(Main Flow\)__

1\. Issuer 在 App 填寫憑證資訊 \(圖片、描述、屬性\) 並點擊「發行」。

2\. App 將數據打包並發送至 API。

3\. __API \(Spring Boot\)__ 驗證數據格式與用戶 KYC 狀態。

4\. API 鎖定並預扣 1 Credit \(狀態: LOCKED\)。

5\. API 將 Metadata 上傳至 Arweave/IPFS \(或放入上傳隊列\)。

6\. API 建立一筆 PENDING 狀態的交易任務至 __JMS Queue__。

7\. API 回傳 202 Accepted 給 App。

8\. App 顯示「正在上鏈中\.\.\.」狀態。

__後端異步流程 \(Async Flow\)__

9\. __Relayer Worker__ 從 Queue 取出任務。

10\. Worker 透過 OCI Vault 取得私鑰簽名，發送至 Polygon。

11\. 監聽鏈上 Transfer 事件確認成功。

12\. Worker 更新 DB：交易狀態 CONFIRMED，Credit 狀態 CONSUMED。

13\. 透過 WebSocket 推送「發行成功」通知給 Issuer App。

__例外流程 \(Exception Flow\)__

__E1: 餘額不足__

若 Step 4 檢查餘額 < 1，API 回傳 402 Payment Required，App 引導儲值。

__E2: 上鏈失敗 \(Revert\)__

若 Step 10 交易被鏈上 Revert，Worker 回滾 Credit 狀態至 AVAILABLE，標記任務失敗，通知用戶「發行失敗，點數已退還」。

## <a id="_sqcq3vmvg6h6"></a>__14\. API 規格 \(OpenAPI / Swagger 3\.0\)__

為了確保前後端對接無誤，以下是核心 API 的 YAML 定義片段。

YAML

openapi: 3\.0\.3

info:

  title: TRUTH Protocol API

  version: 1\.0\.0

  description: 企業級 Web3 溯源認證平台 API

servers:

  \- url: https://api\.truthprotocol\.com/v1

    description: Production OCI Gateway

paths:

  /credentials/mint:

    post:

      summary: 發行新憑證 \(異步處理\)

      security:

        \- bearerAuth: \[\]

      requestBody:

        required: true

        content:

          application/json:

            schema:

              type: object

              required: \[title, recipient\_wallet, metadata\]

              properties:

                title:

                  type: string

                  example: "2025 官方認證經銷商"

                recipient\_wallet:

                  type: string

                  pattern: "^0x\[a\-fA\-F0\-9\]\{40\}$"

                  description: "接收者的錢包地址 \(若無則由系統代管\)"

                metadata:

                  type: object

                  description: "將被存入 Arweave 的完整 JSON"

      responses:

        '202':

          description: 請求已受理，進入排程

          content:

            application/json:

              schema:

                type: object

                properties:

                  job\_id:

                    type: string

                    format: uuid

                  status:

                    type: string

                    example: "QUEUED"

        '402':

          description: 點數不足 \(Insufficient Credits\)

          content:

            application/json:

              schema:

                $ref: '\#/components/schemas/ErrorResponse'

components:

  securitySchemes:

    bearerAuth:

      type: http

      scheme: bearer

      bearerFormat: JWT

  schemas:

    ErrorResponse:

      type: object

      properties:

        code:

          type: string

          example: "ERR\_INSUFFICIENT\_FUNDS"

        message:

          type: string

          example: "Your credit balance is 0\. Please top up\."

## <a id="_5s9cxwuci1b6"></a>__15\. 系統序列圖 \(System Sequence Diagrams\)__

### <a id="_rsc417v53x7a"></a>__15\.1 驗證者掃碼流程 \(Verifier Scan\) \- "秒開體驗"__

此流程展示如何繞過讀取區塊鏈的延遲，直接從 Index DB 讀取數據，實現 Web2 級別速度。

程式碼片段

sequenceDiagram

    participant User as Verifier \(App\)

    participant API as API Gateway

    participant DB as PostgreSQL \(Index\)

    participant Ar as Arweave \(Storage\)

    User\->>User: 掃描 QR Code \(解析 TokenID\)

    User\->>API: GET /credentials/\{tokenId\}

    

    par Parallel Fetch \(效能優化\)

        API\->>DB: 查詢憑證狀態 \(Is Valid?\) & Hash

        DB\-\->>API: Return Status: Valid, Hash: 0x123\.\.\.

    and

        API\->>DB: 查詢快取 Metadata

        alt Metadata 未快取

            API\->>Ar: Fetch JSON via Gateway

            Ar\-\->>API: Return JSON

            API\->>DB: Update Cache

        end

    end

    API\-\->>User: HTTP 200 OK \(完整顯示資料\)

    Note right of User: 顯示綠色 Verified 標章<br/>不顯示 Gas/Hash

### <a id="_mh209lfxn7di"></a>__15\.2 後端 Relayer 處理流程 \(含錯誤重試\)__

程式碼片段

sequenceDiagram

    participant Q as JMS Queue

    participant W as Worker \(Spring Boot\)

    participant V as OCI Vault \(KMS\)

    participant Chain as Polygon PoS

    Q\->>W: Consume Job \(Mint Request\)

    W\->>W: 建構 Transaction \(Raw Tx\)

    W\->>V: 請求簽名 \(Sign Hash\)

    V\-\->>W: 返回簽名 \(Signature\)

    

    W\->>Chain: Send Signed Transaction

    

    alt 成功 \(Success\)

        Chain\-\->>W: Tx Hash

        W\->>W: 寫入 DB: Pending

        loop 輪詢確認

            W\->>Chain: Get Receipt

            Chain\-\->>W: Status: 1 \(Success\)

        end

    else 失敗 \(Gas Spike / Error\)

        Chain\-\->>W: Revert / Timeout

        W\->>W: 檢查重試次數 \(Retry Count < 3?\)

        W\->>W: 提高 Gas Price \(\+10%\)

        W\->>Q: Re\-queue Job \(延遲重試\)

    end

## <a id="_inark5fx0otg"></a>__16\. 詳細資料庫 Schema \(PostgreSQL\)__

這部分展示工程落地所需的精確度，特別關注索引優化。

SQL

\-\- 1\. 用戶表 \(含 KYC 狀態\)

CREATE TABLE users \(

    id UUID PRIMARY KEY DEFAULT gen\_random\_uuid\(\),

    email VARCHAR\(255\) UNIQUE NOT NULL,

    password\_hash VARCHAR\(255\) NOT NULL,

    kyc\_status VARCHAR\(20\) DEFAULT 'PENDING' CHECK \(kyc\_status IN \('PENDING', 'APPROVED', 'REJECTED'\)\),

    kyc\_ref\_id VARCHAR\(100\), \-\- 外部 KYC 服務商 ID

    created\_at TIMESTAMP WITH TIME ZONE DEFAULT NOW\(\)

\);

\-\- 2\. 點數表 \(高併發核心\)

CREATE TABLE credits \(

    user\_id UUID PRIMARY KEY REFERENCES users\(id\),

    balance INTEGER NOT NULL DEFAULT 0 CHECK \(balance >= 0\),

    version INTEGER DEFAULT 0, \-\- 用於樂觀鎖 \(Optimistic Locking\)

    updated\_at TIMESTAMP WITH TIME ZONE DEFAULT NOW\(\)

\);

\-\- 3\. 憑證表 \(核心資產\)

CREATE TABLE credentials \(

    id UUID PRIMARY KEY DEFAULT gen\_random\_uuid\(\),

    issuer\_id UUID NOT NULL REFERENCES users\(id\),

    token\_id NUMERIC\(78,0\), \-\- 對應 uint256，允許空值 \(上鏈前\)

    tx\_hash VARCHAR\(66\),

    

    \-\- Metadata 儲存 \(Arweave Hash & 本地 Cache\)

    arweave\_hash VARCHAR\(100\),

    metadata\_cache JSONB, \-\- 使用 JSONB 以支援靈活查詢

    

    status VARCHAR\(20\) DEFAULT 'QUEUED' CHECK \(status IN \('QUEUED', 'PENDING', 'CONFIRMED', 'FAILED', 'REVOKED'\)\),

    

    created\_at TIMESTAMP WITH TIME ZONE DEFAULT NOW\(\)

\);

\-\- 4\. 索引優化 \(Performance Tuning\)

\-\- 加速「我的發行」列表查詢

CREATE INDEX idx\_credentials\_issuer ON credentials\(issuer\_id, created\_at DESC\);

\-\- 加速掃碼查詢 \(根據 TokenID\)

CREATE UNIQUE INDEX idx\_credentials\_token\_id ON credentials\(token\_id\) WHERE status = 'CONFIRMED';

\-\- 加速 JSONB 內部屬性查詢 \(例如查詢特定產品批號\)

CREATE INDEX idx\_credentials\_meta\_batch ON credentials USING GIN \(\(metadata\_cache \-> 'batch\_no'\)\);

## <a id="_pp8sgtjfpy6x"></a>__17\. 營運指標 \(SLA / SLO / SLI\)__

這是面對投資人與企業客戶 \(B端 Issuer\) 最重要的承諾。

### <a id="_3ysmt54dduoh"></a>__17\.1 定義__

- __SLA \(Service Level Agreement\):__ 對外承諾的最低服務標準 \(違約需賠償/退點\)。
- __SLO \(Service Level Objective\):__ 團隊內部的技術奮鬥目標 \(通常比 SLA 嚴格\)。
- __SLI \(Service Level Indicator\):__ 實際監控的測量指標。

### <a id="_mnils5mic0xn"></a>__17\.2 TRUTH Protocol 營運矩陣__

__類別__

__指標 \(SLI\)__

__內部目標 \(SLO\)__

__對外承諾 \(SLA\)__

__測量方式__

__API 可用性__

API HTTP 5xx 錯誤率

99\.95% Uptime

__99\.9%__ \(每月停機 < 43m\)

OCI Load Balancer Logs

__驗證速度__

GET /credentials 回應時間 \(P95\)

< 300 ms

__< 1000 ms__

APM \(Grafana/Prometheus\)

__發行上鏈時效__

任務進入 Queue 到 Tx Confirmed 時間

< 3 分鐘

__< 10 分鐘__

Spring Batch Job Stats

__資料耐久性__

PostgreSQL RPO \(資料遺失容忍\)

< 1 分鐘

__< 15 分鐘__

OCI Database Backup Logs

__Relayer 穩定性__

交易成功率 \(不含用戶餘額不足\)

99\.9%

__99%__

Smart Contract Events

