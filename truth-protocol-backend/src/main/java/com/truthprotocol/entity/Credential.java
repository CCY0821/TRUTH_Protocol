// ========================================================================
// TRUTH Protocol Backend - Credential Entity
// ========================================================================
// Package: com.truthprotocol.entity
// Purpose: JPA Entity for credentials table (SBT credentials with on-chain & off-chain metadata)
// Database: PostgreSQL (credentials table from V1__init.sql)
// ========================================================================

package com.truthprotocol.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.databind.JsonNode;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

import java.math.BigInteger;
import java.time.Instant;
import java.util.UUID;

/**
 * Credential Entity
 *
 * Represents an SBT (Soulbound Token) credential in the TRUTH Protocol system.
 * Tracks the entire lifecycle from request to on-chain confirmation.
 *
 * Lifecycle Flow:
 * 1. QUEUED    → Request accepted, waiting for Relayer Worker
 * 2. PENDING   → Transaction submitted to blockchain
 * 3. CONFIRMED → Successfully minted on-chain (final state)
 * 4. FAILED    → Minting failed, credits refunded (final state)
 * 5. REVOKED   → Credential revoked by issuer (final state)
 *
 * On-Chain Data:
 * - recipientWalletAddress: EVM wallet address (0x + 40 hex chars)
 * - tokenId: ERC-721 token ID (uint256, stored as BigInteger)
 * - txHash: Blockchain transaction hash (0x + 64 hex chars)
 *
 * Off-Chain Data:
 * - arweaveHash: Arweave permanent storage hash (metadata stored on Arweave)
 * - metadataCache: JSONB cache of metadata (for fast querying without Arweave access)
 *
 * Performance Optimization:
 * - metadataCache is indexed using PostgreSQL GIN index for fast product/batch queries
 * - Example query: WHERE metadata_cache @> '{"product_sku": "PROD-123"}'
 *
 * Database Mapping:
 * - Table: credentials
 * - Primary Key: id (UUID)
 * - Foreign Key: issuer_id → users(id)
 * - Unique Constraint: token_id (partial index on CONFIRMED status only)
 * - Check Constraints: status IN ('QUEUED', 'PENDING', 'CONFIRMED', 'FAILED', 'REVOKED'),
 *                      recipient_wallet_address ~ '^0x[a-fA-F0-9]{40}$',
 *                      tx_hash ~ '^0x[a-fA-F0-9]{64}$',
 *                      token_id >= 0
 *
 * @see User
 * @see CredentialStatus
 */
@Entity
@Table(name = "credentials")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Credential {

    // ========================================================================
    // PRIMARY KEY
    // ========================================================================

    /**
     * Unique credential identifier (UUID v4)
     *
     * Generated automatically using PostgreSQL's uuid_generate_v4() function.
     * Uses JPA's UUID generation strategy for compatibility with Hibernate 6+.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    // ========================================================================
    // FOREIGN KEY (RELATIONSHIP)
    // ========================================================================

    /**
     * Issuer who created this credential (ManyToOne relationship)
     *
     * Business Logic:
     * - Points to the User entity (ISSUER role)
     * - Multiple credentials can be issued by the same user
     * - Foreign key constraint: ON DELETE RESTRICT (cannot delete user with credentials)
     *
     * Database:
     * - Column: issuer_id (UUID)
     * - Indexed: idx_credentials_issuer_id (issuer_id, created_at DESC)
     * - Most common query: "Get all credentials issued by user X"
     *
     * Usage:
     * - credential.getIssuer().getEmail() → Get issuer's email
     * - credential.getIssuer().getCredits() → Check issuer's remaining credits
     */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "issuer_id", nullable = false, foreignKey = @ForeignKey(name = "credentials_issuer_fk"))
    @JsonIgnore  // Prevent lazy loading issues during serialization
    private User issuer;

    // ========================================================================
    // ON-CHAIN INFORMATION
    // ========================================================================

    /**
     * EVM wallet address of the credential recipient (0x + 40 hex chars)
     *
     * Format: 0x followed by 40 hexadecimal characters
     * Example: 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb
     *
     * Validation:
     * - Enforced by CHECK constraint: recipient_wallet_address ~ '^0x[a-fA-F0-9]{40}$'
     * - Should be validated in service layer before saving
     *
     * Database:
     * - Indexed: idx_credentials_recipient_wallet (for Verifier queries)
     * - Used by Verifier to fetch credentials for a specific wallet
     */
    @Column(name = "recipient_wallet_address", nullable = false, length = 42)
    private String recipientWalletAddress;

    /**
     * ERC-721 token ID (uint256 on-chain)
     *
     * Technical Details:
     * - On-chain: uint256 (max value: 2^256 - 1, ~78 decimal digits)
     * - Database: NUMERIC(78, 0) → mapped to BigInteger in Java
     * - NULL until credential is successfully minted (status = CONFIRMED)
     *
     * Uniqueness:
     * - Partial unique index: idx_credentials_token_id WHERE status = 'CONFIRMED'
     * - Ensures no duplicate token IDs for minted credentials
     *
     * Example:
     * - Token ID: 12345678901234567890123456789012345678 (BigInteger)
     * - Generated by smart contract during minting
     */
    @Column(name = "token_id", precision = 78, scale = 0)
    private BigInteger tokenId;

    /**
     * Blockchain transaction hash (0x + 64 hex chars)
     *
     * Format: 0x followed by 64 hexadecimal characters
     * Example: 0x5c504ed432cb51138bcf09aa5e8a410dd4a1e204ef84bfed1be16dfba1b22060
     *
     * Lifecycle:
     * - NULL when status = QUEUED
     * - Populated when status changes to PENDING (transaction submitted)
     * - Immutable after CONFIRMED or FAILED
     *
     * Validation:
     * - Enforced by CHECK constraint: tx_hash ~ '^0x[a-fA-F0-9]{64}$' (if not NULL)
     *
     * Usage:
     * - Used to track transaction on blockchain explorer
     * - Example URL: https://polygonscan.com/tx/{txHash}
     */
    @Column(name = "tx_hash", length = 66)
    private String txHash;

    // ========================================================================
    // OFF-CHAIN METADATA
    // ========================================================================

    /**
     * Arweave permanent storage hash
     *
     * Purpose:
     * - Stores credential metadata permanently on Arweave (decentralized storage)
     * - Arweave guarantees permanent, tamper-proof storage
     * - Used as tokenURI in ERC-721 smart contract
     *
     * Lifecycle:
     * - NULL when status = QUEUED or PENDING
     * - Populated when metadata is uploaded to Arweave (before or after minting)
     * - Immutable after upload
     *
     * Example:
     * - Arweave Hash: ar://abc123xyz789...
     * - Access URL: https://arweave.net/{arweaveHash}
     */
    @Column(name = "arweave_hash", length = 100)
    private String arweaveHash;

    /**
     * JSONB cache of credential metadata (for fast querying)
     *
     * Purpose:
     * - Local cache of metadata stored on Arweave
     * - Enables fast SQL queries without fetching from Arweave
     * - Supports product/batch tracking and analytics
     *
     * Structure (Example):
     * {
     *   "title": "Organic Certification",
     *   "description": "Certificate for organic farming practices",
     *   "product_sku": "PROD-123",
     *   "batch_no": "BATCH-2024-001",
     *   "attributes": [
     *     {"trait_type": "Certification Body", "value": "USDA"},
     *     {"trait_type": "Issue Date", "value": "2024-01-15"},
     *     {"trait_type": "Expiry Date", "value": "2025-01-15"}
     *   ]
     * }
     *
     * Database:
     * - Stored as JSONB (PostgreSQL native JSON type with indexing)
     * - GIN index: idx_credentials_metadata_cache_gin (full JSONB queries)
     * - Specialized GIN indexes:
     *   - idx_credentials_metadata_batch_no → fast batch queries
     *   - idx_credentials_metadata_product_sku → fast product queries
     *
     * Query Examples:
     * - Find by product: WHERE metadata_cache @> '{"product_sku": "PROD-123"}'
     * - Find by batch: WHERE metadata_cache -> 'batch_no' = '"BATCH-001"'
     *
     * Hibernate 6 Mapping:
     * - @JdbcTypeCode(SqlTypes.JSON) → maps to JSONB in PostgreSQL
     * - JsonNode → Jackson's tree model for JSON manipulation
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "metadata_cache", columnDefinition = "jsonb")
    private JsonNode metadataCache;

    // ========================================================================
    // BUSINESS LOGIC & STATUS
    // ========================================================================

    /**
     * Issuer's internal reference ID (for tracking/reconciliation)
     *
     * Purpose:
     * - Allows issuers to link credentials to their internal systems
     * - Used for order tracking, batch management, ERP integration
     * - Optional field (NULL allowed)
     *
     * Example:
     * - Issuer's Order ID: "ORDER-2024-12345"
     * - Issuer's Product SKU: "PROD-ABC-001"
     *
     * Database:
     * - Partial index: idx_credentials_issuer_ref_id WHERE issuer_ref_id IS NOT NULL
     * - Used by issuers to query credentials by their internal ID
     */
    @Column(name = "issuer_ref_id", length = 100)
    private String issuerRefId;

    /**
     * Credential lifecycle status
     *
     * Lifecycle Flow:
     * - QUEUED: Request accepted, waiting for Relayer Worker
     * - PENDING: Transaction submitted to blockchain
     * - CONFIRMED: Successfully minted on-chain
     * - FAILED: Minting failed, credits refunded
     * - REVOKED: Credential revoked by issuer
     *
     * Database:
     * - Stored as VARCHAR(20) using EnumType.STRING
     * - Default value: 'QUEUED'
     * - Indexed: idx_credentials_status (status, created_at)
     * - Used by Relayer Worker to fetch QUEUED/PENDING credentials
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private CredentialStatus status;

    // ========================================================================
    // TIMESTAMPS
    // ========================================================================

    /**
     * Credential creation timestamp (UTC)
     *
     * Represents when the credential request was made.
     * Automatically set by Hibernate on insert.
     * Immutable after creation (updatable = false).
     */
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    /**
     * Last status update timestamp (UTC)
     *
     * Automatically updated by Hibernate on every update.
     * Trigger: update_updated_at_column() ensures database-level updates as well.
     */
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    /**
     * On-chain confirmation timestamp (UTC)
     *
     * Set when status changes to CONFIRMED.
     * NULL for QUEUED, PENDING, FAILED, or REVOKED status.
     *
     * Usage:
     * - Calculate minting duration: confirmedAt - createdAt
     * - Analytics: Average time to mint
     */
    @Column(name = "confirmed_at")
    private Instant confirmedAt;

    // ========================================================================
    // BUILDER DEFAULTS (for Lombok @Builder)
    // ========================================================================

    /**
     * Custom builder class to set default values
     *
     * Usage:
     * Credential credential = Credential.builder()
     *     .issuer(issuerUser)
     *     .recipientWalletAddress("0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb")
     *     .metadataCache(jsonNode)
     *     .build();
     *
     * Defaults:
     * - status: QUEUED
     */
    public static class CredentialBuilder {
        // Set default status if not explicitly provided
        private CredentialStatus status = CredentialStatus.QUEUED;
    }
}
