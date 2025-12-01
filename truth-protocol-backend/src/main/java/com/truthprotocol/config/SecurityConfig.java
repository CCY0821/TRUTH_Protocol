// ========================================================================
// TRUTH Protocol Backend - Security Configuration
// ========================================================================
// Package: com.truthprotocol.config
// Purpose: Spring Security 6+ configuration with JWT authentication
// ========================================================================

package com.truthprotocol.config;

import com.truthprotocol.security.JwtAuthenticationFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

/**
 * Security Configuration (Spring Security 6+)
 *
 * Configures JWT-based stateless authentication for TRUTH Protocol API.
 *
 * Key Features:
 * - BCrypt password hashing (cost factor 10)
 * - JWT token authentication (stateless sessions)
 * - CORS support for frontend applications
 * - Public endpoints for login and API documentation
 * - Role-based access control (RBAC) via @PreAuthorize
 * - Custom JWT authentication filter
 *
 * Authentication Flow:
 * 1. User logs in via POST /api/v1/auth/login (public endpoint)
 * 2. Server validates credentials and returns JWT token
 * 3. Frontend includes token in Authorization header: "Bearer {token}"
 * 4. JwtAuthenticationFilter validates token and sets SecurityContext
 * 5. @PreAuthorize annotations enforce role-based access control
 *
 * Security Filter Chain:
 * Request → CORS Filter → JWT Filter → UsernamePasswordAuthFilter → ... → Controller
 *
 * @see JwtAuthenticationFilter
 * @see com.truthprotocol.security.JwtTokenProvider
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    /**
     * Constructor injection for JWT filter
     *
     * @param jwtAuthenticationFilter JWT authentication filter
     */
    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
    }

    // ========================================================================
    // PASSWORD ENCODER BEAN
    // ========================================================================

    /**
     * BCrypt Password Encoder Bean
     *
     * Configuration:
     * - Algorithm: BCrypt
     * - Cost Factor: 10 (2^10 = 1024 rounds)
     * - Salt: Automatically generated per password
     *
     * Security:
     * - Adaptive hashing (configurable cost factor)
     * - Resistant to rainbow table attacks
     * - Industry-standard password hashing algorithm
     *
     * Performance:
     * - Cost factor 10: ~60-100ms per hash operation
     * - Intentionally slow to prevent brute-force attacks
     *
     * Used by:
     * - AuthService.register() for password hashing
     * - AuthService.login() for password verification
     *
     * @return BCryptPasswordEncoder with strength 10
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(10);
    }

    // ========================================================================
    // AUTHENTICATION MANAGER BEAN
    // ========================================================================

    /**
     * Authentication Manager Bean
     *
     * Provides AuthenticationManager for manual authentication (e.g., login).
     *
     * Usage:
     * - Can be injected into AuthService for advanced authentication flows
     * - Not required for basic JWT authentication (handled by JwtAuthenticationFilter)
     *
     * Configuration:
     * - Obtained from AuthenticationConfiguration (Spring Security 6+)
     * - Automatically configured with UserDetailsService and PasswordEncoder
     *
     * @param authenticationConfiguration Spring Security authentication configuration
     * @return AuthenticationManager instance
     * @throws Exception if configuration fails
     */
    @Bean
    public AuthenticationManager authenticationManager(
        AuthenticationConfiguration authenticationConfiguration
    ) throws Exception {
        return authenticationConfiguration.getAuthenticationManager();
    }

    // ========================================================================
    // SECURITY FILTER CHAIN BEAN
    // ========================================================================

    /**
     * Security Filter Chain Configuration
     *
     * Configures HTTP security with JWT authentication and CORS support.
     *
     * Security Policies:
     * - CSRF: Disabled (stateless JWT authentication)
     * - Session: Stateless (no server-side sessions)
     * - CORS: Enabled (configured via corsConfigurationSource())
     *
     * Public Endpoints (permitAll):
     * - POST /api/v1/auth/login - User login
     * - POST /api/v1/auth/register - User registration (optional)
     * - /swagger-ui.html, /swagger-ui/** - Swagger UI
     * - /v3/api-docs/** - OpenAPI documentation
     * - /actuator/health - Health check endpoint
     *
     * Protected Endpoints (authenticated):
     * - All other /api/v1/** endpoints require valid JWT token
     * - Role-based access control via @PreAuthorize annotations
     *
     * JWT Authentication Filter:
     * - Position: Before UsernamePasswordAuthenticationFilter
     * - Responsibilities:
     *   1. Extract JWT token from Authorization header
     *   2. Validate token signature and expiration
     *   3. Extract user claims (userId, email, role)
     *   4. Set Authentication in SecurityContextHolder
     *
     * Filter Chain Order:
     * 1. CORS Filter (built-in)
     * 2. JwtAuthenticationFilter (custom)
     * 3. UsernamePasswordAuthenticationFilter (built-in)
     * 4. ... (other Spring Security filters)
     * 5. Controller
     *
     * @param http HttpSecurity configuration
     * @return SecurityFilterChain
     * @throws Exception if configuration fails
     */
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // Disable CSRF (not needed for stateless JWT authentication)
            .csrf(AbstractHttpConfigurer::disable)

            // Enable CORS with custom configuration
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))

            // Configure authorization rules
            .authorizeHttpRequests(auth -> auth
                // Public endpoints (no authentication required)
                .requestMatchers(
                    "/api/v1/auth/login",
                    "/api/v1/auth/register",
                    "/swagger-ui.html",
                    "/swagger-ui/**",
                    "/v3/api-docs/**",
                    "/actuator/health"
                ).permitAll()

                // All other /api/v1/** endpoints require authentication
                .requestMatchers("/api/v1/**").authenticated()

                // Allow all other requests (optional, can be restricted)
                .anyRequest().permitAll()
            )

            // Stateless session management (no server-side sessions)
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            )

            // Add JWT authentication filter before UsernamePasswordAuthenticationFilter
            // This ensures JWT validation happens before default authentication
            .addFilterBefore(
                jwtAuthenticationFilter,
                UsernamePasswordAuthenticationFilter.class
            );

        return http.build();
    }

    // ========================================================================
    // CORS CONFIGURATION
    // ========================================================================

    /**
     * CORS Configuration Source
     *
     * Configures Cross-Origin Resource Sharing (CORS) for frontend applications.
     *
     * Development Configuration:
     * - Allow all origins (*) for local development
     * - Allow all HTTP methods (GET, POST, PUT, DELETE, etc.)
     * - Allow all headers
     * - Allow credentials (cookies, authorization headers)
     *
     * Production Configuration (TODO):
     * - Restrict allowed origins to specific domains
     * - Example: https://app.truthprotocol.com
     * - Never use "*" in production with allowCredentials(true)
     *
     * Security Warning:
     * - Current configuration allows all origins (development only)
     * - Update for production to restrict to specific domains
     *
     * @return CorsConfigurationSource
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();

        // Allow all origins (development only)
        // TODO: Restrict to specific origins in production
        configuration.setAllowedOriginPatterns(List.of("*"));

        // Allow all HTTP methods
        configuration.setAllowedMethods(Arrays.asList(
            "GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"
        ));

        // Allow all headers
        configuration.setAllowedHeaders(List.of("*"));

        // Allow credentials (cookies, authorization headers)
        configuration.setAllowCredentials(true);

        // Apply CORS configuration to all endpoints
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);

        return source;
    }
}
