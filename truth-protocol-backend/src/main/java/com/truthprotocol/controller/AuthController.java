// ========================================================================
// TRUTH Protocol Backend - Authentication Controller
// ========================================================================
// Package: com.truthprotocol.controller
// Purpose: RESTful API endpoints for user authentication
// ========================================================================

package com.truthprotocol.controller;

import com.truthprotocol.dto.LoginRequest;
import com.truthprotocol.dto.LoginResponse;
import com.truthprotocol.entity.User;
import com.truthprotocol.security.JwtTokenProvider;
import com.truthprotocol.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.web.bind.annotation.*;

/**
 * Authentication Controller
 *
 * RESTful API controller for user authentication operations.
 *
 * Base Path: /api/v1/auth
 *
 * Endpoints:
 * - POST /login - User login (public endpoint)
 * - POST /register - User registration (public endpoint, optional)
 *
 * Security:
 * - Login endpoint is public (permitAll in SecurityConfig)
 * - No JWT token required for authentication requests
 * - Returns JWT token on successful login
 *
 * Error Handling:
 * - 400 Bad Request: Invalid request format
 * - 401 Unauthorized: Invalid credentials
 * - 500 Internal Server Error: Unexpected errors
 *
 * @see AuthService
 * @see JwtTokenProvider
 * @see com.truthprotocol.config.SecurityConfig
 */
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;
    private final JwtTokenProvider jwtTokenProvider;

    /**
     * Constructor injection for dependencies
     *
     * @param authService Authentication service for user validation
     * @param jwtTokenProvider JWT token provider for token generation
     */
    public AuthController(AuthService authService, JwtTokenProvider jwtTokenProvider) {
        this.authService = authService;
        this.jwtTokenProvider = jwtTokenProvider;
    }

    /**
     * User login endpoint
     *
     * Validates user credentials and returns JWT token on success.
     *
     * Endpoint: POST /api/v1/auth/login
     * Access: Public (no authentication required)
     *
     * Request Body:
     * {
     *   "email": "issuer@example.com",
     *   "password": "SecurePassword123"
     * }
     *
     * Success Response (200 OK):
     * {
     *   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
     *   "tokenType": "Bearer",
     *   "userId": "550e8400-e29b-41d4-a716-446655440000",
     *   "email": "issuer@example.com",
     *   "role": "ISSUER"
     * }
     *
     * Error Response (401 Unauthorized):
     * {
     *   "error": "INVALID_CREDENTIALS",
     *   "message": "Invalid email or password"
     * }
     *
     * Authentication Flow:
     * 1. Validate request format (email, password not empty)
     * 2. Call AuthService.login() to verify credentials
     * 3. Generate JWT token containing user claims (userId, email, role)
     * 4. Return token and user information to frontend
     *
     * Frontend Usage:
     * 1. Store token in secure storage (HttpOnly cookie or localStorage)
     * 2. Include token in subsequent requests: "Authorization: Bearer {token}"
     * 3. Token will be validated by JwtAuthenticationFilter
     *
     * Security Considerations:
     * - Password transmitted over HTTPS only
     * - BCrypt verification is intentionally slow (~60-100ms)
     * - Consider implementing rate limiting (e.g., max 5 login attempts per minute)
     * - Log failed login attempts for security monitoring
     *
     * @param request Login credentials (email and password)
     * @return LoginResponse containing JWT token and user information
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        try {
            // Step 1: Validate credentials using AuthService
            User user = authService.login(request.getEmail(), request.getPassword());

            // Step 2: Generate JWT token using JwtTokenProvider
            String token = jwtTokenProvider.generateToken(user);

            // Step 3: Build response with token and user information
            LoginResponse response = LoginResponse.builder()
                .token(token)
                .tokenType("Bearer")
                .userId(user.getId())
                .email(user.getEmail())
                .role(user.getRole().name())
                .build();

            return ResponseEntity.ok(response);

        } catch (BadCredentialsException e) {
            // Invalid email or password
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body("Invalid credentials or user not found.");
        } catch (Exception e) {
            // Unexpected error
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("An error occurred during login.");
        }
    }

    /**
     * User registration endpoint (optional)
     *
     * Creates a new user account with hashed password.
     *
     * Endpoint: POST /api/v1/auth/register
     * Access: Public (no authentication required)
     *
     * Implementation Note:
     * - Uncomment this method if registration is required
     * - Ensure proper validation and error handling
     * - Consider email verification workflow
     * - Implement CAPTCHA to prevent bot registrations
     *
     * @param request Registration details (email, password, etc.)
     * @return Success message or error
     */
    /*
    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest request) {
        try {
            User newUser = User.builder()
                .email(request.getEmail())
                .passwordHash(request.getPassword()) // Will be hashed by AuthService
                .build();

            User createdUser = authService.register(newUser);

            return ResponseEntity.status(HttpStatus.CREATED)
                .body("User registered successfully. User ID: " + createdUser.getId());

        } catch (IllegalStateException e) {
            // Email already exists
            return ResponseEntity.status(HttpStatus.CONFLICT)
                .body("Email already registered.");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("An error occurred during registration.");
        }
    }
    */
}
