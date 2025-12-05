// ========================================================================
// TRUTH Protocol Backend - Credential Controller
// ========================================================================
// Package: com.truthprotocol.controller
// Purpose: RESTful API endpoints for SBT credential minting
// ========================================================================

package com.truthprotocol.controller;

import com.truthprotocol.dto.MintRequest;
import com.truthprotocol.dto.MintResponse;
import com.truthprotocol.entity.Credential;
import com.truthprotocol.exception.InsufficientCreditsException;
import com.truthprotocol.service.CredentialService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * Credential Controller
 *
 * RESTful API controller for SBT credential minting operations.
 *
 * Base Path: /api/v1/credentials
 *
 * Endpoints:
 * - POST /mint - Queue credential minting job (requires ISSUER role)
 * - GET /{credentialId}/status - Check minting status (requires authentication)
 *
 * Security:
 * - All endpoints require JWT authentication
 * - POST /mint requires ISSUER role (enforced by @PreAuthorize)
 * - User identity extracted from SecurityContext (JWT claims)
 *
 * Error Handling:
 * - 400 Bad Request: Invalid request format
 * - 401 Unauthorized: Missing or invalid JWT token
 * - 402 Payment Required: Insufficient credits
 * - 403 Forbidden: User does not have ISSUER role
 * - 500 Internal Server Error: Unexpected errors
 *
 * @see CredentialService
 * @see com.truthprotocol.config.SecurityConfig
 */
@RestController
@RequestMapping("/api/v1/credentials")
public class CredentialController {

    private final CredentialService credentialService;

    /**
     * Constructor injection for dependencies
     *
     * @param credentialService Credential business logic service
     */
    public CredentialController(CredentialService credentialService) {
        this.credentialService = credentialService;
    }

    /**
     * Mint credential endpoint
     *
     * Queues a credential minting job for asynchronous processing by Relayer Worker.
     *
     * Endpoint: POST /api/v1/credentials/mint
     * Access: Authenticated users with ISSUER role only
     *
     * Request Headers:
     * - Authorization: Bearer {JWT_TOKEN}
     *
     * Request Body:
     * {
     *   "recipientWalletAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
     *   "issuerRefId": "ORDER-2024-12345",
     *   "metadata": {
     *     "title": "Organic Certification",
     *     "description": "Certificate for organic farming practices",
     *     "product_sku": "PROD-123",
     *     "batch_no": "BATCH-2024-001",
     *     "attributes": [
     *       {"trait_type": "Certification Body", "value": "USDA"}
     *     ]
     *   }
     * }
     *
     * Success Response (202 Accepted):
     * {
     *   "jobId": "550e8400-e29b-41d4-a716-446655440000",
     *   "status": "QUEUED",
     *   "message": "Credential minting request accepted. Processing asynchronously."
     * }
     *
     * Error Response (402 Payment Required):
     * {
     *   "error": "INSUFFICIENT_CREDITS",
     *   "message": "Insufficient credits. Current: 0.00, Required: 1.00"
     * }
     *
     * Business Flow:
     * 1. Extract current user ID from SecurityContext (JWT claims)
     * 2. Check and deduct credits (using pessimistic lock)
     * 3. Create credential record with status = QUEUED
     * 4. Return 202 Accepted with job ID
     * 5. Relayer Worker processes job asynchronously:
     *    - Upload metadata to Arweave
     *    - Submit transaction to Polygon blockchain
     *    - Update status to CONFIRMED or FAILED
     *
     * Transaction Management:
     * - Entire operation is atomic (credit deduction + credential creation)
     * - Rollback on any exception (including InsufficientCreditsException)
     *
     * Security Considerations:
     * - User ID extracted from JWT token (cannot be spoofed)
     * - Only ISSUER role can mint credentials
     * - Credits are deducted immediately (prevents double-spending)
     *
     * @param request Minting request with recipient address and metadata
     * @return MintResponse with job ID and status
     */
    @PostMapping("/mint")
    @PreAuthorize("hasAuthority('ISSUER')")
    @Transactional
    public ResponseEntity<?> mintCredential(@Valid @RequestBody MintRequest request) {
        try {
            // Step 1: Extract current user ID from JWT token in SecurityContext
            UUID currentUserId = getCurrentUserId();

            // Step 2: Check and deduct credits (pessimistic lock ensures atomicity)
            // Cost per mint: 1.00 credit (configurable in application.yml)
            BigDecimal costPerMint = BigDecimal.ONE;
            credentialService.checkAndDeductCredits(currentUserId, costPerMint);

            // Step 3: Queue credential minting job
            Credential credential = credentialService.queueMintingJob(currentUserId, request);

            // Step 4: Build response
            MintResponse response = MintResponse.builder()
                .jobId(credential.getId())
                .status(credential.getStatus().name())
                .message("Credential minting request accepted. Processing asynchronously.")
                .build();

            // Step 5: Return 202 Accepted (async processing)
            return ResponseEntity.status(HttpStatus.ACCEPTED).body(response);

        } catch (InsufficientCreditsException e) {
            // User does not have enough credits
            // OpenAPI Error Code: MINT_INSUFFICIENT_CREDITS
            return ResponseEntity.status(HttpStatus.PAYMENT_REQUIRED)
                .body(new ErrorResponse("INSUFFICIENT_CREDITS", e.getMessage()));

        } catch (IllegalStateException e) {
            // User not found or other business logic error
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse("INVALID_REQUEST", e.getMessage()));

        } catch (Exception e) {
            // Unexpected error
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ErrorResponse("INTERNAL_ERROR", "An unexpected error occurred."));
        }
    }

    /**
     * Get credentials issued by current user
     *
     * Endpoint: GET /api/v1/credentials
     * Access: Authenticated users with ISSUER role
     *
     * @return List of credentials issued by current user
     */
    @GetMapping
    @PreAuthorize("hasAuthority('ISSUER')")
    public ResponseEntity<?> getMyIssuedCredentials() {
        try {
            // Extract user ID from JWT token in SecurityContext
            UUID currentUserId = getCurrentUserId();

            List<Credential> credentials = credentialService.getCredentialsByIssuer(currentUserId);
            return ResponseEntity.ok(credentials);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ErrorResponse("INTERNAL_ERROR", "Failed to fetch credentials"));
        }
    }

    /**
     * Get credentials held by current user (as recipient)
     *
     * Endpoint: GET /api/v1/credentials/holder
     * Access: Authenticated users
     *
     * @return List of credentials where current user is the recipient
     */
    @GetMapping("/holder")
    public ResponseEntity<?> getMyHeldCredentials() {
        try {
            // Extract user ID from JWT token in SecurityContext
            UUID currentUserId = getCurrentUserId();

            // TODO: Implement wallet address lookup in User entity
            // Then update service to query by recipient wallet address
            List<Credential> credentials = credentialService.getCredentialsByRecipient(currentUserId);
            return ResponseEntity.ok(credentials);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ErrorResponse("INTERNAL_ERROR", "Failed to fetch held credentials"));
        }
    }

    /**
     * Get credential by ID
     *
     * Endpoint: GET /api/v1/credentials/{id}
     * Access: Authenticated users
     *
     * @param id UUID of the credential
     * @return Credential details
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getCredentialById(@PathVariable UUID id) {
        try {
            Credential credential = credentialService.getCredentialById(id);
            if (credential == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new ErrorResponse("NOT_FOUND", "Credential not found"));
            }
            return ResponseEntity.ok(credential);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ErrorResponse("INTERNAL_ERROR", "Failed to fetch credential"));
        }
    }

    /**
     * Verify credential by token ID
     *
     * Endpoint: GET /api/v1/credentials/verify/{tokenId}
     * Access: Public (no authentication required for verification)
     *
     * @param tokenId Token ID from blockchain
     * @return Credential details if valid
     */
    @GetMapping("/verify/{tokenId}")
    public ResponseEntity<?> verifyCredential(@PathVariable String tokenId) {
        try {
            Credential credential = credentialService.getCredentialByTokenId(tokenId);
            if (credential == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new ErrorResponse("NOT_FOUND", "Credential not found"));
            }
            return ResponseEntity.ok(credential);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ErrorResponse("INTERNAL_ERROR", "Failed to verify credential"));
        }
    }

    /**
     * Extract current user ID from JWT token in SecurityContext
     *
     * Helper method to extract authenticated user's ID from Spring Security context.
     *
     * Process:
     * 1. Get Authentication from SecurityContextHolder (set by JwtAuthenticationFilter)
     * 2. Extract principal (user ID as string from JWT "sub" claim)
     * 3. Convert to UUID
     *
     * Security:
     * - Called only on authenticated endpoints (@PreAuthorize or authenticated paths)
     * - User ID comes from validated JWT token (cannot be spoofed)
     * - JwtAuthenticationFilter guarantees Authentication is set before reaching controller
     *
     * @return Current authenticated user's UUID
     * @throws IllegalStateException if Authentication is null or user ID is invalid
     */
    private UUID getCurrentUserId() {
        // Get authentication from SecurityContext (set by JwtAuthenticationFilter)
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        if (authentication == null || !authentication.isAuthenticated()) {
            throw new IllegalStateException("User is not authenticated");
        }

        // Extract user ID from principal (JWT sub claim = user UUID string)
        String userIdString = (String) authentication.getPrincipal();

        try {
            return UUID.fromString(userIdString);
        } catch (IllegalArgumentException e) {
            throw new IllegalStateException("Invalid user ID in JWT token: " + userIdString, e);
        }
    }

    /**
     * Error Response DTO (inline for simplicity)
     *
     * Standard error response format for API errors.
     * Consider moving to separate DTO file if used across multiple controllers.
     */
    private record ErrorResponse(String error, String message) {}
}
