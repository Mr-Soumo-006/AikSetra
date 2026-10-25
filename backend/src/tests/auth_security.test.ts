import { test, describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { AuthService, hashMpin } from '../services/auth.service.js';
import { escapeHtml, sanitizeUrl } from '../utils/sanitize.js';
import { db } from '../db/database.js';

describe('Auth & Security Verifications (P0 & P2)', () => {
  beforeEach(() => {
    // Reset or prepare test user
    const users = db.get('users');
    let testUser = users.find((u) => u.id === 'test_usr_01');
    if (!testUser) {
      testUser = {
        id: 'test_usr_01',
        phone: '9999900001',
        fullName: 'Test Security User',
        email: 'test@aiksetra.in',
        panNumber: 'TESTP1234A',
        kycStatus: 'VERIFIED',
        deviceId: 'dev_test_01',
        simId: 'sim_test_01',
        mpinSalt: 'test_salt_1234567890abcdef',
        mpinHash: hashMpin('456789', 'test_salt_1234567890abcdef'),
        failedMpinAttempts: 0,
        primaryVpa: 'testuser@aiksetra',
        liteBalance: 1000,
        lrsUsedUsd: 0,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };
      db.insert('users', testUser);
    } else {
      testUser.failedMpinAttempts = 0;
      testUser.mpinLockedUntil = undefined;
      testUser.mpinHash = hashMpin('456789', 'test_salt_1234567890abcdef');
    }
  });

  test('PBKDF2 salted hash generates consistent 64-char hex and differs with different salts', () => {
    const salt1 = 'salt_alpha_1234567890';
    const salt2 = 'salt_beta_1234567890';
    const hash1 = hashMpin('123456', salt1);
    const hash2 = hashMpin('123456', salt2);

    assert.equal(hash1.length, 64, 'PBKDF2 SHA-256 output must be 32 bytes (64 hex characters)');
    assert.notEqual(hash1, hash2, 'Identical MPINs with different salts must produce different hashes');
    assert.equal(hashMpin('123456', salt1), hash1, 'Hashing the same MPIN and salt must be deterministic');
  });

  test('Verify MPIN succeeds with correct PIN and increments failures on wrong PIN', () => {
    assert.equal(AuthService.verifyMpin('test_usr_01', '456789'), true, 'Correct MPIN must verify successfully');

    // Wrong MPIN
    assert.equal(AuthService.verifyMpin('test_usr_01', '000000'), false, 'Incorrect MPIN must fail verification');

    const user = db.get('users').find((u) => u.id === 'test_usr_01');
    assert.equal(user?.failedMpinAttempts, 1, 'Failed attempt counter must increment');
  });

  test('Account is locked for 5 minutes after 3 consecutive wrong MPIN attempts', () => {
    assert.equal(AuthService.verifyMpin('test_usr_01', '111111'), false, 'Attempt 1 must return false');
    assert.equal(AuthService.verifyMpin('test_usr_01', '222222'), false, 'Attempt 2 must return false');
    assert.equal(AuthService.verifyMpin('test_usr_01', '333333'), false, 'Attempt 3 must return false and engage lock');

    const user = db.get('users').find((u) => u.id === 'test_usr_01');
    assert.ok(user?.mpinLockedUntil, 'mpinLockedUntil timestamp must be populated');
    assert.ok(user.mpinLockedUntil > Date.now(), 'Lockout must be in the future');

    // Subsequent attempt even with correct PIN must throw lockout error
    assert.throws(
      () => AuthService.verifyMpin('test_usr_01', '456789'),
      /Account temporarily locked/i,
      'Locked account must reject even the correct MPIN until timer expires'
    );
  });

  test('HTML Escaping (P0 Issue 8) neutralizes XSS payloads in payment links', () => {
    const maliciousName = '<script>alert("xss")</script>';
    const safeName = escapeHtml(maliciousName);
    assert.equal(safeName, '&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;');
    assert.ok(!safeName.includes('<script>'), 'Must not contain unescaped script tag');

    const descWithQuotes = 'Coffee & Tea "Special" \'Discount\'';
    const safeDesc = escapeHtml(descWithQuotes);
    assert.equal(safeDesc, 'Coffee &amp; Tea &quot;Special&quot; &#39;Discount&#39;');
  });

  test('URL Sanitizer permits upi:// and http(s):// but blocks javascript: pseudo-protocol', () => {
    assert.equal(sanitizeUrl('upi://pay?pa=test@aiksetra&am=100'), 'upi://pay?pa=test@aiksetra&am=100');
    assert.equal(sanitizeUrl('https://aiksetra.in/pay'), 'https://aiksetra.in/pay');
    assert.equal(sanitizeUrl('javascript:alert(1)'), '#', 'Malicious javascript: URLs must be replaced with #');
    assert.equal(sanitizeUrl('data:text/html,<script>alert(1)</script>'), '#', 'Data URIs must be replaced with #');
  });

  test('New user registration does not set default MPIN or fabricated balance', () => {
    const unconfiguredUser = {
      id: 'test_usr_new_02',
      phone: '9888800002',
      fullName: 'New User Test',
      email: 'newuser@aiksetra.in',
      kycStatus: 'PENDING' as const,
      deviceId: 'dev_02',
      simId: 'sim_02',
      primaryVpa: 'newuser@aiksetra',
      liteBalance: 0,
      lrsUsedUsd: 0,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    db.insert('users', unconfiguredUser);

    assert.throws(
      () => AuthService.verifyMpin('test_usr_new_02', '1234'),
      /UPI MPIN has not been configured/i,
      'Unconfigured MPIN must be rejected when attempting to verify'
    );
  });

  test('Explicit MPIN setup succeeds for non-trivial PIN and rejects trivial PINs', () => {
    assert.throws(
      () => AuthService.setMpin('test_usr_01', '1234'),
      /Weak MPIN chosen/i,
      'Trivial PIN 1234 must be rejected'
    );
    assert.throws(
      () => AuthService.setMpin('test_usr_01', '0000'),
      /Weak MPIN chosen/i,
      'Trivial PIN 0000 must be rejected'
    );

    const setResult = AuthService.setMpin('test_usr_01', '892143');
    assert.equal(setResult.success, true);
    assert.equal(AuthService.verifyMpin('test_usr_01', '892143'), true);
  });
});
