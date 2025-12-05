// ========================================================================
// TRUTH Protocol Backend - Credit Controller
// ========================================================================
// Package: com.truthprotocol.controller
// Purpose: RESTful API endpoints for credit management
// ========================================================================

package com.truthprotocol.controller;

import com.truthprotocol.dto.CreditBalanceResponse;
import com.truthprotocol.dto.PurchaseCreditsRequest;
import com.truthprotocol.entity.CreditTransaction;
import com.truthprotocol.service.CreditService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Credit Controller
 *
 * RESTful API controller for credit management operations.
 *
 * Base Path: /api/v1/credits
 *
 * Endpoints:
 * - GET /balance - Get current credit balance
 * - GET /history - Get transaction history
 * - POST /purchase - Purchase credits (admin or payment callback)
 *
 * Security:
 * - All endpoints require JWT authentication
 * - Purchase endpoint requires ADMIN role (for manual top-up)
 *
 * @see CreditService
 */
@RestController
@RequestMapping("/api/v1/credits")
public class CreditController {

    private final CreditService creditService;

    public CreditController(CreditService creditService) {
        this.creditService = creditService;
    }

    /**
     * Get current credit balance
     *
     * Endpoint: GET /api/v1/credits/balance
     * Access: Authenticated users
     *
     * @return Current balance
     */
    @GetMapping("/balance")
    public ResponseEntity<?> getBalance() {
        try {
            UUID userId = getCurrentUserId();
            CreditBalanceResponse response = CreditBalanceResponse.builder()
                .userId(userId.toString())
                .balance(creditService.getBalance(userId))
                .build();
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ErrorResponse("INTERNAL_ERROR", e.getMessage()));
        }
    }

    /**
     * Get transaction history
     *
     * Endpoint: GET /api/v1/credits/history
     * Access: Authenticated users
     *
     * @return List of transactions (newest first)
     */
    @GetMapping("/history")
    public ResponseEntity<?> getTransactionHistory() {
        try {
            UUID userId = getCurrentUserId();
            List<CreditTransaction> history = creditService.getTransactionHistory(userId);
            return ResponseEntity.ok(history);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ErrorResponse("INTERNAL_ERROR", e.getMessage()));
        }
    }

    /**
     * Purchase credits (manual top-up by admin or payment callback)
     *
     * Endpoint: POST /api/v1/credits/purchase
     * Access: Admin only (for manual top-up)
     *
     * NOTE: In production, this endpoint should be called by payment gateway
     * webhook (Stripe, PayPal) with proper authentication.
     *
     * @param request Purchase request
     * @return Created transaction
     */
    @PostMapping("/purchase")
    @PreAuthorize("hasAuthority('ADMIN') or hasAuthority('ISSUER')")
    public ResponseEntity<?> purchaseCredits(@Valid @RequestBody PurchaseCreditsRequest request) {
        try {
            UUID userId = getCurrentUserId();

            String description = request.getDescription() != null
                ? request.getDescription()
                : "Purchased " + request.getAmount() + " credits";

            CreditTransaction transaction = creditService.purchaseCredits(
                userId,
                request.getAmount(),
                description,
                request.getPaymentReference()
            );

            return ResponseEntity.status(HttpStatus.CREATED).body(transaction);
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(new ErrorResponse("DUPLICATE_PAYMENT", e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse("INVALID_REQUEST", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ErrorResponse("INTERNAL_ERROR", e.getMessage()));
        }
    }

    // Helper method to extract current user ID from JWT
    private UUID getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new IllegalStateException("User is not authenticated");
        }
        String userIdString = (String) authentication.getPrincipal();
        return UUID.fromString(userIdString);
    }

    // Error response DTO
    private record ErrorResponse(String error, String message) {}
}
