// ========================================================================
// TRUTH Protocol Backend - User Role Enum
// ========================================================================
// Package: com.truthprotocol.entity
// Purpose: Enum for user roles (ISSUER, VERIFIER, ADMIN)
// Maps to: users.role column (VARCHAR(20) with CHECK constraint)
// ========================================================================

package com.truthprotocol.entity;

/**
 * User Role Enum
 *
 * Defines the three types of users in the TRUTH Protocol system:
 * - ISSUER: Organizations that mint SBT credentials (requires KYC approval)
 * - VERIFIER: End-users who verify credentials (C2C verification)
 * - ADMIN: Platform administrators (internal use only)
 *
 * Database Mapping:
 * - Stored as VARCHAR(20) in database (uses @Enumerated(EnumType.STRING))
 * - Enforced by CHECK constraint: role IN ('ISSUER', 'VERIFIER', 'ADMIN')
 *
 * @see User
 */
public enum UserRole {
    /**
     * ISSUER Role (B2B)
     * - Organizations that mint SBT credentials
     * - Requires KYC approval before minting
     * - Uses credits system for minting operations
     * - Examples: Manufacturers, Certification Bodies, Educational Institutions
     */
    ISSUER,

    /**
     * VERIFIER Role (C2C)
     * - End-users who verify credentials
     * - No KYC required for verification
     * - Cannot mint credentials
     * - Examples: Consumers, Employers, Government Agencies
     */
    VERIFIER,

    /**
     * ADMIN Role (Internal)
     * - Platform administrators
     * - Full access to all system features
     * - Can manage users, KYC approvals, and system configuration
     * - Internal use only (not for customer accounts)
     */
    ADMIN
}
