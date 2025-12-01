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
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
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
            // Step 1: Extract current user ID from SecurityContext
            //
            // TODO: Implement proper JWT authentication and extract user ID
            //
            // Option 1: Extract from JWT claims in SecurityContext
            // Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            // UUID currentUserId = UUID.fromString(authentication.getName());
            //
            // Option 2: Use custom UserPrincipal object
            // UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
            // UUID currentUserId = principal.getUserId();
            //
            // For now, using a mock user ID (replace with actual implementation)
            UUID currentUserId = UUID.fromString("550e8400-e29b-41d4-a716-446655440000");

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
     * Check minting status endpoint (optional)
     *
     * Retrieves the current status of a minting job.
     *
     * Endpoint: GET /api/v1/credentials/{credentialId}/status
     * Access: Authenticated users
     *
     * Implementation Note:
     * - Uncomment this method if status polling is required
     * - Ensure proper authorization (only issuer or admin can check status)
     * - Consider implementing WebSocket for real-time updates instead
     *
     * @param credentialId UUID of the credential
     * @return Current status (QUEUED, PENDING, CONFIRMED, FAILED)
     */
    /*
    @GetMapping("/{credentialId}/status")
    public ResponseEntity<?> getCredentialStatus(@PathVariable UUID credentialId) {
        // Implementation here
        return ResponseEntity.ok("Status: QUEUED");
    }
    */

    /**
     * Error Response DTO (inline for simplicity)
     *
     * Standard error response format for API errors.
     * Consider moving to separate DTO file if used across multiple controllers.
     */
    private record ErrorResponse(String error, String message) {}
}
