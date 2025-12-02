// ========================================================================
// TRUTH Protocol Backend - Spring Task Scheduling Configuration
// ========================================================================
// Package: com.truthprotocol.config
// Purpose: Enable Spring's scheduled task execution
// ========================================================================

package com.truthprotocol.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Spring Task Scheduling Configuration.
 *
 * Enables scheduled task execution for background jobs.
 * The main scheduled task is ConfirmationService.processPendingCredentials()
 * which runs every 60 seconds to check PENDING transactions.
 */
@Configuration
@EnableScheduling
public class SchedulingConfig {
    // This class body can remain empty
    // The @EnableScheduling annotation is sufficient to activate scheduling
}
