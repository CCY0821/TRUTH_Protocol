// ========================================================================
// TRUTH Protocol Backend - Login Request DTO
// ========================================================================
// Package: com.truthprotocol.dto
// Purpose: Data Transfer Object for user login request
// ========================================================================

package com.truthprotocol.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Login Request DTO
 *
 * Data Transfer Object for receiving user login credentials from the frontend.
 *
 * Validation:
 * - Email format validation
 * - Non-empty password requirement
 *
 * Security:
 * - Password is sent as plaintext over HTTPS
 * - Never log or persist this DTO containing plaintext password
 *
 * @see com.truthprotocol.controller.AuthController
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoginRequest {

    /**
     * User's email address (used as username)
     *
     * Format: Standard email format validation
     * Example: issuer@example.com
     */
    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    private String email;

    /**
     * User's plaintext password
     *
     * Security:
     * - Transmitted over HTTPS only
     * - Never logged or stored in plaintext
     * - Validated against BCrypt hash in database
     */
    @NotBlank(message = "Password is required")
    private String password;
}
