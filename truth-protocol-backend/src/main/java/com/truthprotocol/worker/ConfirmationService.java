// ========================================================================
// TRUTH Protocol Backend - Blockchain Confirmation Service
// ========================================================================
// Package: com.truthprotocol.worker
// Purpose: Monitor PENDING transactions and extract Token IDs from blockchain
// ========================================================================

package com.truthprotocol.worker;

import com.truthprotocol.entity.Credential;
import com.truthprotocol.entity.CredentialStatus;
import com.truthprotocol.repository.CredentialRepository;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.methods.response.EthGetTransactionReceipt;
import org.web3j.protocol.core.methods.response.Log;
import org.web3j.protocol.core.methods.response.TransactionReceipt;

import java.math.BigInteger;
import java.time.Instant;
import java.util.List;
import java.util.Optional;

/**
 * Blockchain Confirmation Service
 *
 * Monitors PENDING transactions and updates credential status upon blockchain confirmation.
 *
 * Responsibilities:
 * - Periodically check PENDING credentials for transaction confirmation
 * - Parse transaction receipts to extract Token ID from contract events
 * - Update credential status to CONFIRMED or FAILED
 * - Extract and store tokenId from Minted event
 *
 * Confirmation Process:
 * 1. Query all PENDING credentials with non-null txHash
 * 2. For each credential:
 *    a. Fetch transaction receipt from blockchain
 *    b. Check if transaction is confirmed (>= 12 blocks)
 *    c. Parse contract events (Minted event)
 *    d. Extract tokenId from event logs
 *    e. Update credential status and tokenId
 *
 * TruthSBT Contract Event:
 * <pre>
 * event Minted(uint256 indexed tokenId, address indexed recipient, string metadataUri);
 * </pre>
 *
 * Event Topics:
 * - topics[0]: keccak256("Minted(uint256,address,string)")
 * - topics[1]: tokenId (indexed)
 * - topics[2]: recipient address (indexed)
 * - data: metadataUri (non-indexed)
 *
 * Transaction States:
 * - PENDING: Transaction broadcasted, waiting for confirmation
 * - CONFIRMED: Transaction confirmed with >= 12 blocks, tokenId extracted
 * - FAILED: Transaction reverted or rejected by blockchain
 *
 * Scheduling:
 * - Runs every 60 seconds (@Scheduled fixedRate)
 * - Can be adjusted via configuration
 * - Processes all PENDING credentials in batch
 *
 * Performance:
 * - Processing time: ~100-500ms per credential (RPC call)
 * - Batch size: All PENDING credentials (typically < 100)
 * - Total time: ~1-50 seconds per batch
 *
 * Error Handling:
 * - Network errors: Log and retry on next schedule
 * - RPC errors: Skip and retry on next schedule
 * - Failed transactions: Mark as FAILED
 *
 * @see com.truthprotocol.worker.Web3jRelayerService
 * @see com.truthprotocol.repository.CredentialRepository
 */
@Service
public class ConfirmationService {

    // ========================================================================
    // DEPENDENCIES
    // ========================================================================

    private final CredentialRepository credentialRepository;
    private final Web3jRelayerService web3jRelayerService;

    /**
     * Minimum confirmations required for transaction finality
     *
     * Polygon PoS:
     * - Fast finality: 2-3 blocks (~4-6 seconds)
     * - Safe finality: 12 blocks (~24 seconds)
     * - Deep finality: 128 blocks (~4 minutes)
     *
     * Recommendation: 12 blocks for production
     */
    private static final int MIN_CONFIRMATIONS = 12;

    /**
     * Constructor injection
     *
     * @param credentialRepository Credential repository
     * @param web3jRelayerService Web3j service for blockchain access
     */
    public ConfirmationService(
        CredentialRepository credentialRepository,
        Web3jRelayerService web3jRelayerService
    ) {
        this.credentialRepository = credentialRepository;
        this.web3jRelayerService = web3jRelayerService;
    }

    // ========================================================================
    // SCHEDULED TASKS
    // ========================================================================

    /**
     * Process PENDING credentials (scheduled task).
     *
     * Runs every 60 seconds to check blockchain confirmation status for PENDING credentials.
     * For each confirmed transaction, extracts the tokenId and updates credential status.
     */
    @Scheduled(fixedRate = 60000)  // Execute every 60 seconds
    @Transactional
    public void processPendingCredentials() {
        System.out.println("=========================================");
        System.out.println("Blockchain Confirmation Service - Starting");
        System.out.println("Time: " + Instant.now());
        System.out.println("=========================================");

        try {
            // Step 1: Query all PENDING credentials with txHash
            List<Credential> pendingCredentials = credentialRepository
                .findAllByStatusAndTxHashIsNotNull(CredentialStatus.PENDING);

            if (pendingCredentials.isEmpty()) {
                System.out.println("No PENDING credentials to process");
                System.out.println("=========================================");
                return;
            }

            System.out.println("Found " + pendingCredentials.size() + " PENDING credentials");

            // Statistics counters
            int confirmedCount = 0;
            int failedCount = 0;
            int stillPendingCount = 0;

            // Step 2: Process each PENDING credential
            for (Credential credential : pendingCredentials) {
                try {
                    System.out.println("-----------------------------------------");
                    System.out.println("Processing credential: " + credential.getId());
                    System.out.println("Transaction Hash: " + credential.getTxHash());

                    // Step 3: Check transaction confirmation
                    ConfirmationResult result = checkTransactionConfirmation(credential.getTxHash());

                    // Step 4: Update credential based on result
                    if (result.isConfirmed()) {
                        // Transaction confirmed successfully
                        System.out.println("✓ Transaction confirmed");
                        System.out.println("  Token ID: " + result.getTokenId());
                        System.out.println("  Block Number: " + result.getBlockNumber());

                        credential.setTokenId(result.getTokenId());
                        credential.setStatus(CredentialStatus.CONFIRMED);
                        credential.setConfirmedAt(Instant.now());
                        credentialRepository.save(credential);

                        confirmedCount++;

                    } else if (result.isFailed()) {
                        // Transaction failed (reverted or rejected)
                        System.err.println("✗ Transaction failed");
                        System.err.println("  Reason: " + result.getFailureReason());

                        credential.setStatus(CredentialStatus.FAILED);
                        credential.setUpdatedAt(Instant.now());
                        credentialRepository.save(credential);

                        failedCount++;

                    } else {
                        // Still pending (not enough confirmations)
                        System.out.println("⏳ Transaction still pending");
                        System.out.println("  Current confirmations: " + result.getConfirmations());
                        System.out.println("  Required confirmations: " + MIN_CONFIRMATIONS);

                        stillPendingCount++;
                    }

                } catch (Exception e) {
                    System.err.println("✗ Error processing credential " + credential.getId());
                    System.err.println("  Error: " + e.getMessage());
                    // Continue processing other credentials
                }
            }

            // Step 5: Log processing statistics
            System.out.println("=========================================");
            System.out.println("Processing completed");
            System.out.println("  Confirmed: " + confirmedCount);
            System.out.println("  Failed: " + failedCount);
            System.out.println("  Still Pending: " + stillPendingCount);
            System.out.println("=========================================");

        } catch (Exception e) {
            System.err.println("=========================================");
            System.err.println("✗ Fatal error in confirmation service");
            System.err.println("Error: " + e.getMessage());
            System.err.println("=========================================");
            e.printStackTrace();
        }
    }

    // ========================================================================
    // TRANSACTION CONFIRMATION METHODS
    // ========================================================================

    /**
     * Check transaction confirmation status
     *
     * Fetches transaction receipt from blockchain and determines confirmation status.
     *
     * Process:
     * 1. Fetch transaction receipt via RPC
     * 2. Check if receipt exists (transaction mined)
     * 3. Get current block number
     * 4. Calculate confirmations (current block - tx block)
     * 5. Check if confirmations >= MIN_CONFIRMATIONS
     * 6. Parse contract events to extract tokenId
     * 7. Return confirmation result
     *
     * Transaction Receipt Structure:
     * <pre>
     * {
     *   "transactionHash": "0xabc123...",
     *   "blockNumber": 12345678,
     *   "status": "0x1",  // 1 = success, 0 = failed
     *   "logs": [
     *     {
     *       "address": "0xContractAddress",
     *       "topics": [
     *         "0xEventSignature",
     *         "0xTokenId",
     *         "0xRecipient"
     *       ],
     *       "data": "0xMetadataUri"
     *     }
     *   ]
     * }
     * </pre>
     *
     * Confirmation Calculation:
     * - Current block: 12345700
     * - Transaction block: 12345678
     * - Confirmations: 12345700 - 12345678 = 22 blocks
     * - Required: 12 blocks
     * - Status: CONFIRMED ✓
     *
     * Event Parsing (Production):
     * <pre>
     * {@code
     * // Define contract event
     * Event mintedEvent = new Event(
     *     "Minted",
     *     Arrays.asList(
     *         new TypeReference<Uint256>(true) {},  // tokenId (indexed)
     *         new TypeReference<Address>(true) {},  // recipient (indexed)
     *         new TypeReference<Utf8String>() {}    // metadataUri
     *     )
     * );
     *
     * // Parse event from logs
     * for (Log log : receipt.getLogs()) {
     *     EventValues eventValues = Contract.staticExtractEventParameters(mintedEvent, log);
     *     BigInteger tokenId = (BigInteger) eventValues.getIndexedValues().get(0).getValue();
     *     return tokenId;
     * }
     * }
     * </pre>
     *
     * @param txHash Transaction hash
     * @return Confirmation result with status and tokenId
     */
    private ConfirmationResult checkTransactionConfirmation(String txHash) {
        try {
            // Get Web3j instance
            Web3j web3j = getWeb3j();

            // Step 1: Fetch transaction receipt
            EthGetTransactionReceipt receiptResponse = web3j
                .ethGetTransactionReceipt(txHash)
                .send();

            Optional<TransactionReceipt> receiptOptional = receiptResponse.getTransactionReceipt();

            if (!receiptOptional.isPresent()) {
                // Transaction not yet mined
                return ConfirmationResult.pending(0);
            }

            TransactionReceipt receipt = receiptOptional.get();

            // Step 2: Check transaction status
            String status = receipt.getStatus();
            if ("0x0".equals(status)) {
                // Transaction failed (reverted)
                return ConfirmationResult.failed("Transaction reverted by contract");
            }

            // Step 3: Get current block number
            BigInteger currentBlock = web3j.ethBlockNumber().send().getBlockNumber();
            BigInteger txBlock = receipt.getBlockNumber();

            // Step 4: Calculate confirmations
            int confirmations = currentBlock.subtract(txBlock).intValue();

            // Step 5: Check if enough confirmations
            if (confirmations < MIN_CONFIRMATIONS) {
                // Not enough confirmations yet
                return ConfirmationResult.pending(confirmations);
            }

            // Step 6: Extract tokenId from contract event logs
            BigInteger tokenId = extractTokenIdFromLogs(receipt.getLogs());

            // Step 7: Return confirmed result
            return ConfirmationResult.confirmed(tokenId, txBlock.longValue());

        } catch (Exception e) {
            System.err.println("Error checking transaction confirmation: " + e.getMessage());
            // Return pending to retry on next schedule
            return ConfirmationResult.pending(0);
        }
    }

    /**
     * Extract Token ID from transaction receipt logs
     *
     * Parses contract event logs to extract the minted tokenId.
     *
     * TruthSBT Minted Event:
     * <pre>
     * event Minted(uint256 indexed tokenId, address indexed recipient, string metadataUri);
     * </pre>
     *
     * Event Signature:
     * - keccak256("Minted(uint256,address,string)")
     * - Result: 0x... (32 bytes)
     *
     * Event Topics:
     * - topics[0]: Event signature
     * - topics[1]: tokenId (uint256, indexed)
     * - topics[2]: recipient (address, indexed)
     *
     * Event Data:
     * - metadataUri (string, non-indexed)
     *
     * Parsing Example:
     * <pre>
     * Log:
     *   topics: [
     *     "0x...",  // Event signature
     *     "0x000000000000000000000000000000000000000000000000000000000000002a",  // tokenId = 42
     *     "0x000000000000000000000000742d35cc6634c0532925a3b844bc9e7595f0beb"   // recipient
     *   ]
     *   data: "0x..."  // metadataUri
     *
     * Extracted tokenId: 42
     * </pre>
     *
     * TODO (Production Implementation):
     * 1. Define contract ABI for Minted event
     * 2. Use Web3j Event class to parse logs
     * 3. Extract indexed tokenId from topics[1]
     * 4. Convert hex to BigInteger
     *
     * Current Implementation (Mock):
     * - Generates mock tokenId based on timestamp
     * - Format: timestamp % 1,000,000
     * - Range: 0 - 999,999
     *
     * @param logs Transaction receipt logs
     * @return Extracted tokenId
     */
    private BigInteger extractTokenIdFromLogs(List<Log> logs) {
        // ================================================================
        // PRODUCTION IMPLEMENTATION (TODO)
        // ================================================================
        //
        // Step 1: Define Minted event
        // Event mintedEvent = new Event(
        //     "Minted",
        //     Arrays.asList(
        //         new TypeReference<Uint256>(true) {},   // tokenId (indexed)
        //         new TypeReference<Address>(true) {},   // recipient (indexed)
        //         new TypeReference<Utf8String>() {}     // metadataUri
        //     )
        // );
        //
        // Step 2: Iterate through logs
        // for (Log log : logs) {
        //     // Check if log is from SBT contract
        //     if (!log.getAddress().equalsIgnoreCase(sbtContractAddress)) {
        //         continue;
        //     }
        //
        //     try {
        //         // Parse event
        //         EventValues eventValues = Contract.staticExtractEventParameters(mintedEvent, log);
        //
        //         // Extract tokenId (first indexed parameter)
        //         BigInteger tokenId = (BigInteger) eventValues.getIndexedValues().get(0).getValue();
        //
        //         System.out.println("Extracted tokenId from event: " + tokenId);
        //         return tokenId;
        //
        //     } catch (Exception e) {
        //         // Not a Minted event, continue
        //     }
        // }
        //
        // throw new RuntimeException("Minted event not found in transaction logs");
        //
        // ================================================================

        // ================================================================
        // MOCK IMPLEMENTATION (Current)
        // ================================================================
        //
        // Generate mock tokenId based on timestamp
        // This simulates extracting a unique token ID from the blockchain
        //
        // In production, this would be the actual tokenId minted by the contract
        //
        long mockTokenId = System.currentTimeMillis() % 1_000_000L;
        System.out.println("Mock tokenId extracted: " + mockTokenId);
        return BigInteger.valueOf(mockTokenId);
        //
        // ================================================================
    }

    // ========================================================================
    // HELPER METHODS
    // ========================================================================

    /**
     * Get Web3j instance from Web3jRelayerService
     *
     * Accesses the initialized Web3j instance for blockchain queries.
     *
     * @return Web3j instance
     * @throws IllegalStateException if Web3j is not initialized
     */
    private Web3j getWeb3j() {
        Web3j web3j = web3jRelayerService.getWeb3j();
        
        if (web3j == null) {
            throw new IllegalStateException(
                "Web3j is not initialized. Check Web3jRelayerService configuration."
            );
        }
        
        return web3j;
    }

    // ========================================================================
    // CONFIRMATION RESULT CLASS
    // ========================================================================

    /**
     * Confirmation Result
     *
     * Encapsulates the result of a transaction confirmation check.
     *
     * States:
     * - CONFIRMED: Transaction confirmed with >= MIN_CONFIRMATIONS
     * - FAILED: Transaction reverted or rejected
     * - PENDING: Transaction not yet confirmed
     */
    private static class ConfirmationResult {
        private final Status status;
        private final BigInteger tokenId;
        private final Long blockNumber;
        private final Integer confirmations;
        private final String failureReason;

        private enum Status {
            CONFIRMED,
            FAILED,
            PENDING
        }

        private ConfirmationResult(
            Status status,
            BigInteger tokenId,
            Long blockNumber,
            Integer confirmations,
            String failureReason
        ) {
            this.status = status;
            this.tokenId = tokenId;
            this.blockNumber = blockNumber;
            this.confirmations = confirmations;
            this.failureReason = failureReason;
        }

        public static ConfirmationResult confirmed(BigInteger tokenId, Long blockNumber) {
            return new ConfirmationResult(Status.CONFIRMED, tokenId, blockNumber, null, null);
        }

        public static ConfirmationResult failed(String reason) {
            return new ConfirmationResult(Status.FAILED, null, null, null, reason);
        }

        public static ConfirmationResult pending(int confirmations) {
            return new ConfirmationResult(Status.PENDING, null, null, confirmations, null);
        }

        public boolean isConfirmed() {
            return status == Status.CONFIRMED;
        }

        public boolean isFailed() {
            return status == Status.FAILED;
        }

        public BigInteger getTokenId() {
            return tokenId;
        }

        public Long getBlockNumber() {
            return blockNumber;
        }

        public Integer getConfirmations() {
            return confirmations;
        }

        public String getFailureReason() {
            return failureReason;
        }
    }
}
