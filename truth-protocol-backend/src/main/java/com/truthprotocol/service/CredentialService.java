// ========================================================================
// TRUTH Protocol Backend - Credential Service
// ========================================================================
// Package: com.truthprotocol.service
// Purpose: Core business logic for SBT credential issuance and credit management
// Transactions: Pessimistic locking for credit deduction (prevents race conditions)
// ========================================================================

package com.truthprotocol.service;

import com.truthprotocol.entity.Credential;
import com.truthprotocol.entity.CredentialStatus;
import com.truthprotocol.entity.User;
import com.truthprotocol.dto.MintRequest;
import com.truthprotocol.exception.InsufficientCreditsException;
import com.truthprotocol.repository.CredentialRepository;
import com.truthprotocol.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * 憑證鑄造服務 (Minting Service)。
 * 負責處理鑄造請求、點數扣除和任務排程。
 */
@Service
public class CredentialService {

    private final CredentialRepository credentialRepository;
    private final UserRepository userRepository;

    public CredentialService(CredentialRepository credentialRepository, UserRepository userRepository) {
        this.credentialRepository = credentialRepository;
        this.userRepository = userRepository;
    }

    /**
     * 【CRITICAL】檢查用戶點數，並以原子操作扣除點數。
     * 必須在事務中執行，並使用悲觀鎖防止併發扣點問題。
     *
     * @param userId 發行者 ID
     * @param requiredCredits 鑄造所需點數
     * @return 更新後的 User 物件
     * @throws InsufficientCreditsException 如果點數不足
     * @throws IllegalStateException 如果用戶不存在
     */
    @Transactional
    public User checkAndDeductCredits(UUID userId, BigDecimal requiredCredits) {
        // 1. 使用悲觀鎖鎖定用戶記錄，直到事務完成
        User user = userRepository.findByIdForUpdate(userId)
                .orElseThrow(() -> new IllegalStateException("User not found: " + userId));

        // 2. 檢查點數是否足夠
        if (user.getCredits().compareTo(requiredCredits) < 0) {
            // 拋出業務異常，對應 OpenAPI 規格中的 MINT_INSUFFICIENT_CREDITS (BE-02)
            throw new InsufficientCreditsException(
                "Insufficient credits. Current: " + user.getCredits() + ", Required: " + requiredCredits
            );
        }

        // 3. 扣除點數
        BigDecimal newCredits = user.getCredits().subtract(requiredCredits);
        user.setCredits(newCredits);

        // 4. 儲存用戶 (在事務結束時自動提交)
        return userRepository.save(user);
    }

    /**
     * 建立新的憑證記錄，並將其狀態設置為 QUEUED，準備交由 Relayer Worker 異步處理。
     *
     * @param issuerId 發行者 ID
     * @param request 鑄造請求 DTO (包含 recipient_wallet_address, metadata, issuer_ref_id)
     * @return 新創建的 Credential Entity
     */
    @Transactional
    public Credential queueMintingJob(UUID issuerId, MintRequest request) {
        // 註: 假定 issuer 在此之前已被驗證且點數已扣除
        
        // ⚠️ 重要修正：Credential Entity 使用 issuer (User object)，而非 issuerId (UUID)
        // 必須先從資料庫查詢 User 物件
        User issuer = userRepository.findById(issuerId)
                .orElseThrow(() -> new IllegalStateException("Issuer not found: " + issuerId));
        
        Credential credential = Credential.builder()
                .issuer(issuer)  // ✅ 正確：使用 User object
                // 註: 這裡需要從 DTO 映射到 Entity 欄位
                .recipientWalletAddress(request.getRecipientWalletAddress())
                .issuerRefId(request.getIssuerRefId())
                .metadataCache(request.getMetadata()) // 假定 DTO 包含 JsonNode metadata
                .status(CredentialStatus.QUEUED)
                // token_id, tx_hash, arweave_hash 保持為 NULL
                .build();
        
        // 儲存 Credential Entity (觸發 QUEUED 狀態的記錄)
        Credential savedCredential = credentialRepository.save(credential);

        // TODO: 觸發異步任務 (如 Spring Batch Job 或 RabbitMQ 消息)
        // messageQueue.send(new MintingTask(savedCredential.getId()));

        return savedCredential;
    }
}
