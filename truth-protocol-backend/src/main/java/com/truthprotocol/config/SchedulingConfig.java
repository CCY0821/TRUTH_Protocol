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
 * Spring Task Scheduling Configuration
 *
 * Enables Spring's scheduled task execution for background jobs.
 *
 * @EnableScheduling annotation:
 * - Activates Spring's scheduled task infrastructure
 * - Allows @Scheduled annotations to function
 * - Creates a default task scheduler with single thread
 *
 * Scheduled Tasks in TRUTH Protocol:
 * - ConfirmationService.processPendingCredentials()
 *   - Runs every 60 seconds
 *   - Checks PENDING transactions for confirmation
 *   - Extracts tokenId from blockchain events
 *   - Updates credential status to CONFIRMED
 *
 * Thread Pool Configuration (Optional):
 * <pre>
 * spring:
 *   task:
 *     scheduling:
 *       pool:
 *         size: 2  # Number of threads for scheduled tasks
 *       thread-name-prefix: "truth-scheduler-"
 * </pre>
 *
 * Default Behavior:
 * - Single thread executor
 * - Tasks execute sequentially
 * - If task takes longer than interval, next execution waits
 *
 * Concurrent Execution:
 * - To enable parallel execution, configure thread pool size > 1
 * - Each @Scheduled method can run concurrently
 * - Ensure thread-safety in scheduled methods
 *
 * Task Execution Modes:
 *
 * 1. Fixed Rate (@Scheduled(fixedRate = 60000)):
 *    - Executes at fixed intervals (60s)
 *    - Next execution starts N ms after previous start
 *    - Example: Start at 0s, 60s, 120s, 180s...
 *
 * 2. Fixed Delay (@Scheduled(fixedDelay = 60000)):
 *    - Waits N ms after previous execution completes
 *    - Next execution starts N ms after previous end
 *    - Example: Start at 0s, complete at 10s, next at 70s
 *
 * 3. Cron (@Scheduled(cron = "0 */5 * * * *")):
 *    - Executes based on cron expression
 *    - More flexible scheduling (specific times, days, etc.)
 *    - Example: Every 5 minutes, every hour, daily at midnight
 *
 * Performance Monitoring:
 * - Spring Boot Actuator provides metrics for scheduled tasks
 * - Endpoint: /actuator/metrics
 * - Metrics:
 *   - Task execution count
 *   - Task execution time
 *   - Task failures
 *
 * Error Handling:
 * - Exceptions in scheduled methods are logged but don't stop scheduling
 * - Next execution continues as scheduled
 * - Consider implementing custom error handling in @Scheduled methods
 *
 * Testing:
 * - Disable scheduling in tests: @DisableScheduling
 * - Or set spring.task.scheduling.enabled=false
 *
 * @see com.truthprotocol.worker.ConfirmationService
 */
@Configuration
@EnableScheduling
public class SchedulingConfig {
    // This class body can remain empty
    // The @EnableScheduling annotation is sufficient to activate scheduling
}
