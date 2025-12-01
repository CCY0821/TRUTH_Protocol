// ========================================================================
// TRUTH Protocol Backend - JWT Authentication Filter
// ========================================================================
// Package: com.truthprotocol.security
// Purpose: Spring Security filter for JWT token validation on each request
// ========================================================================

package com.truthprotocol.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

/**
 * JWT Authentication Filter
 *
 * Spring Security filter that validates JWT tokens on every HTTP request.
 *
 * Filter Lifecycle:
 * 1. Extract JWT token from Authorization header
 * 2. Validate token signature and expiration
 * 3. Extract user claims and authorities
 * 4. Set Authentication in SecurityContextHolder
 * 5. Continue filter chain
 *
 * Filter Position:
 * - Positioned BEFORE UsernamePasswordAuthenticationFilter
 * - Configured in SecurityConfig.securityFilterChain()
 * - Executes on every request (OncePerRequestFilter guarantees single execution)
 *
 * Public Endpoints (Skipped):
 * - /api/v1/auth/login - Login endpoint
 * - /api/v1/auth/register - Registration endpoint
 * - /swagger-ui/** - Swagger UI
 * - /v3/api-docs/** - OpenAPI documentation
 * - /actuator/health - Health check
 *
 * Protected Endpoints (Validated):
 * - All other /api/v1/** endpoints require valid JWT token
 *
 * Error Handling:
 * - Invalid/expired tokens: No authentication set → 401 Unauthorized (handled by Spring Security)
 * - Missing token: No authentication set → 401 Unauthorized
 * - Malformed header: Logged and ignored
 *
 * Security Context:
 * - Authentication set in SecurityContextHolder is thread-local
 * - Cleared after request completion
 * - Accessible in controllers via SecurityContextHolder.getContext().getAuthentication()
 *
 * @see JwtTokenProvider
 * @see com.truthprotocol.config.SecurityConfig
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;

    /**
     * Public endpoints that do not require JWT authentication
     *
     * These paths will bypass JWT validation and allow anonymous access.
     * Must match the permitAll() configuration in SecurityConfig.
     */
    private static final List<String> PUBLIC_PATHS = Arrays.asList(
        "/api/v1/auth/login",
        "/api/v1/auth/register",
        "/swagger-ui",
        "/v3/api-docs",
        "/actuator/health"
    );

    /**
     * Constructor injection
     *
     * @param jwtTokenProvider JWT token validation and parsing service
     */
    public JwtAuthenticationFilter(JwtTokenProvider jwtTokenProvider) {
        this.jwtTokenProvider = jwtTokenProvider;
    }

    // ========================================================================
    // FILTER IMPLEMENTATION
    // ========================================================================

    /**
     * Filter internal implementation
     *
     * Executes on every HTTP request to validate JWT token and set authentication.
     *
     * Process Flow:
     * 1. Check if request path is public (skip JWT validation)
     * 2. Extract JWT token from Authorization header
     * 3. Validate token signature and expiration
     * 4. Extract user claims and build Authentication object
     * 5. Set Authentication in SecurityContextHolder
     * 6. Continue filter chain
     *
     * Authentication Flow:
     * <pre>
     * Request with Token
     *     ↓
     * Extract Token from "Authorization: Bearer {token}"
     *     ↓
     * Validate Token (signature, expiration)
     *     ↓
     * Valid? → Extract Claims → Set SecurityContext → Continue
     * Invalid? → Continue without authentication → 401 Unauthorized
     * </pre>
     *
     * Security Context Lifecycle:
     * 1. Set in this filter (thread-local)
     * 2. Used by Spring Security for authorization (@PreAuthorize, etc.)
     * 3. Cleared by Spring Security after request completion
     *
     * Example Scenarios:
     *
     * Scenario 1: Valid Token
     * - Request: GET /api/v1/credentials/mint
     * - Header: Authorization: Bearer eyJhbGc...
     * - Result: Authentication set → @PreAuthorize check passes → Endpoint executes
     *
     * Scenario 2: Expired Token
     * - Request: GET /api/v1/credentials/mint
     * - Header: Authorization: Bearer expired_token
     * - Result: Validation fails → No authentication set → 401 Unauthorized
     *
     * Scenario 3: Missing Token
     * - Request: GET /api/v1/credentials/mint
     * - Header: (no Authorization header)
     * - Result: No token extracted → No authentication set → 401 Unauthorized
     *
     * Scenario 4: Public Endpoint
     * - Request: POST /api/v1/auth/login
     * - Header: (no Authorization header)
     * - Result: Skipped (public path) → Allowed → Endpoint executes
     *
     * @param request HTTP request
     * @param response HTTP response
     * @param filterChain Spring Security filter chain
     * @throws ServletException if servlet error occurs
     * @throws IOException if I/O error occurs
     */
    @Override
    protected void doFilterInternal(
        HttpServletRequest request,
        HttpServletResponse response,
        FilterChain filterChain
    ) throws ServletException, IOException {

        try {
            // Step 1: Check if request path is public (skip JWT validation)
            String requestPath = request.getRequestURI();
            if (isPublicPath(requestPath)) {
                // Skip JWT validation for public endpoints
                filterChain.doFilter(request, response);
                return;
            }

            // Step 2: Extract JWT token from Authorization header
            String jwt = extractTokenFromRequest(request);

            // Step 3: Validate token and set authentication if valid
            if (jwt != null && jwtTokenProvider.validateToken(jwt)) {
                // Step 4: Extract user claims and build Authentication object
                Authentication authentication = jwtTokenProvider.getAuthentication(jwt);

                // Step 5: Set Authentication in SecurityContextHolder
                // This makes the user details available to Spring Security
                // and can be accessed in controllers
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }

            // Step 6: Continue filter chain
            // If token is invalid or missing, SecurityContext remains empty
            // Spring Security will return 401 Unauthorized for protected endpoints
            filterChain.doFilter(request, response);

        } catch (Exception e) {
            // Log exception but continue filter chain
            // Spring Security will handle authentication failure
            System.err.println("JWT Authentication Error: " + e.getMessage());
            filterChain.doFilter(request, response);
        }
    }

    // ========================================================================
    // HELPER METHODS
    // ========================================================================

    /**
     * Extract JWT token from HTTP request
     *
     * Extracts token from Authorization header with Bearer scheme.
     *
     * Expected Header Format:
     * Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
     *
     * Extraction Process:
     * 1. Get Authorization header value
     * 2. Check if header starts with "Bearer "
     * 3. Extract token substring after "Bearer "
     *
     * Return Values:
     * - Token string if valid Bearer token present
     * - null if header is missing, empty, or not Bearer scheme
     *
     * Example:
     * <pre>
     * {@code
     * // Valid header
     * Authorization: Bearer eyJhbGc...
     * → Returns: "eyJhbGc..."
     *
     * // Invalid headers
     * Authorization: Basic abc123
     * → Returns: null
     *
     * (no Authorization header)
     * → Returns: null
     * }
     * </pre>
     *
     * @param request HTTP request
     * @return JWT token string or null
     */
    private String extractTokenFromRequest(HttpServletRequest request) {
        // Get Authorization header
        String bearerToken = request.getHeader("Authorization");

        // Check if header starts with "Bearer "
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            // Extract token (remove "Bearer " prefix)
            return bearerToken.substring(7);
        }

        return null;
    }

    /**
     * Check if request path is public (no authentication required)
     *
     * Compares request path against list of public endpoints.
     *
     * Matching Logic:
     * - Exact match: /api/v1/auth/login
     * - Prefix match: /swagger-ui/** matches /swagger-ui/index.html
     *
     * @param requestPath Request URI path
     * @return true if path is public, false otherwise
     */
    private boolean isPublicPath(String requestPath) {
        // Check if request path starts with any public path
        return PUBLIC_PATHS.stream()
            .anyMatch(requestPath::startsWith);
    }
}
