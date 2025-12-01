// ========================================================================
// TRUTH Protocol Backend - Arweave Service
// ========================================================================
// Package: com.truthprotocol.worker
// Purpose: Upload credential metadata to Arweave for permanent storage
// ========================================================================

package com.truthprotocol.worker;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.UUID;

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
     * WebClient for HTTP requests
     *
     * Why WebClient:
     * - Modern Spring WebFlux reactive client
     * - Non-blocking I/O (better for high concurrency)
     * - Built-in timeout and retry support
     * - Better than RestTemplate (deprecated in Spring 6+)
     *
     * Alternative: Apache HttpClient, OkHttp, or Java 11+ HttpClient
     */
    private WebClient webClient;

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
        this.webClient = WebClient.builder()
            .baseUrl(gatewayUrl)
            .defaultHeader("Content-Type", "application/json")
            .defaultHeader("Accept", "application/json")
            .build();

        System.out.println("Arweave Service initialized");
        System.out.println("Gateway URL: " + gatewayUrl);
        System.out.println("Timeout: " + timeoutMs + "ms");
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
        try {
            System.out.println("Uploading metadata to Arweave...");

            // Log metadata size for monitoring
            String metadataJson = objectMapper.writeValueAsString(metadata);
            int dataSize = metadataJson.getBytes().length;
            System.out.println("Metadata size: " + dataSize + " bytes");

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

            // ================================================================
            // MOCK IMPLEMENTATION (Current)
            // ================================================================
            //
            // Simulate network delay for realistic testing
            // In production, this represents:
            // - Network latency (50-200ms)
            // - Gateway processing (200-500ms)
            // - Transaction creation (100-300ms)
            // - Total: 350-1000ms typical, up to 5s worst case
            //
            // For testing, we use a shorter delay (500-2000ms)
            //
            long delayMs = 500 + (long) (Math.random() * 1500);  // 500-2000ms
            System.out.println("Simulating Arweave upload delay: " + delayMs + "ms");
            Thread.sleep(delayMs);

            // Generate mock Arweave hash
            // Format: ar-hash-TRUTH-{UUID}
            // This format is easily identifiable as mock data
            String mockHash = "ar-hash-TRUTH-" + UUID.randomUUID().toString();

            System.out.println("Arweave upload successful (mock)");
            System.out.println("Arweave hash: " + mockHash);

            return mockHash;

            // ================================================================
            // END MOCK IMPLEMENTATION
            // ================================================================

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Arweave upload interrupted", e);

        } catch (Exception e) {
            System.err.println("Failed to upload metadata to Arweave: " + e.getMessage());

            // In production, throw custom exception:
            // throw new ArweaveUploadException("Failed to upload metadata", e);
            //
            // Custom exception class (to be created):
            // public class ArweaveUploadException extends RuntimeException {
            //     public ArweaveUploadException(String message, Throwable cause) {
            //         super(message, cause);
            //     }
            // }
            //
            // This allows ItemProcessor to:
            // - Catch and retry (for transient network errors)
            // - Mark credential as FAILED (for permanent errors)
            // - Log error details for debugging

            throw new RuntimeException("Failed to upload metadata to Arweave", e);
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
