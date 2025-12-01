// ========================================================================
// TRUTH Protocol Backend - Mint Request DTO
// ========================================================================
// Package: com.truthprotocol.dto
// Purpose: Data Transfer Object for credential minting request
// ========================================================================

package com.truthprotocol.dto;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Mint Request DTO
 *
 * Data Transfer Object for receiving credential minting requests from the frontend.
 * Contains all necessary information to create a new SBT credential.
 *
 * Validation:
 * - All fields are validated using Jakarta Bean Validation annotations
 * - Service layer performs additional business logic validation
 *
 * @see com.truthprotocol.entity.Credential
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MintRequest {

    /**
     * EVM wallet address of the credential recipient (0x + 40 hex chars)
     *
     * Format: 0x followed by 40 hexadecimal characters
     * Example: 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb
     */
    @NotBlank(message = "Recipient wallet address is required")
    @Pattern(
        regexp = "^0x[a-fA-F0-9]{40}$",
        message = "Invalid Ethereum wallet address format"
    )
    private String recipientWalletAddress;

    /**
     * Issuer's internal reference ID (optional)
     *
     * Used for tracking and reconciliation with issuer's internal systems.
     */
    private String issuerRefId;

    /**
     * Credential metadata (JSON object)
     *
     * Will be uploaded to Arweave and cached in database as JSONB.
     *
     * Expected structure:
     * {
     *   "title": "Organic Certification",
     *   "description": "Certificate for organic farming practices",
     *   "product_sku": "PROD-123",
     *   "batch_no": "BATCH-2024-001",
     *   "attributes": [
     *     {"trait_type": "Certification Body", "value": "USDA"},
     *     {"trait_type": "Issue Date", "value": "2024-01-15"}
     *   ]
     * }
     */
    @NotNull(message = "Metadata is required")
    private JsonNode metadata;
}
