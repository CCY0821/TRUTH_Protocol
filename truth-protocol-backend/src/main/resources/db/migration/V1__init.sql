-- ========================================================================
-- TRUTH Protocol - Database Schema Initialization
-- ========================================================================
-- Flyway Migration: V1__init.sql
-- Description: Initial schema creation for TRUTH Protocol backend
-- Author: TRUTH Protocol DevOps Team
-- Date: 2025-01-15
-- Database: PostgreSQL 15+
-- ========================================================================
-- Tables:
--   1. users - User accounts (Issuer, Verifier, Admin)
--   2. credentials - SBT credentials (on-chain & metadata)
-- ========================================================================

-- ========================================================================
-- EXTENSIONS
-- ========================================================================

-- Enable UUID generation (required for primary keys)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pgcrypto for password hashing (optional, if not using bcrypt externally)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ========================================================================
-- TABLE: users
-- ========================================================================
-- Purpose: Store user accounts with authentication & KYC information
-- Business Logic:
--   - ISSUER: Organizations that mint credentials (requires KYC)
--   - VERIFIER: End-users who verify credentials
--   - ADMIN: Platform administrators
-- Compliance:
--   - data_retention_date: GDPR/privacy law compliance (auto-delete after retention period)
-- ========================================================================

CREATE TABLE users (
    -- ----------------------------------------------------------------
    -- Primary Key & Identity
    -- ----------------------------------------------------------------
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- ----------------------------------------------------------------
    -- Authentication & Authorization
    -- ----------------------------------------------------------------
    email VARCHAR(100) NOT NULL,
    password_hash VARCHAR(60) NOT NULL,  -- bcrypt hash (always 60 chars)

    role VARCHAR(20) NOT NULL DEFAULT 'ISSUER',

    -- ----------------------------------------------------------------
    -- KYC & Compliance
    -- ----------------------------------------------------------------
    kyc_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',

    -- GDPR/Privacy Law Compliance: Auto-deletion date for personal data
    -- After this date, user's personal information should be anonymized/deleted
    data_retention_date TIMESTAMP WITH TIME ZONE,

    -- ----------------------------------------------------------------
    -- Business Logic (Credits System)
    -- ----------------------------------------------------------------
    -- Using NUMERIC to avoid floating-point precision issues
    -- Precision: 10 digits total, 2 decimal places (e.g., 99999999.99)
    credits NUMERIC(10, 2) NOT NULL DEFAULT 0.00,

    -- ----------------------------------------------------------------
    -- Metadata & Timestamps
    -- ----------------------------------------------------------------
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,

    -- ----------------------------------------------------------------
    -- Constraints
    -- ----------------------------------------------------------------
    CONSTRAINT users_email_unique UNIQUE (email),

    CONSTRAINT users_role_check CHECK (
        role IN ('ISSUER', 'VERIFIER', 'ADMIN')
    ),

    CONSTRAINT users_kyc_status_check CHECK (
        kyc_status IN ('PENDING', 'APPROVED', 'REJECTED')
    ),

    CONSTRAINT users_credits_non_negative CHECK (
        credits >= 0
    )
);

-- ----------------------------------------------------------------
-- Indexes for users table
-- ----------------------------------------------------------------

-- Unique index on email (enforced by UNIQUE constraint, but explicit for clarity)
CREATE UNIQUE INDEX idx_users_email ON users(email);

-- Index for querying users by role (e.g., find all ISSUERS)
CREATE INDEX idx_users_role ON users(role);

-- Index for querying users by KYC status (e.g., find pending KYC reviews)
CREATE INDEX idx_users_kyc_status ON users(kyc_status);

-- Index for data retention compliance queries
-- Find users whose data should be deleted (data_retention_date < NOW())
CREATE INDEX idx_users_data_retention ON users(data_retention_date)
    WHERE data_retention_date IS NOT NULL;

-- ----------------------------------------------------------------
-- Comments for users table
-- ----------------------------------------------------------------

COMMENT ON TABLE users IS 'User accounts with authentication, KYC, and credits management';
COMMENT ON COLUMN users.id IS 'Unique user identifier (UUID v4)';
COMMENT ON COLUMN users.email IS 'User email address (used for login, must be unique)';
COMMENT ON COLUMN users.password_hash IS 'bcrypt password hash (60 characters)';
COMMENT ON COLUMN users.role IS 'User role: ISSUER (B2B), VERIFIER (C2C), or ADMIN';
COMMENT ON COLUMN users.kyc_status IS 'KYC verification status (required for ISSUER role)';
COMMENT ON COLUMN users.data_retention_date IS 'GDPR compliance: Date after which personal data should be deleted';
COMMENT ON COLUMN users.credits IS 'Remaining credits for minting (ISSUER only), using NUMERIC for precision';
COMMENT ON COLUMN users.created_at IS 'Account creation timestamp';
COMMENT ON COLUMN users.updated_at IS 'Last account update timestamp';
COMMENT ON COLUMN users.last_login_at IS 'Last successful login timestamp';

-- ========================================================================
-- TABLE: credentials
-- ========================================================================
-- Purpose: Store SBT credentials with on-chain and off-chain metadata
-- Business Logic:
--   - QUEUED: Request accepted, waiting for Relayer Worker
--   - PENDING: Transaction submitted to blockchain
--   - CONFIRMED: Successfully minted on-chain
--   - FAILED: Minting failed (credits refunded)
--   - REVOKED: Credential revoked by issuer
-- Performance:
--   - metadata_cache: JSONB for fast querying without reading Arweave
--   - GIN index on metadata_cache for product/batch queries
-- ========================================================================

CREATE TABLE credentials (
    -- ----------------------------------------------------------------
    -- Primary Key & Foreign Keys
    -- ----------------------------------------------------------------
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Foreign key to users table (who issued this credential)
    issuer_id UUID NOT NULL,

    -- ----------------------------------------------------------------
    -- On-Chain Information
    -- ----------------------------------------------------------------
    -- EVM wallet address (Ethereum/Polygon format: 0x + 40 hex chars)
    recipient_wallet_address VARCHAR(42) NOT NULL,

    -- ERC-721 token ID (uint256 on-chain, can be very large)
    -- Using NUMERIC(78, 0) to store uint256 (max 2^256-1, ~78 decimal digits)
    -- NULL until minted on-chain
    token_id NUMERIC(78, 0),

    -- Blockchain transaction hash (0x + 64 hex chars)
    -- NULL until transaction is submitted
    tx_hash VARCHAR(66),

    -- ----------------------------------------------------------------
    -- Off-Chain Metadata
    -- ----------------------------------------------------------------
    -- Arweave permanent storage hash
    -- NULL until metadata is uploaded
    arweave_hash VARCHAR(100),

    -- Local cache of metadata (JSONB for fast querying)
    -- Stores the same data as Arweave, but queryable via SQL
    -- Example structure:
    -- {
    --   "title": "Certificate Title",
    --   "description": "...",
    --   "product_sku": "PROD-123",
    --   "batch_no": "BATCH-001",
    --   "attributes": [...]
    -- }
    metadata_cache JSONB,

    -- ----------------------------------------------------------------
    -- Business Logic & Status
    -- ----------------------------------------------------------------
    -- Issuer's internal reference ID (for tracking/reconciliation)
    issuer_ref_id VARCHAR(100),

    -- Credential lifecycle status
    status VARCHAR(20) NOT NULL DEFAULT 'QUEUED',

    -- ----------------------------------------------------------------
    -- Timestamps
    -- ----------------------------------------------------------------
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- When the credential was confirmed on-chain
    confirmed_at TIMESTAMP WITH TIME ZONE,

    -- ----------------------------------------------------------------
    -- Constraints
    -- ----------------------------------------------------------------
    CONSTRAINT credentials_issuer_fk
        FOREIGN KEY (issuer_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,  -- Prevent deleting users with credentials

    CONSTRAINT credentials_status_check CHECK (
        status IN ('QUEUED', 'PENDING', 'CONFIRMED', 'FAILED', 'REVOKED')
    ),

    -- Ensure wallet address matches EVM format (0x + 40 hex chars)
    CONSTRAINT credentials_wallet_format_check CHECK (
        recipient_wallet_address ~ '^0x[a-fA-F0-9]{40}$'
    ),

    -- Ensure tx_hash matches blockchain format (0x + 64 hex chars) if present
    CONSTRAINT credentials_tx_hash_format_check CHECK (
        tx_hash IS NULL OR tx_hash ~ '^0x[a-fA-F0-9]{64}$'
    ),

    -- Ensure token_id is non-negative if present
    CONSTRAINT credentials_token_id_check CHECK (
        token_id IS NULL OR token_id >= 0
    )
);

-- ----------------------------------------------------------------
-- Indexes for credentials table
-- ----------------------------------------------------------------

-- Index for querying credentials by issuer
-- Most common query: "Get all credentials issued by user X"
CREATE INDEX idx_credentials_issuer_id ON credentials(issuer_id, created_at DESC);

-- Partial unique index on token_id for CONFIRMED credentials only
-- Ensures no duplicate token IDs for minted credentials
-- Partial index is more efficient than full index (only indexes CONFIRMED rows)
CREATE UNIQUE INDEX idx_credentials_token_id ON credentials(token_id)
    WHERE status = 'CONFIRMED';

-- Index for querying credentials by status
-- Used by Relayer Worker to fetch QUEUED/PENDING credentials
CREATE INDEX idx_credentials_status ON credentials(status, created_at);

-- Index for querying by recipient wallet
-- Used by Verifier to fetch credentials for a specific wallet
CREATE INDEX idx_credentials_recipient_wallet ON credentials(recipient_wallet_address);

-- Index for querying by issuer reference ID
-- Used by issuers to track their internal orders
CREATE INDEX idx_credentials_issuer_ref_id ON credentials(issuer_ref_id)
    WHERE issuer_ref_id IS NOT NULL;

-- ----------------------------------------------------------------
-- GIN Index on JSONB metadata_cache (Performance Optimization)
-- ----------------------------------------------------------------

-- GIN index on the entire JSONB column (supports all JSONB operators)
-- Enables fast queries like: WHERE metadata_cache @> '{"product_sku": "PROD-123"}'
CREATE INDEX idx_credentials_metadata_cache_gin ON credentials USING GIN (metadata_cache);

-- Specialized GIN index on specific JSONB attribute: batch_no
-- Optimizes queries like: WHERE metadata_cache -> 'batch_no' = '"BATCH-001"'
-- This is more efficient than indexing the entire JSONB when you only query specific fields
CREATE INDEX idx_credentials_metadata_batch_no ON credentials
    USING GIN ((metadata_cache -> 'batch_no'));

-- Optional: Index on product_sku (if frequently queried)
CREATE INDEX idx_credentials_metadata_product_sku ON credentials
    USING GIN ((metadata_cache -> 'product_sku'));

-- ----------------------------------------------------------------
-- Comments for credentials table
-- ----------------------------------------------------------------

COMMENT ON TABLE credentials IS 'SBT credentials with on-chain and off-chain metadata';
COMMENT ON COLUMN credentials.id IS 'Unique credential identifier (UUID v4)';
COMMENT ON COLUMN credentials.issuer_id IS 'Foreign key to users table (who issued this credential)';
COMMENT ON COLUMN credentials.recipient_wallet_address IS 'EVM wallet address (0x + 40 hex chars)';
COMMENT ON COLUMN credentials.token_id IS 'ERC-721 token ID (uint256, NULL until minted)';
COMMENT ON COLUMN credentials.tx_hash IS 'Blockchain transaction hash (0x + 64 hex chars, NULL until submitted)';
COMMENT ON COLUMN credentials.arweave_hash IS 'Arweave permanent storage hash (NULL until uploaded)';
COMMENT ON COLUMN credentials.metadata_cache IS 'JSONB cache of credential metadata (for fast querying without Arweave)';
COMMENT ON COLUMN credentials.issuer_ref_id IS 'Issuer internal reference ID (for tracking/reconciliation)';
COMMENT ON COLUMN credentials.status IS 'Lifecycle status: QUEUED -> PENDING -> CONFIRMED/FAILED';
COMMENT ON COLUMN credentials.created_at IS 'Credential creation timestamp (when request was made)';
COMMENT ON COLUMN credentials.updated_at IS 'Last status update timestamp';
COMMENT ON COLUMN credentials.confirmed_at IS 'On-chain confirmation timestamp (NULL until CONFIRMED)';

-- ========================================================================
-- TRIGGERS (Automatic Timestamp Updates)
-- ========================================================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for users table
CREATE TRIGGER users_updated_at_trigger
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for credentials table
CREATE TRIGGER credentials_updated_at_trigger
    BEFORE UPDATE ON credentials
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ========================================================================
-- INITIAL DATA (Optional - for development/testing)
-- ========================================================================

-- Uncomment for development environment to create a test admin user
-- Password: "admin123" (bcrypt hash)
-- INSERT INTO users (email, password_hash, role, kyc_status, credits) VALUES
--     ('admin@truthprotocol.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye/IY/lGhzzN7mIQGLJ9.OrVLWyJkzJVy', 'ADMIN', 'APPROVED', 0.00);

-- ========================================================================
-- INDEXES SUMMARY (Performance Tuning)
-- ========================================================================
--
-- users table (5 indexes):
--   1. PRIMARY KEY (id)                          - Automatic clustered index
--   2. UNIQUE (email)                            - Enforced by constraint
--   3. idx_users_role                            - Query by role
--   4. idx_users_kyc_status                      - Query by KYC status
--   5. idx_users_data_retention                  - Compliance queries
--
-- credentials table (9 indexes):
--   1. PRIMARY KEY (id)                          - Automatic clustered index
--   2. idx_credentials_issuer_id                 - Most common query pattern
--   3. idx_credentials_token_id (PARTIAL UNIQUE) - Enforce uniqueness for CONFIRMED
--   4. idx_credentials_status                    - Relayer Worker queries
--   5. idx_credentials_recipient_wallet          - Verifier queries
--   6. idx_credentials_issuer_ref_id             - Issuer tracking
--   7. idx_credentials_metadata_cache_gin        - Full JSONB queries
--   8. idx_credentials_metadata_batch_no         - Specific JSONB attribute
--   9. idx_credentials_metadata_product_sku      - Specific JSONB attribute
--
-- Total indexes: 14 (optimized for read-heavy workload)
-- Estimated index overhead: ~20-30% of table size
-- Recommended vacuum strategy: VACUUM ANALYZE daily
-- ========================================================================

-- ========================================================================
-- MIGRATION VALIDATION QUERIES (For Testing)
-- ========================================================================

-- Verify tables were created
-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

-- Verify indexes were created
-- SELECT tablename, indexname, indexdef FROM pg_indexes
-- WHERE schemaname = 'public' ORDER BY tablename, indexname;

-- Verify constraints
-- SELECT conname, contype, conrelid::regclass AS table_name
-- FROM pg_constraint WHERE connamespace = 'public'::regnamespace;

-- Test insert (should succeed)
-- INSERT INTO users (email, password_hash, role, kyc_status)
-- VALUES ('test@example.com', '$2a$10$test...', 'ISSUER', 'APPROVED') RETURNING *;

-- Test invalid role (should fail)
-- INSERT INTO users (email, password_hash, role)
-- VALUES ('bad@example.com', 'hash', 'INVALID_ROLE');

-- ========================================================================
-- END OF MIGRATION
-- ========================================================================
