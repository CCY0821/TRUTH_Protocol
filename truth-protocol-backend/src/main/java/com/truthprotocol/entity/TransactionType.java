// ========================================================================
// TRUTH Protocol Backend - Transaction Type Enum
// ========================================================================
// Package: com.truthprotocol.entity
// Purpose: Enum for credit transaction types
// ========================================================================

package com.truthprotocol.entity;

/**
 * Transaction Type Enum
 *
 * Represents different types of credit transactions in the TRUTH Protocol system.
 *
 * Business Rules:
 * - PURCHASE: User purchases credits (adds to balance)
 * - DEDUCT: Credits deducted for minting SBT (subtracts from balance)
 * - REFUND: Credits refunded when minting fails (adds to balance)
 * - ADJUSTMENT: Manual adjustment by admin (can add or subtract)
 *
 * Database Mapping:
 * - Stored as VARCHAR(20) using EnumType.STRING
 * - Used in credit_transactions table
 *
 * @see CreditTransaction
 */
public enum TransactionType {
    /**
     * User purchases credits
     *
     * - Amount: Positive (e.g., +100.00)
     * - Balance: Increases
     * - Trigger: Payment gateway callback, admin top-up
     */
    PURCHASE,

    /**
     * Credits deducted for minting SBT credential
     *
     * - Amount: Negative (e.g., -1.00)
     * - Balance: Decreases
     * - Trigger: Credential minting request
     */
    DEDUCT,

    /**
     * Credits refunded when minting fails
     *
     * - Amount: Positive (e.g., +1.00)
     * - Balance: Increases
     * - Trigger: Credential minting failure, blockchain revert
     */
    REFUND,

    /**
     * Manual adjustment by admin
     *
     * - Amount: Can be positive or negative
     * - Balance: Can increase or decrease
     * - Trigger: Admin correction, promotional credits
     */
    ADJUSTMENT
}
