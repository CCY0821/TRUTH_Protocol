// ========================================================================
// TRUTH Protocol Backend - User Repository
// ========================================================================
// Package: com.truthprotocol.repository
// Purpose: Spring Data JPA Repository for User entity
// Database: PostgreSQL (users table)
// ========================================================================

package com.truthprotocol.repository;

import com.truthprotocol.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import jakarta.persistence.LockModeType;
import java.util.Optional;
import java.util.UUID;

/**
 * 用戶數據存取層。
 * 繼承 JpaRepository 獲得 CRUD 功能。
 *
 * @implNote 包含悲觀鎖定方法，用於處理高併發下的 Credits 扣除操作。
 */
@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    /**
     * 根據 Email 查找用戶。用於登入和註冊時的唯一性檢查。
     *
     * @param email 用戶 Email 地址
     * @return 包含用戶的 Optional
     */
    Optional<User> findByEmail(String email);

    /**
     * 根據 ID 查找用戶，並立即施加悲觀寫入鎖 (SELECT ... FOR UPDATE)。
     * 這是確保 Credits 扣除操作原子性的關鍵。
     *
     * @param id 用戶 UUID
     * @return 包含用戶的 Optional
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT u FROM User u WHERE u.id = :id")
    Optional<User> findByIdForUpdate(@Param("id") UUID id);
}
