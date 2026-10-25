import { test, describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { LedgerService } from '../services/ledger.service.js';
import { db } from '../db/database.js';
import type { BankAccount } from '../types/index.js';

describe('Financial Integrity & Double-Entry Ledger (P1)', () => {
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
});
