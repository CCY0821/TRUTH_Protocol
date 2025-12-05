// ========================================================================
// TRUTH Protocol Backend - Credit Transaction Entity
// ========================================================================
// Package: com.truthprotocol.entity
// Purpose: JPA Entity for credit_transactions table
// Database: PostgreSQL (credit_transactions table)
// ========================================================================

package com.truthprotocol.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Credit Transaction Entity
 *
 * Records all credit transactions (purchases, deductions, refunds) for audit trail.
 *
 * Business Rules:
 * - Every credit balance change must have a corresponding transaction record
 * - Transactions are immutable (insert-only, no updates or deletes)
 * - PURCHASE: User buys credits (amount > 0)
 * - DEDUCT: Credits deducted for minting (amount < 0)
 * - REFUND: Credits refunded on failure (amount > 0)
 * - ADJUSTMENT: Admin manual adjustment (amount can be positive or negative)
 *
 * Audit Trail:
 * - All transactions are permanent and immutable
 * - Balance can be reconstructed from transaction history
 * - Supports financial reconciliation and compliance
 *
 * Database Mapping:
 * - Table: credit_transactions
 * - Primary Key: id (UUID)
 * - Foreign Key: user_id references users(id)
 * - Foreign Key: credential_id references credentials(id) (nullable)
 * - Indexes: user_id, created_at for efficient queries
 *
 * @see User
 * @see Credential
 * @see TransactionType
 */
@Entity
@Table(name = "credit_transactions")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreditTransaction {

    // ========================================================================
    // PRIMARY KEY
    // ========================================================================

    /**
     * Unique transaction identifier (UUID v4)
     *
     * Generated automatically using PostgreSQL's uuid_generate_v4() function.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    // ========================================================================
    // FOREIGN KEYS & RELATIONSHIPS
    // ========================================================================

    /**
     * User who owns this transaction
     *
     * References:
     * - users(id) via user_id column
     * - Required for all transactions
     * - Used for balance calculations and transaction history
     */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, foreignKey = @ForeignKey(name = "fk_credit_transaction_user"))
    private User user;

    /**
     * Associated credential (if transaction is for minting)
     *
     * References:
     * - credentials(id) via credential_id column
     * - NULL for PURCHASE and ADJUSTMENT transactions
     * - Set for DEDUCT and REFUND transactions
     * - Links transaction to specific minting job
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "credential_id", foreignKey = @ForeignKey(name = "fk_credit_transaction_credential"))
    private Credential credential;

    // ========================================================================
    // TRANSACTION DETAILS
    // ========================================================================

    /**
     * Transaction type (PURCHASE, DEDUCT, REFUND, ADJUSTMENT)
     *
     * Business Rules:
     * - PURCHASE: User buys credits
     * - DEDUCT: Credits deducted for minting
     * - REFUND: Credits refunded on failure
     * - ADJUSTMENT: Admin manual adjustment
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "transaction_type", nullable = false, length = 20)
    private TransactionType transactionType;

    /**
     * Transaction amount (can be positive or negative)
     *
     * Rules:
     * - PURCHASE: Positive (e.g., +100.00)
     * - DEDUCT: Negative (e.g., -1.00)
     * - REFUND: Positive (e.g., +1.00)
     * - ADJUSTMENT: Can be positive or negative
     *
     * Database:
     * - Stored as NUMERIC(10, 2) for precision
     * - Max value: 99,999,999.99
     * - Precision: 2 decimal places
     */
    @Column(name = "amount", nullable = false, precision = 10, scale = 2)
    private BigDecimal amount;

    /**
     * User's balance AFTER this transaction
     *
     * Purpose:
     * - Snapshot of balance after transaction completes
     * - Used for audit trail and balance verification
     * - Simplifies balance calculation (no need to sum all transactions)
     *
     * Calculation:
     * - balance_after = previous_balance + amount
     *
     * Example:
     * - Previous balance: 100.00
     * - Transaction amount: -1.00 (DEDUCT)
     * - Balance after: 99.00
     */
    @Column(name = "balance_after", nullable = false, precision = 10, scale = 2)
    private BigDecimal balanceAfter;

    /**
     * Optional description or reference
     *
     * Examples:
     * - "Purchased 100 credits via Stripe payment"
     * - "Deducted 1 credit for minting credential ABC123"
     * - "Refunded 1 credit due to minting failure"
     * - "Admin adjustment: Promotional credits"
     *
     * Max length: 500 characters
     */
    @Column(name = "description", length = 500)
    private String description;

    /**
     * External payment reference (for PURCHASE transactions)
     *
     * Examples:
     * - Stripe payment ID: "pi_1234567890"
     * - PayPal transaction ID: "PAYID-1234567890"
     * - Invoice number: "INV-2024-001"
     *
     * Purpose:
     * - Links credit purchase to external payment system
     * - Supports financial reconciliation
     * - Required for refund processing
     *
     * Max length: 255 characters
     */
    @Column(name = "payment_reference", length = 255)
    private String paymentReference;

    // ========================================================================
    // METADATA & TIMESTAMPS
    // ========================================================================

    /**
     * Transaction creation timestamp (UTC)
     *
     * Automatically set by Hibernate on insert.
     * Immutable after creation (updatable = false).
     */
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    // ========================================================================
    // BUILDER DEFAULTS (for Lombok @Builder)
    // ========================================================================

    /**
     * Custom builder class to set default values
     *
     * Usage:
     * CreditTransaction transaction = CreditTransaction.builder()
     *     .user(user)
     *     .transactionType(TransactionType.PURCHASE)
     *     .amount(new BigDecimal("100.00"))
     *     .balanceAfter(new BigDecimal("100.00"))
     *     .description("Purchased 100 credits")
     *     .build();
     */
    public static class CreditTransactionBuilder {
        // No defaults needed for now
    }
}
