// ========================================================================
// TRUTH Protocol Backend - Credit Service
// ========================================================================
// Package: com.truthprotocol.service
// Purpose: Business logic for credit management (purchase, deduct, refund)
// ========================================================================

package com.truthprotocol.service;

import com.truthprotocol.entity.Credential;
import com.truthprotocol.entity.CreditTransaction;
import com.truthprotocol.entity.TransactionType;
import com.truthprotocol.entity.User;
import com.truthprotocol.repository.CreditTransactionRepository;
import com.truthprotocol.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * Credit Service
 *
 * Manages credit operations for TRUTH Protocol business model.
 *
 * Core Functions:
 * - Purchase credits (add to balance)
 * - Deduct credits (subtract for minting)
 * - Refund credits (return on failure)
 * - Get transaction history
 * - Get current balance
 *
 * Business Rules:
 * - All credit operations are atomic (transaction-based)
 * - Every balance change creates an immutable transaction record
 * - Balance cannot go negative (enforced by database constraint)
 * - Duplicate payments are prevented via payment_reference check
 *
 * @see CreditTransaction
 * @see User
 */
@Service
public class CreditService {

    private final UserRepository userRepository;
    private final CreditTransactionRepository transactionRepository;

    public CreditService(
        UserRepository userRepository,
        CreditTransactionRepository transactionRepository
    ) {
        this.userRepository = userRepository;
        this.transactionRepository = transactionRepository;
    }

    // ========================================================================
    // PURCHASE CREDITS
    // ========================================================================

    /**
     * Purchase credits for a user
     *
     * Adds credits to user's balance and creates PURCHASE transaction record.
     *
     * Business Flow:
     * 1. Lock user record (pessimistic lock)
     * 2. Check for duplicate payment (via payment_reference)
     * 3. Add credits to balance
     * 4. Create PURCHASE transaction record
     * 5. Save user and transaction
     *
     * Usage:
     * - Called after payment gateway callback (Stripe, PayPal)
     * - Called by admin for manual top-up
     *
     * @param userId User UUID
     * @param amount Amount of credits to add (must be positive)
     * @param description Transaction description
     * @param paymentReference External payment system reference (optional)
     * @return Created transaction record
     * @throws IllegalArgumentException if amount is not positive
     * @throws IllegalStateException if user not found or duplicate payment
     */
    @Transactional
    public CreditTransaction purchaseCredits(
        UUID userId,
        BigDecimal amount,
        String description,
        String paymentReference
    ) {
        // Validation
        if (amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Purchase amount must be positive: " + amount);
        }

        // Check for duplicate payment
        if (paymentReference != null) {
            CreditTransaction existing = transactionRepository.findByPaymentReference(paymentReference);
            if (existing != null) {
                throw new IllegalStateException("Duplicate payment reference: " + paymentReference);
            }
        }

        // Lock user record and add credits
        User user = userRepository.findByIdForUpdate(userId)
            .orElseThrow(() -> new IllegalStateException("User not found: " + userId));

        BigDecimal previousBalance = user.getCredits();
        BigDecimal newBalance = previousBalance.add(amount);
        user.setCredits(newBalance);

        // Save user
        userRepository.save(user);

        // Create transaction record
        CreditTransaction transaction = CreditTransaction.builder()
            .user(user)
            .transactionType(TransactionType.PURCHASE)
            .amount(amount)
            .balanceAfter(newBalance)
            .description(description)
            .paymentReference(paymentReference)
            .build();

        return transactionRepository.save(transaction);
    }

    // ========================================================================
    // DEDUCT CREDITS (for minting)
    // ========================================================================

    /**
     * Deduct credits for minting a credential
     *
     * Subtracts credits from user's balance and creates DEDUCT transaction record.
     *
     * NOTE: This method is typically called from CredentialService.checkAndDeductCredits()
     * which already locks the user record. This method records the transaction.
     *
     * Business Flow:
     * 1. User record is already locked by caller
     * 2. Create DEDUCT transaction record
     * 3. Link transaction to credential
     *
     * Usage:
     * - Called after successful credit deduction in minting process
     * - Creates audit trail for credential minting cost
     *
     * @param user User entity (already updated with new balance)
     * @param amount Amount of credits deducted (should be positive, will be stored as negative)
     * @param credential Associated credential
     * @param description Transaction description
     * @return Created transaction record
     */
    @Transactional
    public CreditTransaction recordDeduction(
        User user,
        BigDecimal amount,
        Credential credential,
        String description
    ) {
        // Create transaction record (amount is stored as negative for deductions)
        BigDecimal negativeAmount = amount.negate();

        CreditTransaction transaction = CreditTransaction.builder()
            .user(user)
            .credential(credential)
            .transactionType(TransactionType.DEDUCT)
            .amount(negativeAmount)
            .balanceAfter(user.getCredits())
            .description(description != null ? description : "Deducted " + amount + " credits for minting credential")
            .build();

        return transactionRepository.save(transaction);
    }

    // ========================================================================
    // REFUND CREDITS (on minting failure)
    // ========================================================================

    /**
     * Refund credits when minting fails
     *
     * Returns credits to user's balance and creates REFUND transaction record.
     *
     * Business Flow:
     * 1. Lock user record
     * 2. Add credits back to balance
     * 3. Create REFUND transaction record
     * 4. Link transaction to credential
     *
     * Usage:
     * - Called when credential minting fails
     * - Called when blockchain transaction reverts
     * - Restores user's balance to state before minting attempt
     *
     * @param userId User UUID
     * @param amount Amount of credits to refund (must be positive)
     * @param credential Associated credential
     * @param description Refund reason
     * @return Created transaction record
     * @throws IllegalArgumentException if amount is not positive
     * @throws IllegalStateException if user not found
     */
    @Transactional
    public CreditTransaction refundCredits(
        UUID userId,
        BigDecimal amount,
        Credential credential,
        String description
    ) {
        // Validation
        if (amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Refund amount must be positive: " + amount);
        }

        // Lock user record and add credits back
        User user = userRepository.findByIdForUpdate(userId)
            .orElseThrow(() -> new IllegalStateException("User not found: " + userId));

        BigDecimal previousBalance = user.getCredits();
        BigDecimal newBalance = previousBalance.add(amount);
        user.setCredits(newBalance);

        // Save user
        userRepository.save(user);

        // Create transaction record
        CreditTransaction transaction = CreditTransaction.builder()
            .user(user)
            .credential(credential)
            .transactionType(TransactionType.REFUND)
            .amount(amount)
            .balanceAfter(newBalance)
            .description(description != null ? description : "Refunded " + amount + " credits due to minting failure")
            .build();

        return transactionRepository.save(transaction);
    }

    // ========================================================================
    // QUERY METHODS
    // ========================================================================

    /**
     * Get current credit balance for a user
     *
     * @param userId User UUID
     * @return Current credit balance
     * @throws IllegalStateException if user not found
     */
    @Transactional(readOnly = true)
    public BigDecimal getBalance(UUID userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new IllegalStateException("User not found: " + userId));
        return user.getCredits();
    }

    /**
     * Get transaction history for a user
     *
     * Returns all credit transactions ordered by creation time (newest first).
     *
     * @param userId User UUID
     * @return List of transactions (newest first)
     */
    @Transactional(readOnly = true)
    public List<CreditTransaction> getTransactionHistory(UUID userId) {
        return transactionRepository.findAllByUser_IdOrderByCreatedAtDesc(userId);
    }

    /**
     * Get filtered transaction history by type
     *
     * Returns only transactions of specified type (e.g., only purchases).
     *
     * @param userId User UUID
     * @param transactionType Transaction type filter
     * @return List of filtered transactions (newest first)
     */
    @Transactional(readOnly = true)
    public List<CreditTransaction> getTransactionHistoryByType(
        UUID userId,
        TransactionType transactionType
    ) {
        return transactionRepository.findAllByUser_IdAndTransactionTypeOrderByCreatedAtDesc(
            userId,
            transactionType
        );
    }
}
