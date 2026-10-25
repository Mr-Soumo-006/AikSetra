import { test } from 'node:test';
import assert from 'node:assert/strict';
import { db } from '../db/database.js';
import { runSeed } from '../db/seed.js';
import { AccountService } from '../services/account.service.js';
import { PaymentService } from '../services/payment.service.js';
import { soundboxService } from '../services/soundbox.service.js';
import { ScamShieldService } from '../services/scamShield.service.js';
import { postgresDb } from '../db/postgres.js';
import { v4 as uuidv4 } from 'uuid';

test('End-to-End Two-Phone QR Payment Flow (P0, P1 & P2)', async (t) => {
  t.after(async () => {
    try {
      await postgresDb.close();
    } catch (_) {}
  });

  // Reset clean state
  runSeed(true);

  // Phone 1: Receiver (Priya Patel, priya@aiksetra)
  // Phone 2: Sender (Simo Naskar, simo@aiksetra)
  const senderUser = db.get('users').find((u) => u.id === 'usr_simo_01')!;
  const receiverUser = db.get('users').find((u) => u.id === 'usr_priya_03')!;

  assert.ok(senderUser, 'Sender user Simo Naskar must exist');
  assert.ok(receiverUser, 'Receiver user Priya Patel must exist');

  const senderAccounts = db.get('accounts').filter((a) => a.userId === senderUser.id);
  const senderAcc = senderAccounts.find((a) => a.isPrimary) || senderAccounts[0];
  assert.ok(senderAcc, 'Sender bank account must exist');

  const receiverAccounts = db.get('accounts').filter((a) => a.userId === receiverUser.id);
  const receiverAcc = receiverAccounts.find((a) => a.isPrimary) || receiverAccounts[0];
  assert.ok(receiverAcc, 'Receiver bank account must exist');

  const initialSenderBalance = senderAcc.balance;
  const initialReceiverBalance = receiverAcc.balance;

  await t.test('1. Phone 1 generates Dynamic Bharat QR Code URI', async () => {
    const paymentAmount = 750.00;
    const paymentNote = 'Dinner Share';
    const qrIntentUri = `upi://pay?pa=${receiverUser.primaryVpa}&pn=${encodeURIComponent(receiverUser.fullName)}&am=${paymentAmount.toFixed(2)}&cu=INR&tn=${encodeURIComponent(paymentNote)}`;

    assert.ok(qrIntentUri.startsWith('upi://pay?'), 'QR URI must follow NPCI UPI deep-link specification');
    const url = new URL(qrIntentUri);
    assert.equal(url.searchParams.get('pa'), 'priya@aiksetra');
    assert.equal(url.searchParams.get('am'), '750.00');
    assert.equal(url.searchParams.get('cu'), 'INR');
    assert.equal(url.searchParams.get('tn'), 'Dinner Share');
  });

  await t.test('2. Phone 2 scans QR, parses payload & resolves payee identity via Switch', async () => {
    const scannedVpa = 'priya@aiksetra';
    const resolution = AccountService.resolveVpa(scannedVpa);

    assert.equal(resolution.valid, true, 'Receiver VPA must resolve successfully');
    assert.equal(resolution.fullName, 'Priya Patel', 'Receiver legal name must match registered KYC identity');
    assert.ok((resolution.trustScore ?? 0) >= 80, 'Trust score should indicate a verified trusted payee');
  });

  await t.test('3. Phone 2 executes Scam Shield Pre-Payment Safety Check', async () => {
    const analysis = ScamShieldService.analyzePaymentRisk({
      senderUserId: senderUser.id,
      senderVpa: senderUser.primaryVpa,
      receiverVpa: receiverUser.primaryVpa,
      amount: 750.00,
      remark: 'Dinner Share',
    });

    assert.equal(analysis.recommendation, 'PROCEED', 'Trusted contact payment must be approved to proceed');
    assert.equal(analysis.verifiedLegalName, 'Priya Patel');
    assert.ok(analysis.riskLevel === 'SAFE' || analysis.riskLevel === 'LOW', 'Risk level should indicate safe/low risk');
  });

  let paymentTxnId = '';
  const qrIdempotencyKey = `qr_pay_dinner_${uuidv4()}`;

  await t.test('4. Phone 2 authorizes with MPIN & completes double-entry payment', async () => {
    const paymentResult = await PaymentService.executePayment({
      senderUserId: senderUser.id,
      senderAccountId: senderAcc.id,
      receiverVpa: receiverUser.primaryVpa,
      amount: 750.00,
      mpin: '123456', // Valid MPIN for demo user
      remark: 'Dinner Share',
      idempotencyKey: qrIdempotencyKey,
    });

    assert.equal(paymentResult.success, true, 'Payment execution must succeed');
    assert.ok(paymentResult.transaction.id, 'Transaction must have a unique identifier');
    paymentTxnId = paymentResult.transaction.id;

    // Verify balance update
    const updatedSenderAcc = db.get('accounts').find((a) => a.id === senderAcc.id)!;
    const updatedReceiverAcc = db.get('accounts').find((a) => a.id === receiverAcc.id)!;

    assert.equal(
      updatedSenderAcc.balance,
      initialSenderBalance - 750.00,
      'Sender account must be debited by exactly ₹750.00'
    );
    assert.equal(
      updatedReceiverAcc.balance,
      initialReceiverBalance + 750.00,
      'Receiver account must be credited by exactly ₹750.00'
    );

    // Verify paired double-entry ledger entries
    const ledgerEntries = db.get('ledger').filter((l) => l.transactionId === paymentTxnId);
    assert.equal(ledgerEntries.length, 2, 'Must create exactly two balanced ledger entries (DEBIT and CREDIT)');

    const debit = ledgerEntries.find((l) => l.entryType === 'DEBIT');
    const credit = ledgerEntries.find((l) => l.entryType === 'CREDIT');
    assert.ok(debit, 'DEBIT entry must exist in ledger');
    assert.ok(credit, 'CREDIT entry must exist in ledger');
    assert.equal(debit.amount, 750.00);
    assert.equal(credit.amount, 750.00);
    assert.equal(debit.accountId, senderAcc.id);
    assert.equal(credit.accountId, receiverAcc.id);
  });

  await t.test('5. Transaction History: Visible on both sender and receiver devices', async () => {
    // Phone 2 (Sender) transaction history query
    const senderHistory = db
      .get('transactions')
      .filter((t) => t.senderUserId === senderUser.id || t.receiverUserId === senderUser.id);
    const senderTxn = senderHistory.find((t) => t.id === paymentTxnId);
    assert.ok(senderTxn, 'Transaction must appear in sender history');
    assert.equal(senderTxn.amount, 750.00);
    assert.equal(senderTxn.receiverVpa, receiverUser.primaryVpa);

    // Phone 1 (Receiver) transaction history query
    const receiverHistory = db
      .get('transactions')
      .filter((t) => t.receiverUserId === receiverUser.id || t.senderUserId === receiverUser.id);
    const receiverTxn = receiverHistory.find((t) => t.id === paymentTxnId);
    assert.ok(receiverTxn, 'Transaction must appear in receiver history');
    assert.equal(receiverTxn.amount, 750.00);
    assert.equal(receiverTxn.senderVpa, senderUser.primaryVpa);
  });

  await t.test('6. Idempotency & Duplicate Prevention: Retried QR scan returns existing receipt without double debit', async () => {
    const currentSenderBalance = db.get('accounts').find((a) => a.id === senderAcc.id)!.balance;

    // Simulate phone scanning the same dynamic QR code again or network retry
    const duplicateResult = await PaymentService.executePayment({
      senderUserId: senderUser.id,
      senderAccountId: senderAcc.id,
      receiverVpa: receiverUser.primaryVpa,
      amount: 750.00,
      mpin: '123456',
      remark: 'Dinner Share',
      idempotencyKey: qrIdempotencyKey,
    });

    assert.equal(duplicateResult.success, true);
    assert.equal(duplicateResult.transaction.id, paymentTxnId, 'Must return the original transaction ID');

    // Balance must NOT have been deducted a second time
    const balanceAfterRetry = db.get('accounts').find((a) => a.id === senderAcc.id)!.balance;
    assert.equal(balanceAfterRetry, currentSenderBalance, 'Account balance must remain unchanged on duplicate QR scan');
  });

  await t.test('7. Merchant Bharat QR Payment & Audio Soundbox Announcement', async () => {
    // Setup a verified merchant
    const merchant = db.get('merchants')[0] || {
      id: 'merch_test_qr_01',
      userId: receiverUser.id,
      businessName: 'Sharma General Store',
      merchantVpa: 'sharmastore@aiksetra',
      category: 'RETAIL',
      panOrGst: '27AAAAA0000A1Z5',
      apiKey: 'sec_test_merch_key',
      soundboxLanguage: 'hi',
      totalVolumeInr: 0,
      createdAt: new Date().toISOString(),
    };

    if (!db.get('merchants').some((m) => m.id === merchant.id)) {
      db.insert('merchants', merchant);
    }

    let soundboxBroadcastReceived = false;
    let broadcastPayload: any = null;

    // Register a mock listener for Soundbox WebSocket broadcast
    const mockWs = {
      readyState: 1, // WebSocket.OPEN
      send: (data: string) => {
        const parsed = JSON.parse(data);
        if (parsed.type === 'PAYMENT_RECEIVED') {
          soundboxBroadcastReceived = true;
          broadcastPayload = parsed.data;
        }
      },
      on: (_event: string, _callback: Function) => {},
    };
    soundboxService.registerWsClient(mockWs as any);

    const merchantPayResult = await PaymentService.executePayment({
      senderUserId: senderUser.id,
      senderAccountId: senderAcc.id,
      receiverVpa: merchant.merchantVpa,
      amount: 150.00,
      mpin: '123456',
      remark: 'Groceries QR scan',
      idempotencyKey: `merch_qr_${uuidv4()}`,
    });

    assert.equal(merchantPayResult.success, true);
    assert.equal(merchantPayResult.soundboxAnnounced, true, 'Soundbox announcement flag must be true');
    assert.equal(soundboxBroadcastReceived, true, 'WebSocket Soundbox event must be dispatched');
    assert.equal(broadcastPayload.amount, 150.00);
    assert.equal(broadcastPayload.merchantId, merchant.id);
  });
});
