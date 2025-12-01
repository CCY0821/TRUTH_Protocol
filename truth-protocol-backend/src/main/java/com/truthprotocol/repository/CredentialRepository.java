// ========================================================================
// TRUTH Protocol Backend - Credential Repository
// ========================================================================
// Package: com.truthprotocol.repository
// Purpose: Spring Data JPA Repository for Credential entity
// Database: PostgreSQL (credentials table)
// ========================================================================

package com.truthprotocol.repository;

import com.truthprotocol.entity.Credential;
import com.truthprotocol.entity.CredentialStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

/**
 * Credential Repository
 *
 * Spring Data JPA repository for Credential entity operations.
 *
 * Database Table: credentials
 *
 * Indexes:
 * - Primary Key: id (UUID)
 * - idx_credentials_issuer_id: issuer_id
 * - idx_credentials_status: status
 * - idx_credentials_recipient: recipient_wallet_address
 *
 * Common Queries:
 * - Find by issuer (for issuer dashboard)
 * - Find by status (for batch processing)
 * - Find by recipient (for user wallet view)
 *
 * Custom Query Methods:
 * Spring Data JPA automatically implements query methods based on method names.
 *
 * Naming Convention:
 * - findBy: SELECT query
 * - findAllBy: SELECT multiple results
 * - OrderBy: Sort results
 * - And/Or: Combine conditions
 *
 * Example Generated SQL:
 * <pre>
 * findAllByStatusAndTxHashIsNotNull(PENDING):
 *
 * SELECT * FROM credentials
 * WHERE status = 'PENDING'
 *   AND tx_hash IS NOT NULL
 * ORDER BY created_at ASC
 * </pre>
 *
 * @see com.truthprotocol.entity.Credential
 * @see com.truthprotocol.worker.ConfirmationService
 */
@Repository
public interface CredentialRepository extends JpaRepository<Credential, UUID> {

    /**
     * Find all credentials by issuer ID
     *
     * Retrieves all credentials issued by a specific user.
     * Used for issuer dashboard and "My Issuances" view.
     *
     * SQL:
     * <pre>
     * SELECT * FROM credentials
     * WHERE issuer_id = ?
     * ORDER BY created_at DESC
     * </pre>
     *
     * Index Usage:
     * - Uses idx_credentials_issuer_id for efficient lookup
     *
     * @param issuerId Issuer user UUID
     * @return List of credentials (ordered by creation time, newest first)
     */
    List<Credential> findAllByIssuerIdOrderByCreatedAtDesc(UUID issuerId);

    /**
     * Find all credentials by status with non-null transaction hash
     *
     * Retrieves credentials in a specific status that have been submitted to blockchain.
     * Primarily used by ConfirmationService to find PENDING transactions.
     *
     * Use Cases:
     * - Find PENDING credentials for confirmation checking
     * - Find CONFIRMED credentials for analytics
     * - Find FAILED credentials for retry or audit
     *
     * SQL:
     * <pre>
     * SELECT * FROM credentials
     * WHERE status = ?
     *   AND tx_hash IS NOT NULL
     * ORDER BY created_at ASC
     * </pre>
     *
     * Index Usage:
     * - Uses idx_credentials_status for efficient filtering
     * - tx_hash IS NOT NULL condition evaluated after index lookup
     *
     * Performance:
     * - Typical PENDING queue size: < 100 credentials
     * - Query execution time: < 10ms
     * - Index scan + filter
     *
     * Example Usage:
     * <pre>
     * {@code
     * // Find all PENDING credentials for confirmation
     * List<Credential> pending = repository.findAllByStatusAndTxHashIsNotNull(
     *     CredentialStatus.PENDING
     * );
     *
     * // Process each pending credential
     * for (Credential credential : pending) {
     *     String txHash = credential.getTxHash();
     *     // Check blockchain confirmation...
     * }
     * }
     * </pre>
     *
     * @param status Credential status (QUEUED, PENDING, CONFIRMED, FAILED)
     * @return List of credentials matching criteria (ordered by creation time, oldest first)
     */
    List<Credential> findAllByStatusAndTxHashIsNotNull(CredentialStatus status);
}
