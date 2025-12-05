// ========================================================================
// TRUTH Protocol Backend - Transaction History Response DTO
// ========================================================================
// Package: com.truthprotocol.dto
// Purpose: Response DTO for credit transaction history
// ========================================================================

package com.truthprotocol.dto;

import com.truthprotocol.entity.CreditTransaction;
import com.truthprotocol.entity.TransactionType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Transaction History Response DTO
 *
 * Represents a single credit transaction in the user's transaction history.
 * Avoids Hibernate lazy loading issues by using primitive/simple types only.
 *
 * Response Structure:
 * {
 * "id": "uuid",
 * "userId": "uuid",
 * "userName": "user@example.com",
 * "transactionType": "PURCHASE",
 * "amount": 100.00,
 * "balanceAfter": 100.00,
 * "description": "Purchased 100 credits",
 * "paymentReference": "test-payment-001",
 * "credentialId": "uuid",
 * "createdAt": "2025-12-05T..."
 * }
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TransactionHistoryResponse {

    /**
     * Transaction ID
     */
    private String id;

    /**
     * User ID who owns this transaction
     */
    private String userId;

    /**
     * User's email or wallet address (for display)
     */
    private String userName;

    /**
     * Transaction type (PURCHASE, DEDUCT, REFUND, ADJUSTMENT)
     */
    private TransactionType transactionType;

    /**
     * Transaction amount (positive for purchases/refunds, negative for deductions)
     */
    private BigDecimal amount;

    /**
     * User's balance after this transaction
     */
    private BigDecimal balanceAfter;

    /**
     * Transaction description
     */
    private String description;

    /**
     * External payment reference (for PURCHASE transactions)
     */
    private String paymentReference;

    /**
     * Associated credential ID (if transaction is for minting)
     */
    private String credentialId;

    /**
     * Transaction creation timestamp
     */
    private Instant createdAt;

    /**
     * Factory method to create DTO from entity
     *
     * @param transaction Credit transaction entity
     * @return DTO instance
     */
    public static TransactionHistoryResponse fromEntity(CreditTransaction transaction) {
        return TransactionHistoryResponse.builder()
                .id(transaction.getId().toString())
                .userId(transaction.getUser().getId().toString())
                .userName(transaction.getUser().getEmail())
                .transactionType(transaction.getTransactionType())
                .amount(transaction.getAmount())
                .balanceAfter(transaction.getBalanceAfter())
                .description(transaction.getDescription())
                .paymentReference(transaction.getPaymentReference())
                .credentialId(transaction.getCredential() != null
                        ? transaction.getCredential().getId().toString()
                        : null)
                .createdAt(transaction.getCreatedAt())
                .build();
    }
}
