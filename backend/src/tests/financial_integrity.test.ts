import { test, describe, beforeEach, after } from 'node:test';
import assert from 'node:assert/strict';
import { LedgerService } from '../services/ledger.service.js';
import { CrossBorderService } from '../services/crossBorder.service.js';
import { RecoveryService } from '../services/recovery.service.js';
import { PaymentService } from '../services/payment.service.js';
import { hashMpin } from '../services/auth.service.js';
import { db } from '../db/database.js';
import { postgresDb } from '../db/postgres.js';
import type { BankAccount, Transaction, User } from '../types/index.js';

describe('Financial Integrity & Double-Entry Ledger (P1)', () => {
  after(async () => {
    try {
      await postgresDb.close();
    } catch (_) {}
  });

  let senderAcc: BankAccount;
  let receiverAcc: BankAccount;

  beforeEach(() => {
    // Set up test accounts with known balances
    const accounts = db.get('accounts');
    accounts.length = 0; // Clear for isolation

    const ledger = db.get('ledger');
    ledger.length = 0; // Clear for isolation

    senderAcc = {
      id: 'acc_test_sender_01',
      userId: 'usr_sender_01',
      bankName: 'HDFC Bank',
      bankCode: 'HDFC',
      ifsc: 'HDFC0001234',
      maskedAccountNumber: '•••• •••• 1111',
      accountType: 'SAVINGS',
      isPrimary: true,
      balance: 10000.0,
      upiPinSet: true,
    };

    receiverAcc = {
      id: 'acc_test_receiver_02',
      userId: 'usr_receiver_02',
      bankName: 'State Bank of India',
      bankCode: 'SBIN',
      ifsc: 'SBIN0005678',
      maskedAccountNumber: '•••• •••• 2222',
      accountType: 'SAVINGS',
      isPrimary: true,
      balance: 5000.0,
      upiPinSet: true,
    };

    db.insert('accounts', senderAcc);
    db.insert('accounts', receiverAcc);
  });

  test('Balanced Double-Entry Transfer: Sum of DEBITS equals Sum of CREDITS', async () => {
    const transferAmount = 2500.0;
    const initialTotalSystemBalance = senderAcc.balance + receiverAcc.balance;

    const result = await LedgerService.executeDoubleEntryTransfer({
      transactionId: 'txn_test_debit_credit_01',
      senderAccount: senderAcc,
      receiverAccount: receiverAcc,
      amount: transferAmount,
      currency: 'INR',
      description: 'P2P Test Transfer',
    });

    assert.equal(result.senderBalanceAfter, 7500.0, 'Sender balance must decrease by transfer amount');
    assert.equal(result.receiverBalanceAfter, 7500.0, 'Receiver balance must increase by transfer amount');

    // Verify conservation of money
    const updatedSender = db.get('accounts').find((a) => a.id === senderAcc.id);
    const updatedReceiver = db.get('accounts').find((a) => a.id === receiverAcc.id);
    assert.equal(
      updatedSender!.balance + updatedReceiver!.balance,
      initialTotalSystemBalance,
      'Total money in the system must be perfectly conserved'
    );

    // Verify paired ledger entries
    const ledger = db.get('ledger').filter((e) => e.transactionId === 'txn_test_debit_credit_01');
    assert.equal(ledger.length, 2, 'Exactly 2 ledger entries must be created for a transfer');

    const debit = ledger.find((e) => e.entryType === 'DEBIT');
    const credit = ledger.find((e) => e.entryType === 'CREDIT');
    assert.ok(debit, 'DEBIT entry must exist');
    assert.ok(credit, 'CREDIT entry must exist');
    assert.equal(debit!.amount, credit!.amount, 'Debit amount must equal credit amount');
  });

  test('Overdraft prevention: Attempting to transfer more than balance throws error and touches neither account', async () => {
    const excessiveAmount = 50000.0; // Sender only has 10,000

    await assert.rejects(
      async () => {
        await LedgerService.executeDoubleEntryTransfer({
          transactionId: 'txn_test_overdraft_01',
          senderAccount: senderAcc,
          receiverAccount: receiverAcc,
          amount: excessiveAmount,
          currency: 'INR',
          description: 'Excessive Overdraft Transfer',
        });
      },
      /Insufficient funds/i,
      'Transfer exceeding balance must be rejected'
    );

    // Verify neither balance changed
    const currentSender = db.get('accounts').find((a) => a.id === senderAcc.id);
    const currentReceiver = db.get('accounts').find((a) => a.id === receiverAcc.id);
    assert.equal(currentSender?.balance, 10000.0, 'Sender balance must remain untouched');
    assert.equal(currentReceiver?.balance, 5000.0, 'Receiver balance must remain untouched');
  });

  test('Deterministic Concurrency Mutex: Parallel payments on same account are serialized safely', async () => {
    // Fire 5 concurrent transfers of ₹1,500 each (Total: ₹7,500)
    const transfers = Array.from({ length: 5 }, (_, i) =>
      LedgerService.executeDoubleEntryTransfer({
        transactionId: `txn_concurrent_${i}`,
        senderAccount: senderAcc,
        receiverAccount: receiverAcc,
        amount: 1500.0,
        currency: 'INR',
        description: `Concurrent Transfer #${i}`,
      })
    );

    await Promise.all(transfers);

    const currentSender = db.get('accounts').find((a) => a.id === senderAcc.id);
    const currentReceiver = db.get('accounts').find((a) => a.id === receiverAcc.id);

    // Initial 10,000 - (5 * 1,500) = 2,500
    assert.equal(currentSender?.balance, 2500.0, 'Concurrent debits must serialize cleanly without race conditions');
    // Initial 5,000 + (5 * 1,500) = 12,500
    assert.equal(currentReceiver?.balance, 12500.0, 'Concurrent credits must serialize cleanly without race conditions');
  });

  test('Atomic Transaction Rollback: Thrown exception rolls back all in-memory changes', async () => {
    const initialBal = senderAcc.balance;

    await assert.rejects(
      async () => {
        await db.transaction(async () => {
          senderAcc.balance = 1.0; // modify balance
          throw new Error('Simulated database/rail failure midway through transaction');
        });
      },
      /Simulated database\/rail failure/
    );

    const currentSender = db.get('accounts').find((a) => a.id === senderAcc.id);
    assert.equal(currentSender?.balance, initialBal, 'In-memory state must roll back to pre-transaction snapshot on failure');
  });

  test('Atomic Reversals: Reverses payment with sender credit, receiver debit, and paired ledger entries', async () => {
    // 1. Initial transfer of ₹1,000
    await LedgerService.executeDoubleEntryTransfer({
      transactionId: 'txn_to_reverse_01',
      senderAccount: senderAcc,
      receiverAccount: receiverAcc,
      amount: 1000.0,
      currency: 'INR',
      description: 'Transfer before reversal',
    });

    const txnToReverse: any = {
      id: 'txn_to_reverse_01',
      txnRef: 'REF_REV_01',
      upiRrn: '429100000001',
      senderUserId: senderAcc.userId,
      senderAccountId: senderAcc.id,
      receiverUserId: receiverAcc.userId,
      amount: 1000.0,
      currency: 'INR',
      status: 'SUCCESS',
    };

    // 2. Execute atomic reversal
    const reversed = await LedgerService.executeReversal({
      originalTransaction: txnToReverse,
      reason: 'Wrong VPA credited error',
    });

    assert.equal(reversed, true, 'Reversal must execute successfully');
    assert.equal(txnToReverse.status, 'REVERSED');

    // 3. Check balances restored: sender back to 10000, receiver back to 5000
    const curSender = db.get('accounts').find((a) => a.id === senderAcc.id);
    const curReceiver = db.get('accounts').find((a) => a.id === receiverAcc.id);
    assert.equal(curSender?.balance, 10000.0, 'Sender balance must be restored');
    assert.equal(curReceiver?.balance, 5000.0, 'Receiver balance must be reduced by reversal amount');

    // 4. Repeated reversal must be idempotent
    const secondReversal = await LedgerService.executeReversal({
      originalTransaction: txnToReverse,
      reason: 'Duplicate call',
    });
    assert.equal(secondReversal, false, 'Idempotent repeated reversal must return false without modifying balances');
  });

  test('Dynamic Reconciliation: Accurately checks balance against baseline opening balance plus ledger', () => {
    senderAcc.openingBalance = 10000.0;
    const initialRec = LedgerService.reconcileAccount(senderAcc.id);
    assert.equal(initialRec.reconciled, true, 'Account with zero net delta and matching opening balance must reconcile');

    // Manually skew balance
    senderAcc.balance = 8500.0;
    const skewedRec = LedgerService.reconcileAccount(senderAcc.id);
    assert.equal(skewedRec.reconciled, false, 'Discrepancy must be detected when balance does not match ledger');
    assert.equal(skewedRec.balanceDiscrepancy, 1500.0);
  });

  test('Persistent Idempotency Keys: Enforces uniqueness and prevents concurrent duplicate execution', () => {
    const testKey = 'idem_key_unique_test_99';
    assert.equal(db.reserveIdempotencyKey(testKey), true, 'First key reservation must succeed');
    assert.equal(db.reserveIdempotencyKey(testKey), false, 'Duplicate key reservation must be rejected');

    db.releaseIdempotencyKey(testKey);
  });

  test('Cross-Border Durable Settlement: Compensatory refund on partner failure restores balance and LRS', async () => {
    const testRemitTxn: Transaction = {
      id: 'remit_cb_test_01',
      txnRef: 'TXN_CB_01',
      upiRrn: '',
      senderUserId: senderAcc.userId,
      senderAccountId: senderAcc.id,
      senderVpa: 'sender@aiksetra',
      receiverVpa: 'john@usd',
      receiverName: 'John Beneficiary',
      amount: 8500.0,
      currency: 'INR',
      txnType: 'CROSS_BORDER',
      status: 'PENDING_PARTNER_SETTLEMENT',
      remark: 'Abroad Remittance Hold',
      createdAt: new Date().toISOString(),
      metadata: { targetCurrency: 'USD', targetAmount: 100 },
    };
    db.insert('transactions', testRemitTxn);

    // Initial balance after hold deduction
    senderAcc.balance = 1500.0;

    // Partner callback reports failure
    const success = await CrossBorderService.confirmPartnerSettlement({
      transferId: testRemitTxn.id,
      partnerRrn: 'SWIFT_REJ_99',
      status: 'FAILED',
      failureReason: 'Beneficiary IBAN closed at receiving institution',
    });

    assert.equal(success, true);
    assert.equal(testRemitTxn.status, 'FAILED');

    // Verify compensatory refund restored sender balance
    const updatedSender = db.get('accounts').find((a) => a.id === senderAcc.id);
    assert.equal(updatedSender?.balance, 10000.0, 'Failed partner settlement must refund user balance in full');
  });

  test('Concurrent Transaction Isolation: Parallel transactions serialize cleanly via mutex without state clobbering', async () => {
    let order: string[] = [];

    const tx1 = db.transaction(async () => {
      order.push('tx1_start');
      await new Promise((r) => setTimeout(r, 20));
      order.push('tx1_end');
    });

    const tx2 = db.transaction(async () => {
      order.push('tx2_start');
      await new Promise((r) => setTimeout(r, 10));
      order.push('tx2_end');
    });

    await Promise.all([tx1, tx2]);

    // Mutex strictly ensures tx1 finishes completely before tx2 begins
    assert.deepEqual(order, ['tx1_start', 'tx1_end', 'tx2_start', 'tx2_end'], 'Transactions must not interleave');
  });

  test('Crash-Safe Auto Recovery: Scans and auto-recovers orphaned pending transactions', async () => {
    const oldDate = new Date(Date.now() - 10 * 60 * 1000).toISOString(); // 10 mins ago
    const orphanedTxn: Transaction = {
      id: 'txn_orphaned_01',
      txnRef: 'REF_ORPH_01',
      upiRrn: '',
      senderUserId: senderAcc.userId,
      senderAccountId: senderAcc.id,
      senderVpa: 'sender@aiksetra',
      receiverVpa: 'merchant@upi',
      receiverName: 'Orphaned Merchant',
      amount: 500.0,
      currency: 'INR',
      txnType: 'P2M',
      status: 'PENDING',
      remark: 'Abandoned transaction',
      createdAt: oldDate,
    };
    db.insert('transactions', orphanedTxn);

    const recoveryResult = await RecoveryService.recoverPendingTransactions(5 * 60 * 1000);
    assert.ok(recoveryResult.recoveredCount >= 1);
    assert.ok(recoveryResult.transactionIds.includes('txn_orphaned_01'));

    const recovered = db.get('transactions').find((t) => t.id === 'txn_orphaned_01');
    assert.equal(recovered?.status, 'FAILED');
    assert.ok(recovered?.failureReason?.includes('Auto Recovery'));
  });

  test('Payment Provider Separation: Simulator payments produce SIMULATED_SUCCESS and are never labeled as real bank settlement', async () => {
    const salt = 'testsalt1234567890abcdef12345678';
    const testUser: User = {
      id: senderAcc.userId,
      phone: '9876543210',
      fullName: 'Provider Test User',
      email: 'testprovider@aiksetra.in',
      primaryVpa: 'sendertest@aiksetra',
      deviceId: 'dev_test_01',
      simId: 'sim_test_01',
      kycStatus: 'VERIFIED',
      liteBalance: 0,
      lrsUsedUsd: 0,
      mpinSalt: salt,
      mpinHash: hashMpin('1234', salt),
      failedMpinAttempts: 0,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    db.insert('users', testUser);

    const paymentRes = await PaymentService.executePayment({
      senderUserId: senderAcc.userId,
      senderAccountId: senderAcc.id,
      receiverVpa: 'beneficiary@aiksetra',
      amount: 150.0,
      mpin: '1234',
      remark: 'Provider separation audit test',
      bypassScamShieldWarning: true,
    });

    assert.ok(paymentRes.success, 'Simulated payment succeeded');
    assert.equal(paymentRes.transaction.status, 'SIMULATED_SUCCESS', 'Simulator payments must have status SIMULATED_SUCCESS');
    assert.notEqual(paymentRes.transaction.status, 'SUCCESS', 'Simulator payment must NEVER be marked as real SUCCESS settlement');
    assert.equal(paymentRes.transaction.metadata?.isSimulated, true, 'Metadata isSimulated must be true');
    assert.equal(paymentRes.transaction.metadata?.settlementStatus, 'SANDBOX_SIMULATION', 'Settlement status must be SANDBOX_SIMULATION');
    assert.notEqual(paymentRes.transaction.metadata?.settlementStatus, 'CONFIRMED_BANK_SETTLEMENT', 'Settlement status must never be CONFIRMED_BANK_SETTLEMENT');
  });
});
