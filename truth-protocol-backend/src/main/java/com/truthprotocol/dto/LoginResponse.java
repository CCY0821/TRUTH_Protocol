// ========================================================================
// TRUTH Protocol Backend - Login Response DTO
// ========================================================================
// Package: com.truthprotocol.dto
// Purpose: Data Transfer Object for successful login response
// ========================================================================

package com.truthprotocol.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Login Response DTO
 *
 * Data Transfer Object for sending successful login response to the frontend.
 *
 * Contains:
 * - JWT access token for authentication
 * - User information (ID, email, role)
 *
 * Frontend Usage:
 * - Store token in secure storage (e.g., HttpOnly cookie or localStorage)
 * - Include token in Authorization header for subsequent requests
 * - Header format: "Authorization: Bearer {token}"
 *
 * @see com.truthprotocol.controller.AuthController
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoginResponse {

    /**
     * JWT access token
     *
     * Format: Base64 encoded JWT (header.payload.signature)
     * Validity: Configured in application.yml (e.g., 24 hours)
     * Example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
     */
    private String token;

    /**
     * Token type (always "Bearer" for JWT)
     */
    @Builder.Default
    private String tokenType = "Bearer";

    /**
     * User's unique identifier
     */
    private UUID userId;

    /**
     * User's email address
     */
    private String email;

    /**
     * User's role (ISSUER, VERIFIER, ADMIN)
     */
    private String role;
}
