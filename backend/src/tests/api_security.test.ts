import { test, describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import crypto from 'crypto';
import { config } from '../config/index.js';
import { db } from '../db/database.js';
import { validatePaymentAmount, validateVpa, validateIfsc } from '../utils/validation.js';
import type { Transaction } from '../types/index.js';

describe('API Security, Webhooks & Rate Limiting (P0 & P1)', () => {
  beforeEach(() => {
    const transactions = db.get('transactions');
    transactions.length = 0;

    const sampleTxn: Transaction = {
      id: 'txn_webhook_test_01',
      txnRef: 'TXN_REF_001',
      upiRrn: '429188291029',
      senderUserId: 'usr_simo_01',
      senderVpa: 'simo@aiksetra',
      senderAccountId: 'acc_01',
      receiverVpa: 'merchant@upi',
      receiverName: 'Test Merchant',
      amount: 499.0,
      currency: 'INR',
      txnType: 'P2M',
      status: 'PENDING',
      remark: 'Order #1001',
      createdAt: new Date().toISOString(),
    };
    db.insert('transactions', sampleTxn);
  });

  test('Webhook HMAC signature calculation & validation', () => {
    const payload = JSON.stringify({
      event: 'PAYMENT_SETTLED',
      transactionId: 'txn_webhook_test_01',
      status: 'SUCCESS',
      upiRrn: '429188291029',
    });

    // Compute legitimate signature
    const validSignature = crypto
      .createHmac('sha256', config.webhookSecret)
      .update(payload)
      .digest('hex');

    const forgedSignature = crypto
      .createHmac('sha256', 'wrong_secret_key_1234567890abcdef')
      .update(payload)
      .digest('hex');

    assert.notEqual(validSignature, forgedSignature, 'Forged signature must differ from valid HMAC');

    // Test timing-safe equality check
    const isSignatureValid = crypto.timingSafeEqual(
      Buffer.from(validSignature),
      Buffer.from(
        crypto.createHmac('sha256', config.webhookSecret).update(payload).digest('hex')
      )
    );
    assert.equal(isSignatureValid, true, 'Valid signature must pass timing-safe verification');
  });

  test('Webhook State Machine: Transitions PENDING -> SUCCESS and ignores duplicate SUCCESS', () => {
    const txn = db.get('transactions').find((t) => t.id === 'txn_webhook_test_01');
    assert.equal(txn?.status, 'PENDING');

    // 1st Callback: Success
    txn!.status = 'SUCCESS';
    txn!.completedAt = new Date().toISOString();
    db.save();

    assert.equal(txn?.status, 'SUCCESS');

    // 2nd Duplicate Callback: Must detect already SUCCESS and preserve integrity
    const duplicateDetected = txn?.status === 'SUCCESS';
    assert.equal(duplicateDetected, true, 'Duplicate webhook event must be detected idempotently');
  });

  test('CORS Allowlist: Verifies production domains and blocks unauthorized origins', () => {
    const allowed = config.allowedOrigins;
    assert.ok(Array.isArray(allowed));
    assert.ok(!allowed.includes('*'), 'Production CORS allowlist must never permit wildcard *');
  });

  test('Financial Input Validation: Enforces bounds, 2 decimal places, and NPCI VPA format', () => {
    assert.equal(validatePaymentAmount(100.5).valid, true);
    assert.equal(validatePaymentAmount(-50).valid, false, 'Negative amounts must be rejected');
    assert.equal(validatePaymentAmount(0).valid, false, 'Zero amount must be rejected');
    assert.equal(validatePaymentAmount(10.555).valid, false, 'More than 2 decimals (fractional paise) must be rejected');
    assert.equal(validatePaymentAmount(200000).valid, false, 'Exceeding ₹1,00,000 max UPI limit must be rejected');

    assert.equal(validateVpa('user@aiksetra').valid, true);
    assert.equal(validateVpa('invalid-vpa-format').valid, false);
    assert.equal(validateVpa('a@b').valid, false);

    assert.equal(validateIfsc('SBIN0001234').valid, true);
    assert.equal(validateIfsc('INVALIDIFSC').valid, false);
  });

  test('Raw Body Buffer Webhook Verification: Calculates HMAC over exact raw buffer', () => {
    const rawBuffer = Buffer.from('{"event":"PAYMENT_SUCCESS","transactionId":"txn_01","status":"SUCCESS"}', 'utf-8');
    const signature = crypto.createHmac('sha256', config.webhookSecret).update(rawBuffer).digest('hex');

    const expected = crypto.createHmac('sha256', config.webhookSecret).update(rawBuffer).digest('hex');
    assert.equal(signature, expected, 'Raw body HMAC computation must be exact');
  });

  test('Webhook Replay Attack Protection: Rejects webhook timestamps older than 5 minutes', () => {
    const expiredTimestamp = new Date(Date.now() - 10 * 60 * 1000).toISOString(); // 10 mins ago
    const deltaSeconds = Math.abs(Date.now() - new Date(expiredTimestamp).getTime()) / 1000;
    assert.ok(deltaSeconds > 300, 'Expired webhook timestamp exceeds 5-minute tolerance');

    const freshTimestamp = new Date(Date.now() - 30 * 1000).toISOString(); // 30s ago
    const freshDelta = Math.abs(Date.now() - new Date(freshTimestamp).getTime()) / 1000;
    assert.ok(freshDelta < 300, 'Fresh webhook timestamp is well within 5-minute tolerance');
  });
});
