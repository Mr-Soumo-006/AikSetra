import { test } from 'node:test';
import assert from 'node:assert/strict';
import { postgresDb } from '../db/postgres.js';
import { db } from '../db/database.js';
import { v4 as uuidv4 } from 'uuid';

test('PostgreSQL Runtime Database & ACID Concurrency (P1)', async (t) => {
  t.after(async () => {
    try {
      await postgresDb.close();
    } catch (_) {}
  });

  const isPostgresAvailable = await postgresDb.testConnection();

  if (!isPostgresAvailable) {
    t.diagnostic('PostgreSQL not available in this test environment. Skipping live PostgreSQL test suite.');
    return;
  }

  const initialized = await postgresDb.init();
  assert.equal(initialized, true, 'PostgreSQL database initialization must succeed');
  db.usePostgres(postgresDb);

  await t.test('Durable Idempotency in PostgreSQL: Enforces unique constraint', async () => {
    const testKey = `test_pg_idemp_${uuidv4()}`;
    const firstAttempt = await postgresDb.reserveIdempotencyKey(testKey, 60000);
    assert.equal(firstAttempt, true, 'First attempt to reserve idempotency key must succeed in PostgreSQL');

    const duplicateAttempt = await postgresDb.reserveIdempotencyKey(testKey, 60000);
    assert.equal(duplicateAttempt, false, 'Duplicate reservation of same idempotency key must be rejected by PostgreSQL');

    await postgresDb.releaseIdempotencyKey(testKey);
  });

  await t.test('Pessimistic Row Locking & Atomic Balance Transfer: Updates balances and creates paired ledger entries', async () => {
    const pool = postgresDb.getPool();

    // Setup isolated test accounts in PostgreSQL
    const senderAccId = `test_pg_snd_${Date.now()}`;
    const receiverAccId = `test_pg_rec_${Date.now()}`;
    const testUserId = `test_pg_usr_${Date.now()}`;

    await pool.query(
      `INSERT INTO users (id, phone, full_name, email, primary_vpa, device_id, sim_id)
       VALUES ($1, $2, $3, $4, $5, 'dev_test', 'sim_test')
       ON CONFLICT (id) DO NOTHING`,
      [testUserId, `99${Date.now().toString().slice(-8)}`, 'Test User PG', `test_${Date.now()}@aiksetra.in`, `test_${Date.now()}@aiksetra`]
    );

    await pool.query(
      `INSERT INTO bank_accounts (id, user_id, bank_name, bank_code, ifsc, masked_account_number, balance)
       VALUES ($1, $2, 'Test Bank', 'TBANK', 'TBANK0001', '•••• 1234', 1000.00)`,
      [senderAccId, testUserId]
    );

    await pool.query(
      `INSERT INTO bank_accounts (id, user_id, bank_name, bank_code, ifsc, masked_account_number, balance)
       VALUES ($1, $2, 'Beneficiary Bank', 'BBANK', 'BBANK0002', '•••• 5678', 250.00)`,
      [receiverAccId, testUserId]
    );

    const txnId = `txn_pg_test_${Date.now()}`;

    // Insert transaction row to satisfy foreign key constraint on ledger_entries
    await pool.query(
      `INSERT INTO transactions (id, txn_ref, upi_rrn, sender_vpa, receiver_vpa, receiver_name, amount, currency, txn_type, status)
       VALUES ($1, $2, '123456789012', 'sender@aiksetra', 'receiver@aiksetra', 'Test User PG', 300.00, 'INR', 'P2P', 'INITIATED')`,
      [txnId, `REF_${Date.now()}`]
    );

    // Execute atomic transfer with pessimistic row locking
    const transferResult = await postgresDb.executeAtomicTransferWithRowLock({
      transactionId: txnId,
      senderAccountId: senderAccId,
      receiverAccountId: receiverAccId,
      amount: 300.00,
      currency: 'INR',
      description: 'PostgreSQL ACID Concurrency Test',
    });

    assert.equal(transferResult.senderBalanceAfter, 700.00, 'Sender balance should be deducted by 300.00');
    assert.equal(transferResult.receiverBalanceAfter, 550.00, 'Receiver balance should be credited by 300.00');

    // Verify row in database
    const senderRow = await pool.query('SELECT balance FROM bank_accounts WHERE id = $1', [senderAccId]);
    assert.equal(parseFloat(senderRow.rows[0].balance), 700.00);

    const receiverRow = await pool.query('SELECT balance FROM bank_accounts WHERE id = $1', [receiverAccId]);
    assert.equal(parseFloat(receiverRow.rows[0].balance), 550.00);

    // Verify paired double-entry ledger entries in PostgreSQL
    const ledgerRows = await pool.query('SELECT * FROM ledger_entries WHERE transaction_id = $1', [txnId]);
    assert.equal(ledgerRows.rows.length, 2, 'Must create exactly 2 ledger entries (DEBIT and CREDIT)');

    const debit = ledgerRows.rows.find((r) => r.entry_type === 'DEBIT');
    const credit = ledgerRows.rows.find((r) => r.entry_type === 'CREDIT');
    assert.ok(debit, 'DEBIT entry must exist in PostgreSQL ledger');
    assert.ok(credit, 'CREDIT entry must exist in PostgreSQL ledger');
    assert.equal(parseFloat(debit.amount), parseFloat(credit.amount), 'Debit amount must equal credit amount');

    // Clean up test rows
    await pool.query('DELETE FROM ledger_entries WHERE transaction_id = $1', [txnId]);
    await pool.query('DELETE FROM transactions WHERE id = $1', [txnId]);
    await pool.query('DELETE FROM bank_accounts WHERE id IN ($1, $2)', [senderAccId, receiverAccId]);
    await pool.query('DELETE FROM users WHERE id = $1', [testUserId]);
  });

  await t.test('Overdraft Prevention with Row Locking: Fails safely without partial state', async () => {
    const pool = postgresDb.getPool();

    const senderAccId = `test_pg_snd_od_${Date.now()}`;
    const testUserId = `test_pg_usr_od_${Date.now()}`;

    await pool.query(
      `INSERT INTO users (id, phone, full_name, email, primary_vpa, device_id, sim_id)
       VALUES ($1, $2, $3, $4, $5, 'dev_test', 'sim_test')
       ON CONFLICT (id) DO NOTHING`,
      [testUserId, `98${Date.now().toString().slice(-8)}`, 'Test Overdraft PG', `test_od_${Date.now()}@aiksetra.in`, `test_od_${Date.now()}@aiksetra`]
    );

    await pool.query(
      `INSERT INTO bank_accounts (id, user_id, bank_name, bank_code, ifsc, masked_account_number, balance)
       VALUES ($1, $2, 'Test Bank', 'TBANK', 'TBANK0001', '•••• 9999', 100.00)`,
      [senderAccId, testUserId]
    );

    const txnId = `txn_pg_od_${Date.now()}`;

    await assert.rejects(
      async () => {
        await postgresDb.executeAtomicTransferWithRowLock({
          transactionId: txnId,
          senderAccountId: senderAccId,
          amount: 500.00, // Exceeds balance of 100.00
          currency: 'INR',
          description: 'Overdraft test',
        });
      },
      /Insufficient funds/i
    );

    // Verify balance unchanged
    const res = await pool.query('SELECT balance FROM bank_accounts WHERE id = $1', [senderAccId]);
    assert.equal(parseFloat(res.rows[0].balance), 100.00, 'Balance must remain unchanged after aborted transfer');

    // Clean up
    await pool.query('DELETE FROM bank_accounts WHERE id = $1', [senderAccId]);
    await pool.query('DELETE FROM users WHERE id = $1', [testUserId]);
  });
});
