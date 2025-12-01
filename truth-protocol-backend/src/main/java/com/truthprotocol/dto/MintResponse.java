// ========================================================================
// TRUTH Protocol Backend - Mint Response DTO
// ========================================================================
// Package: com.truthprotocol.dto
// Purpose: Data Transfer Object for credential minting response
// ========================================================================

package com.truthprotocol.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Mint Response DTO
 *
 * Data Transfer Object for sending credential minting response to the frontend.
 *
 * HTTP Status: 202 Accepted (async processing)
 * - Indicates that the request has been accepted for processing
 * - Actual minting will be performed asynchronously by Relayer Worker
 *
 * Frontend Usage:
 * - Use jobId to poll status: GET /credentials/{jobId}/status
 * - Display "Minting in progress..." message to user
 * - Listen for WebSocket notifications for status updates
 *
 * @see com.truthprotocol.controller.CredentialController
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MintResponse {

    /**
     * Unique job identifier (Credential UUID)
     *
     * Used to track the minting job status.
     * Frontend can poll: GET /credentials/{jobId}/status
     */
    private UUID jobId;

    /**
     * Current status of the minting job
     *
     * Initial value: "QUEUED"
     * Possible values: QUEUED, PENDING, CONFIRMED, FAILED
     */
    @Builder.Default
    private String status = "QUEUED";

    /**
     * Human-readable message
     *
     * Example: "Credential minting request accepted. Processing asynchronously."
     */
    private String message;
}
