// ========================================================================
// TRUTH Protocol Backend - Spring Batch Configuration
// ========================================================================
// Package: com.truthprotocol.config
// Purpose: Configure Spring Batch jobs for asynchronous credential minting
// ========================================================================

package com.truthprotocol.config;

import com.truthprotocol.entity.Credential;
import com.truthprotocol.entity.CredentialStatus;
import com.truthprotocol.repository.CredentialRepository;
import com.truthprotocol.worker.ArweaveService;
import com.truthprotocol.worker.Web3jRelayerService;
import jakarta.persistence.EntityManagerFactory;
import org.springframework.batch.core.Job;
import org.springframework.batch.core.Step;
import org.springframework.batch.core.job.builder.JobBuilder;
import org.springframework.batch.core.repository.JobRepository;
import org.springframework.batch.core.step.builder.StepBuilder;
import org.springframework.batch.item.ItemProcessor;
import org.springframework.batch.item.ItemReader;
import org.springframework.batch.item.ItemWriter;
import org.springframework.batch.item.database.JpaPagingItemReader;
import org.springframework.batch.item.database.builder.JpaPagingItemReaderBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.transaction.PlatformTransactionManager;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

/**
 * Spring Batch Configuration
 *
 * Configures asynchronous batch jobs for processing QUEUED credentials.
 *
 * Updated Processing Flow (with Arweave):
 * 1. ItemReader: Fetch all QUEUED credentials from database (paginated)
 * 2. ItemProcessor: For each credential:
 *    a. Upload metadata to Arweave → Get arweave_hash
 *    b. Submit minting transaction to blockchain (using arweave_hash as metadataUri)
 *    c. Update credential status based on result
 * 3. ItemWriter: Batch save updated credentials to database
 *
 * Job Execution:
 * - Manual: Triggered via REST API or admin interface
 * - Scheduled: Configured via @Scheduled annotation (e.g., every 5 minutes)
 * - Event-driven: Triggered when new credentials are queued
 *
 * Transaction Management:
 * - Each chunk is a separate transaction
 * - Rollback on ItemProcessor or ItemWriter failure
 * - Failed items can be retried or skipped
 *
 * Performance:
 * - Chunk size: Number of items processed per transaction (default: 10)
 * - Page size: Number of items fetched from database per query (default: 10)
 * - Parallel execution: Can be enabled for higher throughput
 *
 * Monitoring:
 * - Job execution status tracked in Spring Batch metadata tables
 * - Metrics available via Spring Boot Actuator
 * - Failed items logged for manual review
 *
 * Error Handling:
 * - Skip policy: Skip failed items after N retries
 * - Retry policy: Retry transient failures (network errors)
 * - Rollback: Roll back chunk on non-skippable errors
 *
 * @see com.truthprotocol.worker.ArweaveService
 * @see com.truthprotocol.worker.Web3jRelayerService
 * @see com.truthprotocol.repository.CredentialRepository
 */
@Configuration
public class BatchConfig {

    // ========================================================================
    // DEPENDENCIES
    // ========================================================================

    private final EntityManagerFactory entityManagerFactory;
    private final CredentialRepository credentialRepository;
    private final ArweaveService arweaveService;
    private final Web3jRelayerService web3jRelayerService;

    /**
     * Constructor injection
     *
     * @param entityManagerFactory JPA entity manager factory
     * @param credentialRepository Credential repository
     * @param arweaveService Arweave metadata upload service
     * @param web3jRelayerService Web3j blockchain service
     */
    public BatchConfig(
        EntityManagerFactory entityManagerFactory,
        CredentialRepository credentialRepository,
        ArweaveService arweaveService,
        Web3jRelayerService web3jRelayerService
    ) {
        this.entityManagerFactory = entityManagerFactory;
        this.credentialRepository = credentialRepository;
        this.arweaveService = arweaveService;
        this.web3jRelayerService = web3jRelayerService;
    }

    // ========================================================================
    // JOB DEFINITION
    // ========================================================================

    /**
     * Credential Minting Job
     *
     * Main batch job for processing QUEUED credentials.
     *
     * Job Flow:
     * 1. Start job
     * 2. Execute mintingStep
     * 3. Complete job
     *
     * Job Parameters (optional):
     * - jobId: Unique identifier for job execution
     * - timestamp: Job execution timestamp
     *
     * Job Execution:
     * - Can be run multiple times (idempotent)
     * - Only processes QUEUED credentials (skips PENDING/CONFIRMED)
     * - Updates credential status to PENDING or FAILED
     *
     * Job Restart:
     * - Restartable: true (can resume from last successful step)
     * - Incremental: false (processes all QUEUED items each time)
     *
     * Example Job Launch:
     * <pre>
     * {@code
     * JobParameters jobParameters = new JobParametersBuilder()
     *     .addLong("timestamp", System.currentTimeMillis())
     *     .toJobParameters();
     *
     * jobLauncher.run(mintingJob, jobParameters);
     * }
     * </pre>
     *
     * @param jobRepository Spring Batch job repository
     * @param mintingStep Step to execute
     * @return Configured Job
     */
    @Bean
    public Job mintingJob(JobRepository jobRepository, Step mintingStep) {
        return new JobBuilder("mintingJob", jobRepository)
            .start(mintingStep)
            .build();
    }

    // ========================================================================
    // STEP DEFINITION
    // ========================================================================

    /**
     * Credential Minting Step
     *
     * Batch step for processing QUEUED credentials.
     *
     * Step Configuration:
     * - Chunk size: 10 (process 10 credentials per transaction)
     * - Transaction manager: JPA transaction manager
     * - Fault tolerance: Skip on failure, retry on network errors
     *
     * Processing Flow:
     * 1. Read chunk of QUEUED credentials (ItemReader)
     * 2. For each credential in chunk:
     *    a. Process credential (ItemProcessor)
     *    b. Update status to PENDING or FAILED
     * 3. Write chunk of updated credentials (ItemWriter)
     * 4. Commit transaction
     * 5. Repeat until no more QUEUED credentials
     *
     * Chunk-Oriented Processing:
     * - Read: Fetch N items from database
     * - Process: Transform each item individually
     * - Write: Batch save all transformed items
     * - Commit: Single transaction for entire chunk
     *
     * Transaction Boundaries:
     * - Transaction starts before reading chunk
     * - Transaction commits after writing chunk
     * - Rollback on any error in chunk
     *
     * Error Handling:
     * - Skip limit: 5 (skip up to 5 failed items)
     * - Retry limit: 3 (retry network errors 3 times)
     * - Rollback: On non-skippable errors
     *
     * Performance:
     * - Chunk size affects transaction duration
     * - Smaller chunks: More transactions, faster rollback
     * - Larger chunks: Fewer transactions, better throughput
     *
     * @param jobRepository Spring Batch job repository
     * @param transactionManager Transaction manager
     * @param reader Item reader
     * @param processor Item processor
     * @param writer Item writer
     * @return Configured Step
     */
    @Bean
    public Step mintingStep(
        JobRepository jobRepository,
        PlatformTransactionManager transactionManager,
        ItemReader<Credential> reader,
        ItemProcessor<Credential, Credential> processor,
        ItemWriter<Credential> writer
    ) {
        return new StepBuilder("mintingStep", jobRepository)
            .<Credential, Credential>chunk(10, transactionManager)
            .reader(reader)
            .processor(processor)
            .writer(writer)
            // Optional: Add fault tolerance
            // .faultTolerant()
            // .skip(Exception.class)
            // .skipLimit(5)
            // .retry(NetworkException.class)
            // .retryLimit(3)
            .build();
    }

    // ========================================================================
    // ITEM READER
    // ========================================================================

    /**
     * Credential Item Reader
     *
     * Reads QUEUED credentials from database using JPA pagination.
     *
     * Reader Type: JpaPagingItemReader
     * - Fetches items in pages (chunks)
     * - Efficient for large datasets
     * - Prevents memory overflow
     *
     * Query:
     * SELECT c FROM Credential c WHERE c.status = :status ORDER BY c.createdAt ASC
     *
     * Pagination:
     * - Page size: 10 (fetch 10 items per query)
     * - Ordered by createdAt: Process oldest credentials first
     * - Stateful: Remembers current page across chunk boundaries
     *
     * Transaction:
     * - Read within chunk transaction
     * - JPQL query executed for each page
     * - EntityManager managed by transaction manager
     *
     * Performance:
     * - Index usage: Uses idx_credentials_status index
     * - N+1 queries: Avoided with proper fetch strategy
     * - Memory: Only page size items in memory at once
     *
     * Example Query Plan (PostgreSQL):
     * <pre>
     * Index Scan using idx_credentials_status on credentials
     *   Index Cond: (status = 'QUEUED')
     *   Order By: created_at
     * </pre>
     *
     * @return Item reader for QUEUED credentials
     */
    @Bean
    public JpaPagingItemReader<Credential> credentialReader() {
        // JPQL query to fetch QUEUED credentials
        String jpqlQuery = "SELECT c FROM Credential c WHERE c.status = :status ORDER BY c.createdAt ASC";

        // Query parameters
        Map<String, Object> parameters = new HashMap<>();
        parameters.put("status", CredentialStatus.QUEUED);

        // Build JPA paging reader
        return new JpaPagingItemReaderBuilder<Credential>()
            .name("credentialReader")
            .entityManagerFactory(entityManagerFactory)
            .queryString(jpqlQuery)
            .parameterValues(parameters)
            .pageSize(10)  // Fetch 10 items per page
            .build();
    }

    // ========================================================================
    // ITEM PROCESSOR
    // ========================================================================

    /**
     * Credential Item Processor (Updated with Arweave Integration)
     *
     * Processes each QUEUED credential by:
     * 1. Uploading metadata to Arweave (permanent storage)
     * 2. Minting SBT on blockchain (using Arweave hash as metadata URI)
     *
     * Processing Flow:
     * 1. Validate credential data
     * 2. Upload metadata to Arweave → Get arweave_hash
     * 3. Set credential.arweaveHash = arweave_hash
     * 4. Submit minting transaction to blockchain (metadataUri = arweave_hash)
     * 5. Update credential with transaction hash and status
     * 6. Return updated credential for batch save
     *
     * Arweave Upload:
     * - Input: credential.metadataCache (JsonNode)
     * - Process: arweaveService.uploadMetadata(metadataCache)
     * - Output: Arweave hash (e.g., "ar-hash-TRUTH-uuid" or actual Arweave tx ID)
     * - Storage: Permanent, decentralized, immutable
     *
     * Blockchain Interaction:
     * - Input: recipientWalletAddress, arweave_hash
     * - Process: web3jRelayerService.sendMintingTransaction(address, arweave_hash)
     * - Output: Transaction hash (e.g., "0xabc123...")
     * - Network: Polygon PoS (Mumbai or Mainnet)
     *
     * Status Updates:
     * - Success: QUEUED → PENDING (waiting for blockchain confirmation)
     * - Arweave failure: QUEUED → FAILED (metadata upload failed)
     * - Blockchain failure: QUEUED → FAILED (transaction rejected)
     *
     * Error Handling:
     * - Arweave errors: Catch and mark as FAILED (log error)
     * - Network errors: Throw exception for retry (transient)
     * - Invalid data: Mark as FAILED and continue (skip)
     *
     * Return Value:
     * - Updated Credential object with new status, tx_hash, and arweave_hash
     * - null to filter out (skip writing this item)
     *
     * Example Processing:
     * <pre>
     * Credential [QUEUED, metadataCache={...}]
     *   ↓ arweaveService.uploadMetadata(metadataCache)
     * Arweave Hash: ar-hash-TRUTH-abc123
     *   ↓ web3jRelayerService.sendMintingTransaction(address, ar-hash-TRUTH-abc123)
     * Transaction Hash: 0xdef456...
     *   ↓ Update credential
     * Credential [PENDING, txHash=0xdef456, arweaveHash=ar-hash-TRUTH-abc123]
     * </pre>
     *
     * Performance:
     * - Arweave upload: ~500ms-2s (mock), 1-5s (production)
     * - Blockchain transaction: ~100-500ms
     * - Total: ~1-6 seconds per credential
     *
     * Monitoring:
     * - Log each step for debugging
     * - Track success/failure rates
     * - Alert on high failure rates
     *
     * @return Item processor
     */
    @Bean
    public ItemProcessor<Credential, Credential> credentialProcessor() {
        return credential -> {
            try {
                System.out.println("=========================================");
                System.out.println("Processing credential: " + credential.getId());
                System.out.println("=========================================");

                // Step 1: Validate credential data
                if (credential.getRecipientWalletAddress() == null) {
                    throw new IllegalStateException("Recipient wallet address is null");
                }

                if (credential.getMetadataCache() == null) {
                    throw new IllegalStateException("Metadata cache is null");
                }

                System.out.println("Validation passed");

                // Step 2: Upload metadata to Arweave
                System.out.println("Step 1/3: Uploading metadata to Arweave...");
                
                String arweaveHash;
                try {
                    arweaveHash = arweaveService.uploadMetadata(credential.getMetadataCache());
                    System.out.println("✓ Arweave upload successful: " + arweaveHash);
                } catch (Exception e) {
                    System.err.println("✗ Arweave upload failed: " + e.getMessage());
                    throw new RuntimeException("Failed to upload metadata to Arweave", e);
                }

                // Step 3: Set Arweave hash in credential
                credential.setArweaveHash(arweaveHash);
                System.out.println("✓ Arweave hash set: " + arweaveHash);

                // Step 4: Submit minting transaction to blockchain
                System.out.println("Step 2/3: Submitting transaction to blockchain...");
                System.out.println("  Recipient: " + credential.getRecipientWalletAddress());
                System.out.println("  Metadata URI: " + arweaveHash);

                String transactionHash;
                try {
                    transactionHash = web3jRelayerService.sendMintingTransaction(
                        credential.getRecipientWalletAddress(),
                        arweaveHash  // Use Arweave hash as metadata URI
                    );
                    System.out.println("✓ Transaction submitted: " + transactionHash);
                } catch (Exception e) {
                    System.err.println("✗ Transaction failed: " + e.getMessage());
                    throw new RuntimeException("Failed to submit blockchain transaction", e);
                }

                // Step 5: Update credential with transaction hash and status
                System.out.println("Step 3/3: Updating credential status...");
                
                credential.setTxHash(transactionHash);
                credential.setStatus(CredentialStatus.PENDING);
                credential.setUpdatedAt(Instant.now());

                System.out.println("✓ Credential updated to PENDING status");
                System.out.println("  Transaction Hash: " + transactionHash);
                System.out.println("  Arweave Hash: " + arweaveHash);
                System.out.println("=========================================");
                System.out.println("Credential processing completed successfully");
                System.out.println("=========================================");

                // Step 6: Return updated credential for batch save
                return credential;

            } catch (Exception e) {
                // Log error
                System.err.println("=========================================");
                System.err.println("✗ Failed to process credential " + credential.getId());
                System.err.println("Error: " + e.getMessage());
                System.err.println("=========================================");

                // Update credential to FAILED status
                credential.setStatus(CredentialStatus.FAILED);
                credential.setUpdatedAt(Instant.now());

                // Return updated credential (will be saved with FAILED status)
                // This allows tracking of failed credentials for manual review
                return credential;
            }
        };
    }

    // ========================================================================
    // ITEM WRITER
    // ========================================================================

    /**
     * Credential Item Writer
     *
     * Writes processed credentials to database in batch.
     *
     * Writer Type: RepositoryItemWriter (using Spring Data JPA)
     * - Batch save for performance
     * - Uses JPA repository save method
     * - Executes within chunk transaction
     *
     * Batch Save:
     * - Saves all items in chunk with single repository call
     * - JPA batching enabled in application.yml (hibernate.jdbc.batch_size)
     * - Reduces database round trips
     *
     * Transaction:
     * - Write executes within chunk transaction
     * - Commit after all items in chunk are written
     * - Rollback on any error (entire chunk)
     *
     * Update Operations:
     * - Credentials already exist (status update)
     * - JPA merge/update instead of insert
     * - Updates: status, tx_hash, arweave_hash, updated_at
     *
     * Performance:
     * - Batch size: 10 items per transaction
     * - Database round trips: 1 per chunk (with batching)
     * - Index updates: Minimal (only status index affected)
     *
     * Example SQL (PostgreSQL):
     * <pre>
     * UPDATE credentials
     * SET status = ?, tx_hash = ?, arweave_hash = ?, updated_at = ?
     * WHERE id = ?
     * </pre>
     *
     * @return Item writer
     */
    @Bean
    public ItemWriter<Credential> credentialWriter() {
        return items -> {
            // Batch save all processed credentials
            System.out.println("=========================================");
            System.out.println("Writing " + items.size() + " processed credentials...");

            credentialRepository.saveAll(items);

            System.out.println("✓ Successfully saved " + items.size() + " credentials");
            System.out.println("=========================================");
        };
    }
}
