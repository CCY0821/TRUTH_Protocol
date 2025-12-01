// ========================================================================
// TRUTH Protocol Backend - User Entity
// ========================================================================
// Package: com.truthprotocol.entity
// Purpose: JPA Entity for users table (Issuer, Verifier, Admin accounts)
// Database: PostgreSQL (users table from V1__init.sql)
// ========================================================================

package com.truthprotocol.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * User Entity
 *
 * Represents a user account in the TRUTH Protocol system.
 * Supports three types of users: ISSUER (B2B), VERIFIER (C2C), and ADMIN.
 *
 * Business Rules:
 * - ISSUER: Organizations that mint SBT credentials (requires KYC approval)
 * - VERIFIER: End-users who verify credentials (no KYC required)
 * - ADMIN: Platform administrators (internal use only)
 *
 * Credits System:
 * - ISSUER accounts use credits to mint SBT credentials
 * - Credits are deducted when credential status changes to PENDING
 * - Credits are refunded if minting fails
 *
 * Compliance:
 * - dataRetentionDate: GDPR/privacy law compliance (auto-delete after retention period)
 * - KYC verification required for ISSUER role
 *
 * Database Mapping:
 * - Table: users
 * - Primary Key: id (UUID)
 * - Unique Constraint: email
 * - Check Constraints: role IN ('ISSUER', 'VERIFIER', 'ADMIN'),
 *                      kyc_status IN ('PENDING', 'APPROVED', 'REJECTED'),
 *                      credits >= 0
 *
 * @see UserRole
 * @see KycStatus
 * @see Credential
 */
@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    // ========================================================================
    // PRIMARY KEY
    // ========================================================================

    /**
     * Unique user identifier (UUID v4)
     *
     * Generated automatically using PostgreSQL's uuid_generate_v4() function.
     * Uses JPA's UUID generation strategy for compatibility with Hibernate 6+.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    // ========================================================================
    // AUTHENTICATION & AUTHORIZATION
    // ========================================================================

    /**
     * User email address (used for login)
     *
     * Constraints:
     * - Must be unique across all users
     * - Max length: 100 characters
     * - Used as username for authentication
     */
    @Column(name = "email", nullable = false, unique = true, length = 100)
    private String email;

    /**
     * bcrypt password hash (60 characters)
     *
     * Security:
     * - Never store plaintext passwords
     * - bcrypt hash is always 60 characters (cost factor encoded in hash)
     * - Use Spring Security's BCryptPasswordEncoder for hashing
     *
     * Example:
     * - Plaintext: "MyPassword123"
     * - Bcrypt Hash: "$2a$10$N9qo8uLOickgx2ZMRZoMye/IY/lGhzzN7mIQGLJ9.OrVLWyJkzJVy"
     */
    @Column(name = "password_hash", nullable = false, length = 60)
    private String passwordHash;

    /**
     * User role (ISSUER, VERIFIER, ADMIN)
     *
     * Business Logic:
     * - ISSUER: Organizations that mint SBT credentials (requires KYC)
     * - VERIFIER: End-users who verify credentials (no KYC required)
     * - ADMIN: Platform administrators (internal use only)
     *
     * Database:
     * - Stored as VARCHAR(20) using EnumType.STRING
     * - Default value: 'ISSUER'
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "role", nullable = false, length = 20)
    private UserRole role;

    // ========================================================================
    // KYC & COMPLIANCE
    // ========================================================================

    /**
     * KYC (Know Your Customer) verification status
     *
     * Business Rules:
     * - PENDING: Default status when ISSUER account is created
     * - APPROVED: KYC verification completed, user can mint credentials
     * - REJECTED: KYC verification failed, user cannot mint
     *
     * Compliance:
     * - Required for anti-fraud and regulatory compliance
     * - Only relevant for ISSUER role (VERIFIER and ADMIN do not require KYC)
     *
     * Database:
     * - Stored as VARCHAR(20) using EnumType.STRING
     * - Default value: 'PENDING'
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "kyc_status", nullable = false, length = 20)
    private KycStatus kycStatus;

    /**
     * GDPR/Privacy Law Compliance: Data Retention Date
     *
     * Purpose:
     * - Supports GDPR "Right to be Forgotten" and data retention policies
     * - After this date, user's personal information should be anonymized or deleted
     * - Automated data deletion jobs should query this field
     *
     * Business Logic:
     * - Set automatically based on user's country/region data retention laws
     * - Example: EU GDPR = 2 years after last activity
     * - NULL if no retention policy applies
     *
     * Database:
     * - Partial index exists: WHERE data_retention_date IS NOT NULL
     * - Query for expired data: WHERE data_retention_date < NOW()
     */
    @Column(name = "data_retention_date")
    private Instant dataRetentionDate;

    // ========================================================================
    // BUSINESS LOGIC (CREDITS SYSTEM)
    // ========================================================================

    /**
     * Remaining credits for minting SBT credentials
     *
     * Business Rules:
     * - Only relevant for ISSUER role (VERIFIER and ADMIN have 0 credits)
     * - Credits are deducted when credential status changes to PENDING
     * - Credits are refunded if minting fails (status = FAILED)
     * - Cost per mint: Configured in application.yml (app.credits.cost-per-mint)
     *
     * Database:
     * - Stored as NUMERIC(10, 2) for precision (avoids floating-point errors)
     * - Max value: 99,999,999.99 (10 digits total, 2 decimal places)
     * - Default value: 0.00
     * - Check constraint: credits >= 0 (cannot be negative)
     *
     * Example:
     * - User purchases 100 credits
     * - Minting 1 SBT costs 1.00 credit
     * - After minting 10 SBTs, remaining credits = 90.00
     */
    @Column(name = "credits", nullable = false, precision = 10, scale = 2)
    private BigDecimal credits;

    // ========================================================================
    // METADATA & TIMESTAMPS
    // ========================================================================

    /**
     * Account creation timestamp (UTC)
     *
     * Automatically set by Hibernate on insert.
     * Immutable after creation (updatable = false).
     */
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    /**
     * Last account update timestamp (UTC)
     *
     * Automatically updated by Hibernate on every update.
     * Trigger: update_updated_at_column() ensures database-level updates as well.
     */
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    /**
     * Last successful login timestamp (UTC)
     *
     * Updated by authentication service on successful login.
     * NULL if user has never logged in.
     */
    @Column(name = "last_login_at")
    private Instant lastLoginAt;

    // ========================================================================
    // BUILDER DEFAULTS (for Lombok @Builder)
    // ========================================================================

    /**
     * Custom builder class to set default values
     *
     * Usage:
     * User user = User.builder()
     *     .email("issuer@example.com")
     *     .passwordHash("$2a$10$...")
     *     .build();
     *
     * Defaults:
     * - role: ISSUER
     * - kycStatus: PENDING
     * - credits: 0.00
     */
    public static class UserBuilder {
        // Set default values if not explicitly provided
        private UserRole role = UserRole.ISSUER;
        private KycStatus kycStatus = KycStatus.PENDING;
        private BigDecimal credits = BigDecimal.ZERO;
    }
}
