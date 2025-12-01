// ========================================================================
// TRUTH Protocol Backend - Insufficient Credits Exception
// ========================================================================
// Package: com.truthprotocol.exception
// Purpose: Custom exception for insufficient credit balance
// ========================================================================

package com.truthprotocol.exception;

/**
 * Insufficient Credits Exception
 *
 * Thrown when a user attempts to mint a credential but does not have
 * sufficient credits in their account.
 *
 * Business Context:
 * - Credits are pre-purchased by ISSUER users (B端 SaaS 預付模式)
 * - Each credential mint operation costs credits
 * - This exception triggers a 402 Payment Required response to frontend
 *
 * Error Mapping:
 * - OpenAPI Error Code: MINT_INSUFFICIENT_CREDITS (BE-02)
 * - HTTP Status: 402 Payment Required
 * - User Action: Top up credits before retrying
 *
 * @see com.truthprotocol.service.CredentialService#checkAndDeductCredits
 */
public class InsufficientCreditsException extends RuntimeException {

    /**
     * Constructs a new InsufficientCreditsException with the specified detail message.
     *
     * @param message the detail message (e.g., "Insufficient credits: balance=0.00, required=1.00")
     */
    public InsufficientCreditsException(String message) {
        super(message);
    }

    /**
     * Constructs a new InsufficientCreditsException with the specified detail message and cause.
     *
     * @param message the detail message
     * @param cause the cause (which is saved for later retrieval by the {@link #getCause()} method)
     */
    public InsufficientCreditsException(String message, Throwable cause) {
        super(message, cause);
    }
}
