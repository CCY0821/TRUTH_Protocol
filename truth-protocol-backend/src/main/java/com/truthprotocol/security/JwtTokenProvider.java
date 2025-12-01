// ========================================================================
// TRUTH Protocol Backend - JWT Token Provider
// ========================================================================
// Package: com.truthprotocol.security
// Purpose: JWT token generation, validation, and authentication extraction
// ========================================================================

package com.truthprotocol.security;

import com.truthprotocol.entity.User;
import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.*;

/**
 * JWT Token Provider
 *
 * Manages the complete lifecycle of JWT tokens for TRUTH Protocol authentication.
 *
 * Responsibilities:
 * - Generate JWT tokens on successful login
 * - Validate JWT tokens on each authenticated request
 * - Extract user claims and authorities from tokens
 * - Build Spring Security Authentication objects
 *
 * Token Structure:
 * Header:
 *   - alg: HS256 (HMAC with SHA-256)
 *   - typ: JWT
 *
 * Payload (Claims):
 *   - sub: User ID (UUID as string)
 *   - email: User email address
 *   - role: User role (ISSUER, VERIFIER, ADMIN)
 *   - iat: Issued at timestamp
 *   - exp: Expiration timestamp
 *
 * Signature:
 *   - HMACSHA256(base64UrlEncode(header) + "." + base64UrlEncode(payload), secret)
 *
 * Configuration:
 * - Secret key: Loaded from application.yml (app.security.jwt.secret)
 * - Expiration: Loaded from application.yml (app.security.jwt.expiration)
 *
 * Security:
 * - Secret key is Base64 encoded in configuration
 * - Minimum key length: 256 bits (32 bytes) for HS256
 * - Tokens are stateless (no server-side session storage)
 * - Expiration enforced on every validation
 *
 * @see JwtAuthenticationFilter
 * @see com.truthprotocol.config.SecurityConfig
 */
@Component
public class JwtTokenProvider {

    // ========================================================================
    // CONFIGURATION PROPERTIES
    // ========================================================================

    /**
     * JWT Secret Key (Base64 encoded)
     *
     * Configuration:
     * - Loaded from application.yml: app.security.jwt.secret
     * - Environment variable: JWT_SECRET (recommended for production)
     * - Minimum length: 256 bits (32 bytes) for HS256 algorithm
     *
     * Example generation (Linux/Mac):
     * openssl rand -base64 32
     *
     * Security:
     * - NEVER commit actual secret to version control
     * - Use environment variables or external secrets management
     * - Rotate secret periodically in production
     */
    @Value("${app.security.jwt.secret}")
    private String jwtSecret;

    /**
     * JWT Token Expiration Time (in milliseconds)
     *
     * Configuration:
     * - Loaded from application.yml: app.security.jwt.expiration
     * - Default: 86400000 ms = 24 hours
     *
     * Recommendations:
     * - Short-lived tokens (1-24 hours) for security
     * - Implement refresh tokens for longer sessions (future enhancement)
     */
    @Value("${app.security.jwt.expiration}")
    private long jwtExpirationMs;

    /**
     * Parsed Secret Key (used for signing and verification)
     *
     * Initialized in @PostConstruct from Base64 encoded jwtSecret.
     */
    private Key secretKey;

    // ========================================================================
    // INITIALIZATION
    // ========================================================================

    /**
     * Initialize JWT Secret Key
     *
     * Converts Base64 encoded secret string to Key object for HMAC-SHA256.
     *
     * Lifecycle:
     * - Called after dependency injection (@PostConstruct)
     * - Executes before any other methods
     *
     * Security:
     * - Decodes Base64 secret to raw bytes
     * - Creates Key compatible with HS256 algorithm
     */
    @PostConstruct
    public void init() {
        // Decode Base64 secret and create HMAC-SHA256 key
        byte[] keyBytes = Base64.getDecoder().decode(jwtSecret);
        this.secretKey = Keys.hmacShaKeyFor(keyBytes);
    }

    // ========================================================================
    // TOKEN GENERATION
    // ========================================================================

    /**
     * Generate JWT Token for authenticated user
     *
     * Called after successful login to create access token.
     *
     * Token Claims:
     * - sub (subject): User ID (UUID as string)
     * - email: User email address
     * - role: User role (ISSUER, VERIFIER, ADMIN)
     * - iat (issued at): Current timestamp
     * - exp (expiration): Current timestamp + expiration time
     *
     * Example Token:
     * eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI1NTBlODQwMC1lMjliLTQxZDQtYTcxNi00NDY2NTU0NDAwMDAi
     * LCJlbWFpbCI6Imlzc3VlckBleGFtcGxlLmNvbSIsInJvbGUiOiJJU1NVRVIiLCJpYXQiOjE3MDE0MjQwMDAs
     * ImV4cCI6MTcwMTUxMDQwMH0.signature
     *
     * Decoded Payload:
     * {
     *   "sub": "550e8400-e29b-41d4-a716-446655440000",
     *   "email": "issuer@example.com",
     *   "role": "ISSUER",
     *   "iat": 1701424000,
     *   "exp": 1701510400
     * }
     *
     * Usage:
     * <pre>
     * {@code
     * User user = authService.login(email, password);
     * String token = jwtTokenProvider.generateToken(user);
     * // Return token to frontend
     * }
     * </pre>
     *
     * @param user Authenticated user entity
     * @return JWT token string
     */
    public String generateToken(User user) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + jwtExpirationMs);

        // Build JWT with claims
        return Jwts.builder()
            .setSubject(user.getId().toString())                    // User ID (UUID)
            .claim("email", user.getEmail())                        // User email
            .claim("role", user.getRole().name())                   // User role
            .setIssuedAt(now)                                       // Issued timestamp
            .setExpiration(expiryDate)                              // Expiration timestamp
            .signWith(secretKey, SignatureAlgorithm.HS256)          // Sign with HMAC-SHA256
            .compact();
    }

    // ========================================================================
    // TOKEN VALIDATION
    // ========================================================================

    /**
     * Validate JWT Token
     *
     * Checks token signature, expiration, and format.
     *
     * Validation Steps:
     * 1. Parse token and verify signature using secret key
     * 2. Check if token is expired
     * 3. Validate token structure and claims
     *
     * Return Values:
     * - true: Token is valid and not expired
     * - false: Token is invalid, expired, or malformed
     *
     * Exception Handling:
     * - MalformedJwtException: Token structure is invalid
     * - ExpiredJwtException: Token has expired
     * - UnsupportedJwtException: Token algorithm not supported
     * - IllegalArgumentException: Token is null or empty
     * - SignatureException: Token signature verification failed
     *
     * Security:
     * - All exceptions are caught and logged
     * - Returns false for any validation failure (fail-safe)
     * - Never exposes internal error details to client
     *
     * Usage:
     * <pre>
     * {@code
     * if (jwtTokenProvider.validateToken(token)) {
     *     Authentication auth = jwtTokenProvider.getAuthentication(token);
     *     // Set authentication in SecurityContext
     * }
     * }
     * </pre>
     *
     * @param token JWT token string
     * @return true if token is valid, false otherwise
     */
    public boolean validateToken(String token) {
        try {
            // Parse and validate token
            Jwts.parserBuilder()
                .setSigningKey(secretKey)
                .build()
                .parseClaimsJws(token);
            
            return true;

        } catch (MalformedJwtException e) {
            // Token structure is invalid
            System.err.println("Invalid JWT token: " + e.getMessage());
        } catch (ExpiredJwtException e) {
            // Token has expired
            System.err.println("Expired JWT token: " + e.getMessage());
        } catch (UnsupportedJwtException e) {
            // Token algorithm not supported
            System.err.println("Unsupported JWT token: " + e.getMessage());
        } catch (IllegalArgumentException e) {
            // Token is null or empty
            System.err.println("JWT claims string is empty: " + e.getMessage());
        } catch (io.jsonwebtoken.security.SignatureException e) {
            // Token signature verification failed
            System.err.println("Invalid JWT signature: " + e.getMessage());
        }

        return false;
    }

    // ========================================================================
    // AUTHENTICATION EXTRACTION
    // ========================================================================

    /**
     * Extract Authentication from JWT Token
     *
     * Parses token claims and builds Spring Security Authentication object.
     *
     * Process:
     * 1. Parse JWT token to extract claims (subject, email, role)
     * 2. Extract user ID from "sub" claim
     * 3. Extract role and build GrantedAuthority list
     * 4. Create UsernamePasswordAuthenticationToken with user details and authorities
     *
     * Authentication Object:
     * - Principal: User ID (UUID string)
     * - Credentials: null (no password stored in token)
     * - Authorities: List of SimpleGrantedAuthority from role claim
     * - Authenticated: true
     *
     * Role Mapping:
     * - Token claim "role": "ISSUER" → Authority: "ISSUER"
     * - Used by @PreAuthorize("hasAuthority('ISSUER')") annotations
     *
     * Security Context:
     * - This Authentication object will be set in SecurityContextHolder
     * - Accessible in controllers via SecurityContextHolder.getContext().getAuthentication()
     * - Used for authorization checks (@PreAuthorize, @Secured, etc.)
     *
     * Example Usage:
     * <pre>
     * {@code
     * // In JwtAuthenticationFilter
     * if (jwtTokenProvider.validateToken(token)) {
     *     Authentication auth = jwtTokenProvider.getAuthentication(token);
     *     SecurityContextHolder.getContext().setAuthentication(auth);
     * }
     *
     * // In Controller
     * @GetMapping("/me")
     * public ResponseEntity<?> getCurrentUser() {
     *     Authentication auth = SecurityContextHolder.getContext().getAuthentication();
     *     String userId = (String) auth.getPrincipal();  // UUID string
     *     Collection<? extends GrantedAuthority> authorities = auth.getAuthorities();
     *     // ...
     * }
     * }
     * </pre>
     *
     * @param token JWT token string (must be valid)
     * @return Spring Security Authentication object
     */
    public Authentication getAuthentication(String token) {
        // Parse token to extract claims
        Claims claims = Jwts.parserBuilder()
            .setSigningKey(secretKey)
            .build()
            .parseClaimsJws(token)
            .getBody();

        // Extract user details from claims
        String userId = claims.getSubject();                    // User ID (UUID)
        String email = claims.get("email", String.class);       // User email
        String role = claims.get("role", String.class);         // User role

        // Build authorities list from role claim
        List<GrantedAuthority> authorities = new ArrayList<>();
        if (role != null) {
            authorities.add(new SimpleGrantedAuthority(role));
        }

        // Create Authentication object
        // - Principal: User ID (UUID string)
        // - Credentials: null (no password in token)
        // - Authorities: List of roles
        return new UsernamePasswordAuthenticationToken(userId, null, authorities);
    }

    // ========================================================================
    // UTILITY METHODS
    // ========================================================================

    /**
     * Extract User ID from JWT Token
     *
     * Convenience method to get user ID without building full Authentication object.
     *
     * @param token JWT token string
     * @return User ID (UUID string)
     */
    public String getUserIdFromToken(String token) {
        Claims claims = Jwts.parserBuilder()
            .setSigningKey(secretKey)
            .build()
            .parseClaimsJws(token)
            .getBody();

        return claims.getSubject();
    }

    /**
     * Extract User Email from JWT Token
     *
     * Convenience method to get user email from token.
     *
     * @param token JWT token string
     * @return User email address
     */
    public String getEmailFromToken(String token) {
        Claims claims = Jwts.parserBuilder()
            .setSigningKey(secretKey)
            .build()
            .parseClaimsJws(token)
            .getBody();

        return claims.get("email", String.class);
    }
}
