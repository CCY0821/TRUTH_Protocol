// ========================================================================
// TRUTH Protocol Backend - KYC Status Enum
// ========================================================================
// Package: com.truthprotocol.entity
// Purpose: Enum for KYC (Know Your Customer) verification status
// Maps to: users.kyc_status column (VARCHAR(20) with CHECK constraint)
// ========================================================================

package com.truthprotocol.entity;

/**
 * KYC (Know Your Customer) Status Enum
 *
 * Defines the KYC verification status for ISSUER users.
 * KYC approval is required before an ISSUER can mint SBT credentials.
 *
 * Business Rules:
 * - PENDING: Default status when ISSUER account is created
 * - APPROVED: KYC verification completed, user can mint credentials
 * - REJECTED: KYC verification failed, user cannot mint (account may be suspended)
 *
 * Database Mapping:
 * - Stored as VARCHAR(20) in database (uses @Enumerated(EnumType.STRING))
 * - Enforced by CHECK constraint: kyc_status IN ('PENDING', 'APPROVED', 'REJECTED')
 * - Default value: 'PENDING'
 *
 * Compliance:
 * - Required for anti-fraud and regulatory compliance
 * - Follows KYC/AML best practices for B2B SaaS platforms
 *
 * @see User
 */
public enum KycStatus {
    /**
     * PENDING Status
     * - Default status when ISSUER account is created
     * - KYC verification not yet completed
     * - User cannot mint credentials until approved
     * - Action Required: Admin must review KYC documents and approve/reject
     */
    PENDING,

    /**
     * APPROVED Status
     * - KYC verification successfully completed
     * - User is authorized to mint SBT credentials
     * - Credits can be purchased and used for minting
     * - Full access to ISSUER features
     */
    APPROVED,

    /**
     * REJECTED Status
     * - KYC verification failed
     * - User cannot mint credentials
     * - Account may be suspended or restricted
     * - Reason for rejection should be communicated to user
     * - User may re-submit KYC documents for re-review
     */
    REJECTED
}
