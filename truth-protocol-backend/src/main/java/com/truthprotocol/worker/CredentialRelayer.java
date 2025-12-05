package com.truthprotocol.worker;

import com.truthprotocol.entity.Credential;
import com.truthprotocol.entity.CredentialStatus;
import com.truthprotocol.repository.CredentialRepository;
import com.truthprotocol.service.PolygonService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigInteger;
import java.util.List;

/**
 * Credential Relayer Worker
 *
 * Asynchronous worker that processes QUEUED credentials.
 * It orchestrates the interaction between Arweave (storage) and Polygon (blockchain).
 *
 * Flow:
 * 1. Poll for QUEUED credentials
 * 2. Upload metadata to Arweave (if not already done)
 * 3. Mint SBT on Polygon
 * 4. Update credential status to CONFIRMED
 */
@Component
public class CredentialRelayer {

    private final CredentialRepository credentialRepository;
    private final ArweaveService arweaveService;
    private final PolygonService polygonService;

    @Autowired
    public CredentialRelayer(
            CredentialRepository credentialRepository,
            ArweaveService arweaveService,
            PolygonService polygonService) {
        this.credentialRepository = credentialRepository;
        this.arweaveService = arweaveService;
        this.polygonService = polygonService;
    }

    /**
     * Process queued credentials
     * Runs every 5 seconds
     */
    @Scheduled(fixedDelay = 5000)
    public void processQueue() {
        List<Credential> queue = credentialRepository.findByStatus(CredentialStatus.QUEUED);

        if (queue.isEmpty()) {
            return;
        }

        System.out.println("[Relayer] Found " + queue.size() + " queued credentials");

        for (Credential credential : queue) {
            processCredential(credential);
        }
    }

    @Transactional
    public void processCredential(Credential credential) {
        try {
            System.out.println("[Relayer] Processing credential: " + credential.getId());

            // Step 1: Upload to Arweave (if missing)
            if (credential.getArweaveHash() == null) {
                System.out.println("[Relayer] Uploading metadata to Arweave...");
                String arweaveHash = arweaveService.uploadMetadata(credential.getMetadataCache());
                credential.setArweaveHash(arweaveHash);
                // Save intermediate state
                credentialRepository.save(credential);
                System.out.println("[Relayer] Arweave hash: " + arweaveHash);
            }

            // Step 2: Mint on Polygon
            System.out.println("[Relayer] Minting SBT on Polygon...");
            String metadataUri = "ar://" + credential.getArweaveHash();
            BigInteger tokenId = polygonService.mintSBT(
                    credential.getRecipientWalletAddress(),
                    metadataUri
            );
            System.out.println("[Relayer] Token ID: " + tokenId);

            // Step 3: Update Status
            credential.setTokenId(tokenId);
            credential.setStatus(CredentialStatus.CONFIRMED);
            credentialRepository.save(credential);

            System.out.println("[Relayer] Credential " + credential.getId() + " CONFIRMED");

        } catch (Exception e) {
            System.err.println("[Relayer] Failed to process credential " + credential.getId() + ": " + e.getMessage());
            // TODO: Implement retry logic or mark as FAILED after N attempts
            // For now, we leave it as QUEUED to retry next time, or could mark FAILED
            // credential.setStatus(CredentialStatus.FAILED);
            // credentialRepository.save(credential);
        }
    }
}
