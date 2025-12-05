// ========================================================================
// TRUTH Protocol Backend - Credit Transaction Repository
// ========================================================================
// Package: com.truthprotocol.repository
// Purpose: JPA Repository for credit_transactions table
// ========================================================================

package com.truthprotocol.repository;

import com.truthprotocol.entity.CreditTransaction;
import com.truthprotocol.entity.TransactionType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

/**
 * Credit Transaction Repository
 *
 * Provides database access methods for credit transaction records.
 *
 * Query Methods:
 * - Find all transactions for a user (transaction history)
 * - Find transactions by type (purchases, deductions, refunds)
 * - Find transactions by payment reference (for reconciliation)
 *
 * Performance:
 * - Uses indexes: idx_credit_transactions_user_created, idx_credit_transactions_type
 * - Ordered queries return newest transactions first
 *
 * @see CreditTransaction
 */
@Repository
public interface CreditTransactionRepository extends JpaRepository<CreditTransaction, UUID> {

    /**
     * Find all transactions for a specific user
     *
     * Returns transaction history ordered by creation time (newest first).
     * Used for "My Transaction History" page and balance verification.
     *
     * SQL:
     * <pre>
     * SELECT * FROM credit_transactions
     * WHERE user_id = ?
     * ORDER BY created_at DESC
     * </pre>
     *
     * Index Usage:
     * - Uses idx_credit_transactions_user_created for efficient lookup
     *
     * @param userId User UUID
     * @return List of transactions (newest first)
     */
    List<CreditTransaction> findAllByUser_IdOrderByCreatedAtDesc(UUID userId);

    /**
     * Find all transactions of a specific type for a user
     *
     * Returns filtered transaction history (e.g., only purchases or only deductions).
     *
     * SQL:
     * <pre>
     * SELECT * FROM credit_transactions
     * WHERE user_id = ? AND transaction_type = ?
     * ORDER BY created_at DESC
     * </pre>
     *
     * Index Usage:
     * - Uses idx_credit_transactions_user_created and idx_credit_transactions_type
     *
     * @param userId User UUID
     * @param transactionType Transaction type filter
     * @return List of filtered transactions (newest first)
     */
    List<CreditTransaction> findAllByUser_IdAndTransactionTypeOrderByCreatedAtDesc(
        UUID userId,
        TransactionType transactionType
    );

    /**
     * Find transaction by payment reference
     *
     * Used for payment reconciliation and duplicate prevention.
     *
     * SQL:
     * <pre>
     * SELECT * FROM credit_transactions
     * WHERE payment_reference = ?
     * </pre>
     *
     * Index Usage:
     * - Uses idx_credit_transactions_payment_ref
     *
     * @param paymentReference External payment system reference
     * @return Transaction if found, null otherwise
     */
    CreditTransaction findByPaymentReference(String paymentReference);

    /**
     * Find all transactions related to a specific credential
     *
     * Returns both DEDUCT and REFUND transactions for a credential.
     * Used for minting cost tracking and refund verification.
     *
     * SQL:
     * <pre>
     * SELECT * FROM credit_transactions
     * WHERE credential_id = ?
     * ORDER BY created_at DESC
     * </pre>
     *
     * Index Usage:
     * - Uses idx_credit_transactions_credential
     *
     * @param credentialId Credential UUID
     * @return List of transactions for this credential
     */
    List<CreditTransaction> findAllByCredential_IdOrderByCreatedAtDesc(UUID credentialId);
}
