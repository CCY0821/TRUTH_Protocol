// ========================================================================
// TRUTH Protocol Backend - Credential Status Enum
// ========================================================================
// Package: com.truthprotocol.entity
// Purpose: Enum for SBT credential lifecycle status
// Maps to: credentials.status column (VARCHAR(20) with CHECK constraint)
// ========================================================================

package com.truthprotocol.entity;

/**
 * Credential Lifecycle Status Enum
 *
 * Defines the lifecycle status of an SBT credential from creation to on-chain confirmation.
 * Tracks the async minting process handled by the Relayer Worker.
 *
 * Lifecycle Flow:
 * 1. QUEUED    → Request accepted, waiting for Relayer Worker
 * 2. PENDING   → Transaction submitted to blockchain
 * 3. CONFIRMED → Successfully minted on-chain (final state)
 * 4. FAILED    → Minting failed, credits refunded (final state)
 * 5. REVOKED   → Credential revoked by issuer (final state)
 *
 * Database Mapping:
 * - Stored as VARCHAR(20) in database (uses @Enumerated(EnumType.STRING))
 * - Enforced by CHECK constraint: status IN ('QUEUED', 'PENDING', 'CONFIRMED', 'FAILED', 'REVOKED')
 * - Default value: 'QUEUED'
 *
 * Business Rules:
 * - Credits are deducted when status changes from QUEUED to PENDING
 * - Credits are refunded if status changes to FAILED
 * - CONFIRMED and REVOKED are final states (no further transitions)
 *
 * @see Credential
 */
public enum CredentialStatus {
    /**
     * QUEUED Status (Initial State)
     * - Request accepted and saved to database
     * - Waiting for Relayer Worker to process
     * - Credits not yet deducted
     * - No on-chain transaction submitted
     *
     * Next States: PENDING, FAILED
     * Trigger: Relayer Worker picks up credential for processing
     */
    QUEUED,

    /**
     * PENDING Status (Processing)
     * - Relayer Worker has submitted transaction to blockchain
     * - Credits have been deducted from issuer account
     * - Waiting for blockchain confirmation
     * - tx_hash populated with transaction hash
     *
     * Next States: CONFIRMED, FAILED
     * Trigger: Blockchain confirms transaction or transaction fails
     * Timeout: If no confirmation after N blocks, retry or mark as FAILED
     */
    PENDING,

    /**
     * CONFIRMED Status (Final Success State)
     * - Transaction confirmed on blockchain
     * - SBT successfully minted to recipient wallet
     * - token_id populated with ERC-721 token ID
     * - confirmed_at timestamp recorded
     * - Metadata uploaded to Arweave (arweave_hash populated)
     *
     * Next States: REVOKED (only via explicit revocation)
     * Final State: Yes (immutable on-chain)
     */
    CONFIRMED,

    /**
     * FAILED Status (Final Failure State)
     * - Minting failed (e.g., transaction reverted, gas price too low, network error)
     * - Credits refunded to issuer account
     * - Error reason should be logged
     * - User notified of failure
     *
     * Next States: None (terminal state)
     * Action: User can create a new credential request
     */
    FAILED,

    /**
     * REVOKED Status (Final Revoked State)
     * - Credential revoked by issuer (business logic decision)
     * - On-chain status may be updated via smart contract (if supported)
     * - Credential no longer valid for verification
     * - Cannot be un-revoked (permanent decision)
     *
     * Next States: None (terminal state)
     * Trigger: Issuer explicitly revokes credential (e.g., product recall, fraud detection)
     */
    REVOKED
}
