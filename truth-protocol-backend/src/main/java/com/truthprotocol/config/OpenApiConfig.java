// ========================================================================
// TRUTH Protocol Backend - OpenAPI Configuration
// ========================================================================
// Package: com.truthprotocol.config
// Purpose: Configure Swagger UI with JWT authentication support
// ========================================================================

package com.truthprotocol.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * OpenAPI Configuration for Swagger UI
 *
 * Configures Swagger UI with JWT Bearer token authentication support.
 *
 * Features:
 * - JWT Bearer token authentication scheme
 * - "Authorize" button in Swagger UI
 * - Automatic token inclusion in API requests
 * - API documentation metadata
 *
 * After adding JWT token via "Authorize" button, all API requests
 * will automatically include "Authorization: Bearer {token}" header.
 *
 * @see SecurityConfig
 * @see com.truthprotocol.security.JwtTokenProvider
 */
@Configuration
public class OpenApiConfig {

    /**
     * OpenAPI Bean Configuration
     *
     * Configures OpenAPI 3.0 specification with:
     * - API metadata (title, description, version)
     * - JWT Bearer token security scheme
     * - Global security requirement
     *
     * Security Scheme:
     * - Name: Bearer Authentication
     * - Type: HTTP
     * - Scheme: bearer
     * - Bearer Format: JWT
     *
     * Usage in Swagger UI:
     * 1. Click "Authorize" button (lock icon in top right)
     * 2. Enter JWT token (with or without "Bearer " prefix)
     * 3. Click "Authorize"
     * 4. All subsequent API calls will include the token
     *
     * @return OpenAPI configuration
     */
    @Bean
    public OpenAPI customOpenAPI() {
        // Define JWT security scheme
        final String securitySchemeName = "bearerAuth";

        return new OpenAPI()
            // API Information
            .info(new Info()
                .title("TRUTH Protocol API")
                .description("企业级 Web3 溯源认证平台 API - JWT Authentication")
                .version("1.0.0")
                .contact(new Contact()
                    .name("TRUTH Protocol Team")
                    .email("support@truthprotocol.com"))
                .license(new License()
                    .name("MIT License")
                    .url("https://opensource.org/licenses/MIT")))

            // Add JWT Bearer token security scheme
            .components(new Components()
                .addSecuritySchemes(securitySchemeName,
                    new SecurityScheme()
                        .name(securitySchemeName)
                        .type(SecurityScheme.Type.HTTP)
                        .scheme("bearer")
                        .bearerFormat("JWT")
                        .description("Enter JWT token obtained from /api/v1/auth/login endpoint")))

            // Apply security globally to all endpoints
            .addSecurityItem(new SecurityRequirement().addList(securitySchemeName));
    }
}
