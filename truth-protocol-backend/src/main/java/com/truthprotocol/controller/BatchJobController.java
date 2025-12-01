// ========================================================================
// TRUTH Protocol Backend - Batch Job Controller
// ========================================================================
// Package: com.truthprotocol.controller
// Purpose: Admin endpoints for manual batch job triggering
// ========================================================================

package com.truthprotocol.controller;

import org.springframework.batch.core.Job;
import org.springframework.batch.core.JobParameters;
import org.springframework.batch.core.JobParametersBuilder;
import org.springframework.batch.core.launch.JobLauncher;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Batch Job Controller
 *
 * Admin endpoints for manually triggering Spring Batch jobs.
 *
 * Endpoints:
 * - POST /batch/mint - Trigger minting job manually
 *
 * Security:
 * - Requires ADMIN role
 * - Only administrators can trigger batch jobs
 *
 * Use Cases:
 * - Manual job execution for testing
 * - Emergency job trigger when scheduled execution fails
 * - On-demand processing of queued credentials
 *
 * @see com.truthprotocol.config.BatchConfig
 */
@RestController
@RequestMapping("/api/v1/batch")
public class BatchJobController {

    private final JobLauncher jobLauncher;
    private final Job mintingJob;

    /**
     * Constructor injection
     *
     * @param jobLauncher Spring Batch job launcher
     * @param mintingJob Minting batch job
     */
    public BatchJobController(JobLauncher jobLauncher, Job mintingJob) {
        this.jobLauncher = jobLauncher;
        this.mintingJob = mintingJob;
    }

    /**
     * Trigger minting job
     *
     * Manually triggers the credential minting batch job.
     *
     * Endpoint: POST /api/v1/batch/mint
     * Access: ADMIN role only
     *
     * Job Execution:
     * 1. Create unique job parameters (timestamp)
     * 2. Launch minting job
     * 3. Return job execution ID
     *
     * Job Parameters:
     * - timestamp: Current timestamp (makes each run unique)
     *
     * Response:
     * - 200 OK: Job started successfully
     * - 500 Internal Server Error: Job failed to start
     *
     * Example Usage:
     * <pre>
     * curl -X POST http://localhost:8080/api/v1/batch/mint \
     *   -H "Authorization: Bearer {ADMIN_JWT_TOKEN}"
     * </pre>
     *
     * @return Success message with job execution ID
     */
    @PostMapping("/mint")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<?> triggerMintingJob() {
        try {
            // Create unique job parameters
            JobParameters jobParameters = new JobParametersBuilder()
                .addLong("timestamp", System.currentTimeMillis())
                .toJobParameters();

            // Launch job
            jobLauncher.run(mintingJob, jobParameters);

            return ResponseEntity.ok("Minting job triggered successfully");

        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                .body("Failed to trigger minting job: " + e.getMessage());
        }
    }
}
