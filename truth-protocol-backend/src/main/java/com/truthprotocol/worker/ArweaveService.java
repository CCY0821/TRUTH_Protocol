// ========================================================================
// TRUTH Protocol Backend - Arweave Service
// ========================================================================
// Package: com.truthprotocol.worker
// Purpose: Upload credential metadata to Arweave for permanent storage
// ========================================================================

package com.truthprotocol.worker;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import jakarta.annotation.PostConstruct;
import okhttp3.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Base64;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

/**
 * Arweave Service
 *
 * Manages uploading credential metadata to Arweave for permanent, decentralized storage.
 *
 * Arweave Overview:
 * - Permanent data storage (pay once, store forever)
 * - Decentralized network (>1000 nodes globally)
 * - Content-addressable (data identified by hash)
 * - Immutable (data cannot be changed or deleted)
 *
 * Use Case in TRUTH Protocol:
 * - Store SBT metadata (title, description, attributes, images)
 * - Generate permanent URI for on-chain reference
 * - Ensure metadata availability even if issuer is offline
 *
 * Upload Process:
 * 1. Convert metadata JSON to byte array
 * 2. Calculate Arweave transaction fee (based on data size)
 * 3. Sign transaction with Arweave wallet
 * 4. Submit transaction to Arweave gateway
 * 5. Return Arweave transaction ID (hash)
 *
 * Metadata URI Format:
 * - ar://{arweave_hash}
 * - Example: ar://abc123def456...
 * - Resolved via Arweave gateway: https://arweave.net/{arweave_hash}
 *
 * Production vs Mock Mode:
 * - Production: Requires Arweave wallet with AR tokens
 * - Mock Mode (current): Simulates upload and returns mock hash
 *
 * Cost:
 * - Arweave charges based on data size (one-time fee)
 * - ~0.01-0.1 AR per MB (~$0.10-$1.00 at current prices)
 * - Typical SBT metadata: 1-10 KB (~$0.001-$0.01)
 *
 * Performance:
 * - Upload time: 1-5 seconds (depends on gateway and data size)
 * - Confirmation time: 2-10 minutes (blockchain finality)
 * - Availability: Immediate after upload (unconfirmed)
 *
 * Error Handling:
 * - Network errors: Retry with exponential backoff
 * - Insufficient balance: Alert admin to fund Arweave wallet
 * - Gateway errors: Use fallback gateway
 *
 * @see com.truthprotocol.config.BatchConfig
 */
@Service
public class ArweaveService {

    // ========================================================================
    // CONFIGURATION PROPERTIES (from application.yml)
    // ========================================================================

    /**
     * Arweave upload mode: mock or real
     */
    @Value("${app.arweave.mode:mock}")
    private String uploadMode;

    /**
     * Arweave Gateway URL
     *
     * Gateway endpoints:
     * - Production: https://arweave.net
     * - Testnet: https://testnet.arweave.net (if available)
     *
     * Alternative gateways (for redundancy):
     * - https://arweave.dev
     * - https://g8way.io
     * - Custom gateway: Run your own Arweave node
     */
    @Value("${app.arweave.gateway-url:https://arweave.net}")
    private String gatewayUrl;

    /**
     * HTTP request timeout (milliseconds)
     *
     * Recommended values:
     * - Small files (<1MB): 10-30 seconds
     * - Large files (>1MB): 60-120 seconds
     */
    @Value("${app.arweave.timeout:30000}")
    private int timeoutMs;

    /**
     * Max retry attempts for failed uploads
     */
    @Value("${app.arweave.max-retries:3}")
    private int maxRetries;

    /**
     * Arweave wallet JWK (JSON Web Key)
     * Required for real uploads
     */
    @Value("${app.arweave.wallet-jwk:}")
    private String walletJwk;

    /**
     * WebClient for HTTP requests (kept for backward compatibility)
     */
    private WebClient webClient;

    /**
     * OkHttp client for Arweave uploads
     */
    private OkHttpClient httpClient;

    /**
     * ObjectMapper for JSON serialization
     */
    private final ObjectMapper objectMapper = new ObjectMapper();

    // ========================================================================
    // INITIALIZATION
    // ========================================================================

    /**
     * Initialize WebClient
     *
     * Configuration:
     * - Base URL: Arweave gateway URL
     * - Timeout: Configured via application.yml
     * - Headers: Content-Type, Accept (JSON)
     *
     * WebClient Features:
     * - Request/response logging (for debugging)
     * - Automatic retry on network errors (can be configured)
     * - Connection pooling (for better performance)
     *
     * Lifecycle:
     * - Called after dependency injection (@PostConstruct)
     * - Executes before any service methods
     */
    @PostConstruct
    public void init() {
        // Initialize WebClient (backward compatibility)
        this.webClient = WebClient.builder()
            .baseUrl(gatewayUrl)
            .defaultHeader("Content-Type", "application/json")
            .defaultHeader("Accept", "application/json")
            .build();

        // Initialize OkHttp client for real uploads
        this.httpClient = new OkHttpClient.Builder()
            .connectTimeout(timeoutMs, TimeUnit.MILLISECONDS)
            .readTimeout(timeoutMs, TimeUnit.MILLISECONDS)
            .writeTimeout(timeoutMs, TimeUnit.MILLISECONDS)
            .build();

        System.out.println("========================================");
        System.out.println("Arweave Service Initialized");
        System.out.println("========================================");
        System.out.println("Mode: " + uploadMode);
        System.out.println("Gateway URL: " + gatewayUrl);
        System.out.println("Timeout: " + timeoutMs + "ms");
        System.out.println("Max Retries: " + maxRetries);
        System.out.println("Wallet Configured: " + (!walletJwk.isEmpty() ? "Yes" : "No (Mock mode only)"));
        System.out.println("========================================");
    }

    // ========================================================================
    // METADATA UPLOAD METHODS
    // ========================================================================

    /**
     * Upload credential metadata to Arweave
     *
     * Uploads JSON metadata to Arweave for permanent, decentralized storage.
     *
     * Process Flow (Production):
     * 1. Serialize metadata JSON to byte array
     * 2. Calculate Arweave transaction fee based on data size
     * 3. Create Arweave transaction with metadata
     * 4. Sign transaction with Arweave wallet private key
     * 5. Submit transaction to Arweave gateway (POST /tx)
     * 6. Parse response to get Arweave transaction ID
     * 7. Return transaction ID as permanent URI
     *
     * Current Implementation (Mock):
     * - Simulates upload delay (500ms-2s)
     * - Generates mock Arweave hash: ar-hash-TRUTH-{UUID}
     * - No actual network request to Arweave
     * - Suitable for development and testing
     *
     * Metadata Structure (Example):
     * <pre>
     * {
     *   "name": "Organic Certification",
     *   "description": "Certificate for organic farming practices",
     *   "image": "https://example.com/cert.png",
     *   "attributes": [
     *     {"trait_type": "Certification Body", "value": "USDA"},
     *     {"trait_type": "Issue Date", "value": "2024-01-15"}
     *   ]
     * }
     * </pre>
     *
     * Arweave Transaction (Production):
     * <pre>
     * POST https://arweave.net/tx
     * Content-Type: application/json
     * 
     * {
     *   "data": "base64_encoded_metadata",
     *   "tags": [
     *     {"name": "Content-Type", "value": "application/json"},
     *     {"name": "App-Name", "value": "TRUTH-Protocol"}
     *   ]
     * }
     * </pre>
     *
     * Response Format (Production):
     * <pre>
     * {
     *   "id": "abc123def456...",  // Arweave transaction ID (hash)
     *   "status": "pending"
     * }
     * </pre>
     *
     * Arweave URI Construction:
     * - Prefix: ar://
     * - Hash: Arweave transaction ID
     * - Full URI: ar://abc123def456...
     * - Gateway URL: https://arweave.net/abc123def456...
     *
     * Error Scenarios (Production):
     * - Network error: Retry with exponential backoff
     * - Gateway timeout: Use alternative gateway
     * - Insufficient balance: Alert admin to fund Arweave wallet
     * - Invalid data: Validate metadata before upload
     *
     * Exception: ArweaveUploadException
     * - Custom exception for Arweave upload failures
     * - Contains error message and original cause
     * - Allows ItemProcessor to handle upload failures gracefully
     * - Can be caught and retried or logged
     *
     * TODO (Production Implementation):
     * 1. Install Arweave SDK: https://github.com/ArweaveTeam/arweave-java
     * 2. Configure Arweave wallet (load from OCI Vault)
     * 3. Calculate transaction fee: Arweave.calculateFee(dataSize)
     * 4. Create transaction: new Transaction(data, jwk, tags)
     * 5. Sign transaction: transaction.sign(jwk)
     * 6. Submit: arweave.transactions.post(transaction)
     * 7. Return: transaction.id
     *
     * Performance:
     * - Mock mode: 500ms-2s (simulated delay)
     * - Production: 1-5s (network upload + gateway processing)
     * - Confirmation: 2-10 minutes (blockchain finality)
     *
     * Cost Optimization:
     * - Compress metadata JSON (gzip) before upload
     * - Deduplicate images (store once, reference multiple times)
     * - Batch uploads (if Arweave supports)
     *
     * @param metadata Credential metadata as JsonNode
     * @return Arweave hash (mock: ar-hash-TRUTH-{UUID}, production: actual Arweave tx ID)
     * @throws RuntimeException if upload fails (in production, throw ArweaveUploadException)
     */
    public String uploadMetadata(JsonNode metadata) {
        System.out.println("[Arweave] Starting upload - Mode: " + uploadMode);

        try {
            // Log metadata size for monitoring
            String metadataJson = objectMapper.writeValueAsString(metadata);
            int dataSize = metadataJson.getBytes().length;
            System.out.println("[Arweave] Metadata size: " + dataSize + " bytes");

            // Choose upload method based on mode
            if ("real".equalsIgnoreCase(uploadMode)) {
                return uploadMetadataReal(metadata);
            } else {
                return uploadMetadataMock(metadata);
            }

        } catch (Exception e) {
            System.err.println("[Arweave] Upload failed: " + e.getMessage());
            throw new RuntimeException("Failed to upload metadata to Arweave", e);
        }
    }

    /**
     * Mock upload implementation (for development/testing)
     */
    private String uploadMetadataMock(JsonNode metadata) throws Exception {
        System.out.println("[Arweave] Using MOCK upload");

            // ================================================================
            // PRODUCTION IMPLEMENTATION (TODO)
            // ================================================================
            //
            // Step 1: Install Arweave Java SDK
            // <dependency>
            //   <groupId>org.arweave</groupId>
            //   <artifactId>arweave-java-client</artifactId>
            //   <version>1.0.0</version>
            // </dependency>
            //
            // Step 2: Load Arweave wallet from OCI Vault
            // String arweaveJwk = vaultService.getArweaveWallet();
            // JWK jwk = JWK.fromJson(arweaveJwk);
            //
            // Step 3: Create Arweave client
            // Arweave arweave = new Arweave(gatewayUrl);
            //
            // Step 4: Calculate transaction fee
            // long fee = arweave.transactions.calculateFee(dataSize);
            // System.out.println("Arweave fee: " + fee + " winston");
            //
            // Step 5: Create transaction
            // Transaction tx = new Transaction();
            // tx.setData(metadataJson.getBytes());
            // tx.addTag("Content-Type", "application/json");
            // tx.addTag("App-Name", "TRUTH-Protocol");
            // tx.addTag("App-Version", "1.0.0");
            //
            // Step 6: Sign transaction
            // tx.sign(jwk);
            //
            // Step 7: Submit to Arweave
            // String response = arweave.transactions.post(tx);
            // System.out.println("Arweave response: " + response);
            //
            // Step 8: Return transaction ID
            // String arweaveHash = tx.getId();
            // return arweaveHash;
            //
            // ================================================================

        // Simulate network delay for realistic testing
        long delayMs = 500 + (long) (Math.random() * 1500);  // 500-2000ms
        System.out.println("[Arweave] Simulating upload delay: " + delayMs + "ms");
        Thread.sleep(delayMs);

        // Generate mock Arweave hash
        String mockHash = "ar-hash-TRUTH-" + UUID.randomUUID().toString();
        System.out.println("[Arweave] Mock upload successful");
        System.out.println("[Arweave] Mock hash: " + mockHash);

        return mockHash;
    }

    /**
     * Real Arweave upload implementation
     *
     * Uploads data to Arweave network using HTTP API with retry logic
     */
    private String uploadMetadataReal(JsonNode metadata) throws Exception {
        System.out.println("[Arweave] Using REAL upload to Arweave network");

        // Validate wallet is configured
        if (walletJwk == null || walletJwk.isEmpty()) {
            throw new IllegalStateException(
                "Arweave wallet not configured. Set ARWEAVE_WALLET_JWK environment variable or use mock mode."
            );
        }

        // Convert metadata to bytes
        String metadataJson = objectMapper.writeValueAsString(metadata);
        byte[] data = metadataJson.getBytes(StandardCharsets.UTF_8);

        // Try upload with retries
        Exception lastException = null;
        for (int attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                System.out.println("[Arweave] Upload attempt " + attempt + "/" + maxRetries);
                return performArweaveUpload(data);
            } catch (Exception e) {
                lastException = e;
                System.err.println("[Arweave] Attempt " + attempt + " failed: " + e.getMessage());
                
                if (attempt < maxRetries) {
                    // Exponential backoff
                    long backoffMs = (long) Math.pow(2, attempt) * 1000;
                    System.out.println("[Arweave] Retrying in " + backoffMs + "ms...");
                    Thread.sleep(backoffMs);
                }
            }
        }

        throw new RuntimeException(
            "Arweave upload failed after " + maxRetries + " attempts", 
            lastException
        );
    }

    /**
     * Perform actual HTTP upload to Arweave
     *
     * NOTE: This is a simplified implementation.
     * Production version should:
     * - Load wallet JWK properly
     * - Sign transaction with wallet private key
     * - Calculate reward (fee) based on data size
     * - Create proper Arweave transaction structure
     */
    private String performArweaveUpload(byte[] data) throws IOException {
        // Encode data as base64 (Arweave requirement)
        String base64Data = Base64.getEncoder().encodeToString(data);

        // Create transaction request
        // NOTE: This is simplified - real implementation needs wallet signing
        ObjectNode transactionJson = objectMapper.createObjectNode();
        transactionJson.put("data", base64Data);
        
        // Add tags
        transactionJson.putArray("tags")
            .add(objectMapper.createObjectNode()
                .put("name", "Content-Type")
                .put("value", "application/json"))
            .add(objectMapper.createObjectNode()
                .put("name", "App-Name")
                .put("value", "TRUTH-Protocol"));

        String requestBody = objectMapper.writeValueAsString(transactionJson);

        // Build HTTP request
        Request request = new Request.Builder()
            .url(gatewayUrl + "/tx")
            .post(RequestBody.create(
                requestBody,
                MediaType.parse("application/json")
            ))
            .addHeader("Content-Type", "application/json")
            .build();

        // Execute request
        try (Response response = httpClient.newCall(request).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("Arweave upload failed: HTTP " + response.code() + " - " + response.message());
            }

            // Parse response
            String responseBody = response.body().string();
            System.out.println("[Arweave] Response: " + responseBody);

            JsonNode responseJson = objectMapper.readTree(responseBody);
            String txId = responseJson.get("id").asText();

            System.out.println("[Arweave] Upload successful!");
            System.out.println("[Arweave] Transaction ID: " + txId);

            return txId;
        }
    }

    // ========================================================================
    // UTILITY METHODS
    // ========================================================================

    /**
     * Construct Arweave gateway URL for metadata
     *
     * Converts Arweave hash to publicly accessible gateway URL.
     *
     * Hash Format: abc123def456...
     * Gateway URL: https://arweave.net/abc123def456...
     *
     * Multiple gateways available:
     * - https://arweave.net/{hash}
     * - https://arweave.dev/{hash}
     * - https://g8way.io/{hash}
     *
     * @param arweaveHash Arweave transaction ID
     * @return Full gateway URL
     */
    public String getGatewayUrl(String arweaveHash) {
        // Remove "ar-hash-TRUTH-" prefix if mock hash
        if (arweaveHash.startsWith("ar-hash-TRUTH-")) {
            arweaveHash = arweaveHash.substring("ar-hash-TRUTH-".length());
        }

        return gatewayUrl + "/" + arweaveHash;
    }

    /**
     * Validate metadata JSON
     *
     * Checks if metadata conforms to expected structure.
     *
     * Required fields:
     * - name or title
     * - description (optional but recommended)
     *
     * Optional fields:
     * - image (URL to image)
     * - attributes (array of trait_type/value pairs)
     * - external_url (URL to external resource)
     *
     * @param metadata Metadata JSON
     * @return true if valid, false otherwise
     */
    public boolean validateMetadata(JsonNode metadata) {
        if (metadata == null || metadata.isNull()) {
            return false;
        }

        // Check for required fields
        boolean hasName = metadata.has("name") || metadata.has("title");
        
        return hasName;
    }

    /**
     * Check if Arweave service is ready
     *
     * Useful for health checks and testing.
     *
     * @return true if WebClient is initialized, false otherwise
     */
    public boolean isReady() {
        return webClient != null;
    }
}
