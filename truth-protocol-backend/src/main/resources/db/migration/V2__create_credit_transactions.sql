-- ========================================================================
-- Flyway Migration V2: Create credit_transactions table
-- ========================================================================
-- Purpose: Add credit transaction history table for audit trail
-- Author: TRUTH Protocol Team
-- Date: 2025-12-05
-- ========================================================================

-- ========================================================================
-- 1. CREATE CREDIT_TRANSACTIONS TABLE
-- ========================================================================
-- Records all credit transactions (purchases, deductions, refunds) for
-- complete audit trail and financial reconciliation.
-- ========================================================================

CREATE TABLE credit_transactions (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Foreign Keys
    user_id UUID NOT NULL,
    credential_id UUID, -- NULL for PURCHASE and ADJUSTMENT transactions

    -- Transaction Details
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('PURCHASE', 'DEDUCT', 'REFUND', 'ADJUSTMENT')),
    amount NUMERIC(10, 2) NOT NULL, -- Can be positive or negative
    balance_after NUMERIC(10, 2) NOT NULL CHECK (balance_after >= 0), -- Snapshot of balance after transaction

    -- Optional References
    description VARCHAR(500), -- Human-readable description
    payment_reference VARCHAR(255), -- External payment ID (Stripe, PayPal, etc.)

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Foreign Key Constraints
    CONSTRAINT fk_credit_transaction_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_credit_transaction_credential FOREIGN KEY (credential_id) REFERENCES credentials(id) ON DELETE SET NULL
);

-- ========================================================================
-- 2. CREATE INDEXES FOR PERFORMANCE
-- ========================================================================

-- Index for querying user's transaction history (most common query)
CREATE INDEX idx_credit_transactions_user_created ON credit_transactions(user_id, created_at DESC);

-- Index for filtering by transaction type
CREATE INDEX idx_credit_transactions_type ON credit_transactions(transaction_type);

-- Index for finding transactions related to specific credential
CREATE INDEX idx_credit_transactions_credential ON credit_transactions(credential_id) WHERE credential_id IS NOT NULL;

-- Index for payment reconciliation
CREATE INDEX idx_credit_transactions_payment_ref ON credit_transactions(payment_reference) WHERE payment_reference IS NOT NULL;

-- ========================================================================
-- 3. ADD COMMENTS FOR DOCUMENTATION
-- ========================================================================

COMMENT ON TABLE credit_transactions IS 'Audit trail for all credit transactions (purchases, deductions, refunds)';
COMMENT ON COLUMN credit_transactions.id IS 'Unique transaction identifier (UUID)';
COMMENT ON COLUMN credit_transactions.user_id IS 'User who owns this transaction';
COMMENT ON COLUMN credit_transactions.credential_id IS 'Associated credential (NULL for PURCHASE/ADJUSTMENT)';
COMMENT ON COLUMN credit_transactions.transaction_type IS 'Type: PURCHASE, DEDUCT, REFUND, ADJUSTMENT';
COMMENT ON COLUMN credit_transactions.amount IS 'Transaction amount (positive for credits added, negative for deducted)';
COMMENT ON COLUMN credit_transactions.balance_after IS 'User balance snapshot after this transaction';
COMMENT ON COLUMN credit_transactions.description IS 'Human-readable transaction description';
COMMENT ON COLUMN credit_transactions.payment_reference IS 'External payment system reference (Stripe, PayPal, etc.)';
COMMENT ON COLUMN credit_transactions.created_at IS 'Transaction timestamp (immutable)';
