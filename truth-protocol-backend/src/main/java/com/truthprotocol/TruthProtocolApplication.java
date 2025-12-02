// ========================================================================
// TRUTH Protocol Backend - Spring Boot Application Entry Point
// ========================================================================
// Package: com.truthprotocol
// Purpose: Main application class for Spring Boot
// ========================================================================

package com.truthprotocol;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * TRUTH Protocol Backend Application.
 *
 * Main entry point for the Spring Boot application.
 * This class bootstraps the entire Spring context including:
 * - RESTful API controllers
 * - Security configuration (JWT authentication)
 * - Database connection (PostgreSQL with Flyway migrations)
 * - Scheduled tasks (credential confirmation service)
 * - Batch processing (async credential minting)
 *
 * @SpringBootApplication annotation enables:
 * - Component scanning
 * - Auto-configuration
 * - Property binding
 */
@SpringBootApplication
public class TruthProtocolApplication {

    /**
     * Application entry point.
     *
     * @param args Command line arguments
     */
    public static void main(String[] args) {
        SpringApplication.run(TruthProtocolApplication.class, args);
    }
}
