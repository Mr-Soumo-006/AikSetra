-- ====================================================================
-- AikSetra Core Banking & Switch Service - Production PostgreSQL Schema
-- Migration: 001_init.sql
-- Invariants: ACID Transactions, Strict Foreign Keys, CHECK Constraints
-- ====================================================================

-- 1. Users
CREATE TABLE IF NOT EXISTS users (
  id VARCHAR(64) PRIMARY KEY,
  phone VARCHAR(15) UNIQUE NOT NULL,
  full_name VARCHAR(128) NOT NULL,
  email VARCHAR(128) UNIQUE NOT NULL,
  pan_number VARCHAR(10),
  kyc_status VARCHAR(20) DEFAULT 'PENDING' CHECK (kyc_status IN ('PENDING', 'VERIFIED', 'REJECTED')),
  device_id VARCHAR(128) NOT NULL,
  sim_id VARCHAR(128) NOT NULL,
  mpin_hash VARCHAR(128),
  mpin_salt VARCHAR(64),
  failed_mpin_attempts INT DEFAULT 0,
  mpin_locked_until BIGINT,
  is_admin BOOLEAN DEFAULT FALSE,
  primary_vpa VARCHAR(128) UNIQUE NOT NULL,
  lite_balance NUMERIC(12, 2) DEFAULT 0.00 CHECK (lite_balance >= 0 AND lite_balance <= 2000.00),
  lrs_used_usd NUMERIC(12, 2) DEFAULT 0.00 CHECK (lrs_used_usd >= 0 AND lrs_used_usd <= 250000.00),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Bank Accounts
CREATE TABLE IF NOT EXISTS bank_accounts (
  id VARCHAR(64) PRIMARY KEY,
  user_id VARCHAR(64) REFERENCES users(id) ON DELETE CASCADE,
  bank_name VARCHAR(128) NOT NULL,
  bank_code VARCHAR(16) NOT NULL,
  ifsc VARCHAR(16) NOT NULL,
  masked_account_number VARCHAR(32) NOT NULL,
  account_type VARCHAR(16) DEFAULT 'SAVINGS' CHECK (account_type IN ('SAVINGS', 'CURRENT')),
  is_primary BOOLEAN DEFAULT FALSE,
  balance NUMERIC(15, 2) DEFAULT 0.00 CHECK (balance >= 0),
  opening_balance NUMERIC(15, 2) DEFAULT 0.00 CHECK (opening_balance >= 0),
  is_verified BOOLEAN DEFAULT FALSE,
  upi_pin_set BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. VPAs (Virtual Payment Addresses)
CREATE TABLE IF NOT EXISTS vpas (
  vpa VARCHAR(128) PRIMARY KEY,
  user_id VARCHAR(64) REFERENCES users(id) ON DELETE CASCADE,
  full_name VARCHAR(128) NOT NULL,
  account_id VARCHAR(64) REFERENCES bank_accounts(id) ON DELETE SET NULL,
  is_primary BOOLEAN DEFAULT FALSE,
  trust_score INT DEFAULT 90 CHECK (trust_score BETWEEN 0 AND 100),
  fraud_report_count INT DEFAULT 0,
  is_merchant BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Transactions
CREATE TABLE IF NOT EXISTS transactions (
  id VARCHAR(64) PRIMARY KEY,
  txn_ref VARCHAR(64) UNIQUE NOT NULL,
  upi_rrn VARCHAR(32),
  sender_user_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
  sender_vpa VARCHAR(128) NOT NULL,
  sender_account_id VARCHAR(64) REFERENCES bank_accounts(id) ON DELETE SET NULL,
  receiver_user_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
  receiver_vpa VARCHAR(128) NOT NULL,
  receiver_name VARCHAR(128) NOT NULL,
  amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
  currency VARCHAR(8) DEFAULT 'INR',
  txn_type VARCHAR(32) NOT NULL,
  status VARCHAR(32) DEFAULT 'PENDING' CHECK (status IN ('INITIATED', 'PENDING', 'SUCCESS', 'FAILED', 'REVERSED', 'PENDING_PARTNER_SETTLEMENT', 'SIMULATED_SUCCESS')),
  remark VARCHAR(256),
  failure_reason TEXT,
  scam_shield_score INT,
  idempotency_key VARCHAR(128) UNIQUE,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- 5. Immutable Double-Entry Ledger
CREATE TABLE IF NOT EXISTS ledger_entries (
  id VARCHAR(64) PRIMARY KEY,
  transaction_id VARCHAR(64),
  account_id VARCHAR(64) NOT NULL,
  account_type VARCHAR(32) NOT NULL CHECK (account_type IN ('USER_ACCOUNT', 'SETTLEMENT_CLEARING', 'FEE_INCOME', 'ESCROW_HOLD')),
  entry_type VARCHAR(8) NOT NULL CHECK (entry_type IN ('DEBIT', 'CREDIT')),
  amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
  currency VARCHAR(8) DEFAULT 'INR',
  balance_after NUMERIC(15, 2) NOT NULL,
  description TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Audit Logs
CREATE TABLE IF NOT EXISTS audit_logs (
  id VARCHAR(64) PRIMARY KEY,
  actor_id VARCHAR(64),
  action VARCHAR(64) NOT NULL,
  resource VARCHAR(64) NOT NULL,
  resource_id VARCHAR(64),
  ip_address VARCHAR(45),
  user_agent TEXT,
  payload_hash VARCHAR(64),
  metadata JSONB,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Durable Idempotency Keys
CREATE TABLE IF NOT EXISTS idempotency_keys (
  key VARCHAR(128) PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  response JSONB
);

-- 8. Collect Requests
CREATE TABLE IF NOT EXISTS collect_requests (
  id VARCHAR(64) PRIMARY KEY,
  payer_vpa VARCHAR(128) NOT NULL,
  payee_vpa VARCHAR(128) NOT NULL,
  payee_name VARCHAR(128) NOT NULL,
  amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
  remark VARCHAR(256),
  expiry_minutes INT DEFAULT 60,
  status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'EXPIRED')),
  txn_id VARCHAR(64),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL
);

-- 9. Merchants
CREATE TABLE IF NOT EXISTS merchants (
  id VARCHAR(64) PRIMARY KEY,
  user_id VARCHAR(64) REFERENCES users(id) ON DELETE CASCADE,
  business_name VARCHAR(128) NOT NULL,
  merchant_vpa VARCHAR(128) UNIQUE NOT NULL,
  category VARCHAR(64) NOT NULL,
  pan_or_gst VARCHAR(32) NOT NULL,
  api_key VARCHAR(128) NOT NULL,
  webhook_url TEXT,
  soundbox_language VARCHAR(8) DEFAULT 'en',
  total_volume_inr NUMERIC(15, 2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. Pay Links
CREATE TABLE IF NOT EXISTS pay_links (
  id VARCHAR(64) PRIMARY KEY,
  merchant_id VARCHAR(64) REFERENCES merchants(id) ON DELETE CASCADE,
  merchant_name VARCHAR(128) NOT NULL,
  amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
  description VARCHAR(256),
  link_url TEXT NOT NULL,
  upi_intent_url TEXT NOT NULL,
  qr_code_data_url TEXT,
  status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'PAID', 'EXPIRED')),
  paid_at TIMESTAMPTZ,
  paid_by_vpa VARCHAR(128),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for high-throughput concurrency
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_bank_accounts_user ON bank_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_sender_vpa ON transactions(sender_vpa);
CREATE INDEX IF NOT EXISTS idx_transactions_receiver_vpa ON transactions(receiver_vpa);
CREATE INDEX IF NOT EXISTS idx_transactions_idempotency ON transactions(idempotency_key);
CREATE INDEX IF NOT EXISTS idx_ledger_account_id ON ledger_entries(account_id);
CREATE INDEX IF NOT EXISTS idx_idempotency_expires ON idempotency_keys(expires_at);
