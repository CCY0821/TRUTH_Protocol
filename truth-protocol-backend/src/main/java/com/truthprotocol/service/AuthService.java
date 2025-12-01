// ========================================================================
// TRUTH Protocol Backend - Authentication Service
// ========================================================================
// Package: com.truthprotocol.service
// Purpose: User authentication and registration business logic
// Security: Spring Security BCrypt password hashing
// ========================================================================

package com.truthprotocol.service;

import com.truthprotocol.entity.User;
import com.truthprotocol.entity.UserRole;
import com.truthprotocol.repository.UserRepository;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

/**
 * 用戶認證與授權服務 (BE-05)。
 * 處理用戶登入、註冊和密碼管理。
 */
@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    // 依賴注入 (Constructor Injection)
    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    /**
     * 執行用戶登入驗證。
     *
     * @param email 用戶 Email
     * @param rawPassword 用戶輸入的原始密碼
     * @return 成功登入的用戶 User 物件
     * @throws BadCredentialsException 認證失敗 (密碼錯誤或用戶不存在)
     */
    @Transactional(readOnly = true)
    public User login(String email, String rawPassword) {
        Optional<User> userOpt = userRepository.findByEmail(email);

        // 安全實踐：無論用戶是否存在，都使用相同的錯誤類型，避免洩漏用戶資訊
        if (userOpt.isEmpty()) {
            throw new BadCredentialsException("Invalid credentials or user not found.");
        }

        User user = userOpt.get();

        // 使用 BCrypt 比對密碼 (Constant-time comparison)
        if (!passwordEncoder.matches(rawPassword, user.getPasswordHash())) {
            throw new BadCredentialsException("Invalid credentials or user not found.");
        }

        // 登入成功，可更新 lastLoginAt
        // user.setLastLoginAt(Instant.now());
        // userRepository.save(user);

        return user;
    }

    /**
     * 註冊新用戶。
     *
     * @param newUser 待註冊的用戶 Entity (包含原始密碼)
     * @return 成功註冊的用戶 User 物件
     * @throws IllegalStateException 如果 Email 已存在
     */
    @Transactional
    public User register(User newUser) {
        if (userRepository.findByEmail(newUser.getEmail()).isPresent()) {
            throw new IllegalStateException("Email already registered: " + newUser.getEmail());
        }

        // 1. 對原始密碼進行 BCrypt Hash
        String encodedPassword = passwordEncoder.encode(newUser.getPasswordHash());
        newUser.setPasswordHash(encodedPassword);

        // 2. 設置預設值 (角色、KYC 狀態)
        // 註: @Builder 在 Entity 中已設定預設值，此處可選擇性覆寫
        if (newUser.getRole() == null) {
            newUser.setRole(UserRole.ISSUER);
        }

        // 3. 儲存用戶
        return userRepository.save(newUser);
    }
}
