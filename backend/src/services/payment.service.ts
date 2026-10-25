import { v4 as uuidv4 } from 'uuid';
import { db } from '../db/database.js';
import { config } from '../config/index.js';
import { pspSimulator } from './psp.simulator.js';
import { ScamShieldService } from './scamShield.service.js';
import { soundboxService } from './soundbox.service.js';
import { VaultService } from './vault.service.js';
import { AuthService } from './auth.service.js';
import { LedgerService } from './ledger.service.js';
import { AuditService } from './audit.service.js';
import type { Transaction, CollectRequest, BankAccount, LedgerEntry } from '../types/index.js';

export interface InitiatePaymentParams {
  senderUserId: string;
  senderAccountId?: string;
  receiverVpa: string;
  amount: number;
  mpin?: string;
  remark?: string;
  idempotencyKey?: string;
  bypassScamShieldWarning?: boolean;
}

export class PaymentService {
  /**
   * Issue 14, 15, 16, 17, 21, 22:
   * Executes payments with mandatory MPIN verification, atomic concurrency lock,
   * double-entry balanced ledger, and database-enforced idempotency.
   */
  public static async executePayment(params: InitiatePaymentParams): Promise<{
    success: boolean;
    transaction: Transaction;
    scamShieldAnalysis?: any;
    soundboxAnnounced?: boolean;
    roundedUpAmount?: number;
    updatedBalance?: number;
  }> {
    const {
      senderUserId,
      senderAccountId,
      receiverVpa,
      amount,
      mpin,
      remark = 'UPI Payment',
      idempotencyKey,
      bypassScamShieldWarning,
    } = params;

    if (amount <= 0 || !Number.isFinite(amount)) {
      throw new Error('Invalid payment amount. Amount must be a positive number.');
    }

    // 1. Idempotency Check & Atomic Reservation (P1 Issue 15)
    if (idempotencyKey) {
      const existing = db.get('transactions').find((t) => t.idempotencyKey === idempotencyKey);
      if (existing) {
        return { success: true, transaction: existing };
      }
      if (!db.reserveIdempotencyKey(idempotencyKey)) {
        throw new Error('Payment with this idempotency key is already in progress. Please wait.');
      }
    }

    try {

    // 2. Fetch sender user & account (Issue 6 & 21)
    const user = db.get('users').find((u) => u.id === senderUserId);
    if (!user) throw new Error('Sender user not found.');

    if (receiverVpa.trim().toLowerCase() === user.primaryVpa.trim().toLowerCase()) {
      throw new Error('Self payments via P2P not permitted. Use Self Transfer between own accounts.');
    }

    const accounts = db.get('accounts').filter((a) => a.userId === senderUserId);
    if (accounts.length === 0) {
      throw new Error('No linked bank accounts found. Please link an account first.');
    }

    const remitterAccount = senderAccountId
      ? accounts.find((a) => a.id === senderAccountId)
      : accounts.find((a) => a.isPrimary) || accounts[0];

    if (!remitterAccount) {
      throw new Error('Selected bank account could not be found or does not belong to user.');
    }

    // 3. Mandatory MPIN verification (Issue 14)
    if (!mpin || mpin.trim().length < 4) {
      throw new Error('Valid 4 or 6 digit UPI MPIN is required to authorize transaction.');
    }

    if (!AuthService.verifyMpin(senderUserId, mpin)) {
      throw new Error('Incorrect UPI MPIN. Transaction aborted.');
    }

    // 4. Run Scam Shield Pre-Payment Analysis
    const scamAnalysis = ScamShieldService.analyzePaymentRisk({
      senderUserId,
      senderVpa: user.primaryVpa,
      receiverVpa,
      amount,
      remark,
    });

    if (scamAnalysis.recommendation === 'BLOCK') {
      throw new Error(`Payment blocked by Scam Shield: ${scamAnalysis.warnings.join(' ')}`);
    }

    if (
      scamAnalysis.recommendation === 'REQUIRE_COOLING_OFF' &&
      !bypassScamShieldWarning
    ) {
      throw new Error(
        `High Fraud Risk detected (${scamAnalysis.riskScore}/100). Cooling off protection enabled. Please review warning details.`
      );
    }

    // 5. Atomic Balance & Limit Verification (Issue 22)
    if (remitterAccount.balance < amount) {
      throw new Error(`Insufficient funds in ${remitterAccount.bankName} account.`);
    }

    // 6. Invoke Banking Switch Rail
    if (config.isProduction && !config.npciMerchantKey) {
      throw new Error('Authorized Banking PSP Gateway credentials are required in production. Simulated payment processing is prohibited.');
    }

    const txnRef = `BOP${Date.now()}`;
    const pspResult = await pspSimulator.executeReqPay({
      payerVpa: user.primaryVpa,
      payeeVpa: receiverVpa,
      amount,
      encryptedMpinBlock: 'NPCI_CL_PBKDF2_SECURE_BLOCK',
      txnRef,
      remitterBankCode: remitterAccount.bankCode,
    });

    const txnId = `txn_${uuidv4().replace(/-/g, '').slice(0, 12)}`;

    if (!pspResult.success) {
      const failedTxn: Transaction = {
        id: txnId,
        txnRef,
        upiRrn: pspResult.upiRrn,
        senderUserId,
        senderVpa: user.primaryVpa,
        senderAccountId: remitterAccount.id,
        receiverVpa,
        receiverName: scamAnalysis.verifiedLegalName,
        amount,
        currency: 'INR',
        txnType: 'P2P',
        status: 'FAILED',
        remark,
        failureReason: pspResult.responseMessage,
        scamShieldScore: scamAnalysis.riskScore,
        idempotencyKey,
        createdAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      };
      db.insert('transactions', failedTxn);
      AuditService.log({
        actorId: senderUserId,
        action: 'PAYMENT_FAILED_SWITCH',
        resource: 'TRANSACTION',
        resourceId: txnId,
        metadata: { reason: pspResult.responseMessage, amount },
      });
      throw new Error(`Bank Payment Failed: ${pspResult.responseMessage}`);
    }

    // 7. Resolve beneficiary account (if internal) for Atomic Double-Entry Settlement
    let beneficiaryUserId: string | undefined;
    let beneficiaryName = scamAnalysis.verifiedLegalName;
    let beneficiaryAccount: BankAccount | undefined;

    // Check by VPA table
    const beneficiaryVpa = db.get('vpas').find((v) => v.vpa.toLowerCase() === receiverVpa.toLowerCase());
    if (beneficiaryVpa && beneficiaryVpa.accountId) {
      const benAcc = db.get('accounts').find((a) => a.id === beneficiaryVpa.accountId);
      if (benAcc) {
        beneficiaryAccount = benAcc;
        beneficiaryUserId = benAcc.userId;
      }
    }

    // Check by User table (primaryVpa, phone, or prefix match)
    if (!beneficiaryAccount) {
      const cleanReceiver = receiverVpa.toLowerCase().trim();
      const phoneDigits = cleanReceiver.replace(/\D/g, '');
      const beneficiaryUser = db.get('users').find((u) => {
        if (u.primaryVpa.toLowerCase() === cleanReceiver) return true;
        if (phoneDigits.length >= 10 && u.phone.includes(phoneDigits.slice(-10))) return true;
        const uPrefix = u.primaryVpa.split('@')[0].toLowerCase();
        const rPrefix = cleanReceiver.split('@')[0].toLowerCase();
        return uPrefix === rPrefix;
      });

      if (beneficiaryUser) {
        beneficiaryUserId = beneficiaryUser.id;
        beneficiaryName = beneficiaryUser.fullName;
        const benAccounts = db.get('accounts').filter((a) => a.userId === beneficiaryUser.id);
        beneficiaryAccount = benAccounts.find((a) => a.isPrimary) || benAccounts[0];
      }
    }

    // 8. Atomic Double-Entry Ledger Posting (Issue 17 & 26)
    const { senderBalanceAfter } = await LedgerService.executeDoubleEntryTransfer({
      transactionId: txnId,
      senderAccount: remitterAccount,
      receiverAccount: beneficiaryAccount,
      amount,
      currency: 'INR',
      description: `${remark} (${user.primaryVpa} -> ${receiverVpa})`,
    });

    // 9. Soundbox Audio Trigger (if recipient is a merchant)
    let soundboxAnnounced = false;
    const merchant = db.get('merchants').find((m) => m.merchantVpa.toLowerCase() === receiverVpa.toLowerCase());
    if (merchant) {
      merchant.totalVolumeInr += amount;
      soundboxAnnounced = true;
      soundboxService.broadcastPayment({
        merchantId: merchant.id,
        merchantName: merchant.businessName,
        amount,
        currency: 'INR',
        payerName: user.fullName,
        payerVpa: user.primaryVpa,
        language: merchant.soundboxLanguage,
      });
    }

    // 10. Create Successful Transaction Record
    const transaction: Transaction = {
      id: txnId,
      txnRef,
      upiRrn: pspResult.upiRrn,
      senderUserId,
      senderVpa: user.primaryVpa,
      senderAccountId: remitterAccount.id,
      receiverUserId: beneficiaryUserId,
      receiverVpa,
      receiverName: beneficiaryName,
      amount,
      currency: 'INR',
      txnType: beneficiaryVpa?.isMerchant ? 'P2M' : 'P2P',
      status: 'SUCCESS',
      remark,
      scamShieldScore: scamAnalysis.riskScore,
      idempotencyKey,
      createdAt: new Date().toISOString(),
      completedAt: new Date().toISOString(),
      metadata: {
        isSimulated: config.isSimulationMode,
        soundboxAnnounced,
      },
    };

    db.insert('transactions', transaction);

    AuditService.log({
      actorId: senderUserId,
      action: 'PAYMENT_SUCCESS',
      resource: 'TRANSACTION',
      resourceId: txnId,
      metadata: { amount, upiRrn: pspResult.upiRrn, receiverVpa, isSimulated: config.isSimulationMode },
    });

    // 11. Digital Gullak micro-savings round-up
    let roundedUpAmount = 0;
    try {
      const roundUpResult = VaultService.applyAutoRoundUp(senderUserId, amount);
      if (roundUpResult && roundUpResult.roundedUpAmount > 0) {
        roundedUpAmount = roundUpResult.roundedUpAmount;
      }
    } catch (_) {}

    db.save();

    return {
      success: true,
      transaction,
      scamShieldAnalysis: scamAnalysis,
      soundboxAnnounced,
      roundedUpAmount,
      updatedBalance: senderBalanceAfter,
    };
    } finally {
      if (idempotencyKey) {
        db.releaseIdempotencyKey(idempotencyKey);
      }
    }
  }

  public static async executeLitePayment(params: {
    senderUserId: string;
    receiverVpa: string;
    amount: number;
    remark?: string;
  }): Promise<Transaction> {
    const { senderUserId, receiverVpa, amount, remark = 'UPI Lite Payment' } = params;

    if (amount <= 0 || amount > 500) {
      throw new Error('UPI Lite transaction limit is up to ₹500 per payment.');
    }

    if (config.isProduction && !config.npciMerchantKey) {
      throw new Error('Authorized Banking PSP Gateway required for UPI Lite on-device settlement in production.');
    }

    const user = db.get('users').find((u) => u.id === senderUserId);
    if (!user) throw new Error('User not found.');

    const txnId = `txn_lite_${uuidv4().replace(/-/g, '').slice(0, 10)}`;
    const txnRef = `LITE${Date.now()}`;
    const upiRrn = config.isSimulationMode
      ? `4291${Math.floor(10000000 + Math.random() * 90000000)}`
      : '';

    // Concurrency control & atomic double-entry ledger within db.transaction
    return await db.transaction(async () => {
      if (user.liteBalance < amount) {
        throw new Error(`Insufficient UPI Lite balance (Available: ₹${user.liteBalance.toFixed(2)}).`);
      }

      user.liteBalance = Number((user.liteBalance - amount).toFixed(2));

      // Resolve beneficiary
      let beneficiaryUserId: string | undefined;
      let beneficiaryName = 'UPI Lite Beneficiary';
      let beneficiaryAccount: BankAccount | undefined;

      const benVpa = db.get('vpas').find((v) => v.vpa.toLowerCase() === receiverVpa.toLowerCase());
      if (benVpa && benVpa.accountId) {
        beneficiaryAccount = db.get('accounts').find((a) => a.id === benVpa.accountId);
        if (beneficiaryAccount) {
          beneficiaryUserId = beneficiaryAccount.userId;
          beneficiaryName = benVpa.fullName;
        }
      }

      // Paired DEBIT on sender's UPI Lite wallet
      const debitEntry: LedgerEntry = {
        id: `led_lite_dr_${uuidv4().slice(0, 10)}`,
        transactionId: txnId,
        accountId: `lite_${user.id}`,
        accountType: 'USER_ACCOUNT',
        entryType: 'DEBIT',
        amount,
        currency: 'INR',
        balanceAfter: user.liteBalance,
        description: `UPI LITE DEBIT: ${remark}`,
        createdAt: new Date().toISOString(),
      };

      // Paired CREDIT on receiver or clearing
      let creditEntry: LedgerEntry;
      if (beneficiaryAccount) {
        beneficiaryAccount.balance = Math.round((beneficiaryAccount.balance + amount) * 100) / 100;
        creditEntry = {
          id: `led_lite_cr_${uuidv4().slice(0, 10)}`,
          transactionId: txnId,
          accountId: beneficiaryAccount.id,
          accountType: 'USER_ACCOUNT',
          entryType: 'CREDIT',
          amount,
          currency: 'INR',
          balanceAfter: beneficiaryAccount.balance,
          description: `UPI LITE CREDIT: ${remark}`,
          createdAt: new Date().toISOString(),
        };
      } else {
        creditEntry = {
          id: `led_lite_cr_${uuidv4().slice(0, 10)}`,
          transactionId: txnId,
          accountId: 'acc_clearing_switch_00',
          accountType: 'SETTLEMENT_CLEARING',
          entryType: 'CREDIT',
          amount,
          currency: 'INR',
          balanceAfter: 0,
          description: `UPI LITE CLEARING CREDIT: ${remark}`,
          createdAt: new Date().toISOString(),
        };
      }

      db.insert('ledger', debitEntry);
      db.insert('ledger', creditEntry);

      const transaction: Transaction = {
        id: txnId,
        txnRef,
        upiRrn,
        senderUserId,
        senderVpa: user.primaryVpa,
        receiverUserId: beneficiaryUserId,
        receiverVpa,
        receiverName: beneficiaryName,
        amount,
        currency: 'INR',
        txnType: 'LITE',
        status: config.isProduction ? 'PENDING' : 'SUCCESS',
        remark,
        createdAt: new Date().toISOString(),
        completedAt: config.isProduction ? undefined : new Date().toISOString(),
        metadata: {
          isSimulated: config.isSimulationMode,
          rail: 'UPI_LITE_WALLET',
        },
      };

      db.insert('transactions', transaction);

      const merchant = db.get('merchants').find((m) => m.merchantVpa.toLowerCase() === receiverVpa.toLowerCase());
      if (merchant) {
        merchant.totalVolumeInr += amount;
        soundboxService.broadcastPayment({
          merchantId: merchant.id,
          merchantName: merchant.businessName,
          amount,
          currency: 'INR',
          payerName: user.fullName,
          payerVpa: user.primaryVpa,
          language: merchant.soundboxLanguage,
        });
      }

      return transaction;
    });
  }

  public static getTransactionHistory(userId: string): Transaction[] {
    const user = db.get('users').find((u) => u.id === userId);
    if (!user) return [];

    return db
      .get('transactions')
      .filter((t) => (
        t.senderUserId === userId ||
        t.receiverUserId === userId ||
        t.receiverVpa.toLowerCase() === user.primaryVpa.toLowerCase() ||
        (user.phone && t.receiverVpa.includes(user.phone))
      ))
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  }

  public static createCollectRequest(params: {
    payerVpa: string;
    payeeUserId: string;
    amount: number;
    remark?: string;
  }): CollectRequest {
    const payeeUser = db.get('users').find((u) => u.id === params.payeeUserId);
    if (!payeeUser) throw new Error('Payee user not found.');

    const collect: CollectRequest = {
      id: `col_${uuidv4().replace(/-/g, '').slice(0, 10)}`,
      payerVpa: params.payerVpa,
      payeeVpa: payeeUser.primaryVpa,
      payeeName: payeeUser.fullName,
      amount: params.amount,
      remark: params.remark || 'UPI Collect Request',
      expiryMinutes: 60,
      status: 'PENDING',
      createdAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
    };

    db.insert('collectRequests', collect);
    return collect;
  }

  public static async approveCollectRequest(collectId: string, payerUserId: string, mpin: string): Promise<Transaction> {
    const collects = db.get('collectRequests');
    const collect = collects.find((c) => c.id === collectId);
    if (!collect) throw new Error('Collect request not found.');
    if (collect.status !== 'PENDING') throw new Error(`Collect request already ${collect.status}.`);

    const payerUser = db.get('users').find((u) => u.id === payerUserId);
    if (!payerUser) throw new Error('Payer user not found.');

    const userVpas = db.get('vpas').filter((v) => v.userId === payerUserId).map((v) => v.vpa.toLowerCase());
    userVpas.push(payerUser.primaryVpa.toLowerCase());

    if (!userVpas.includes(collect.payerVpa.toLowerCase())) {
      throw new Error('Unauthorized: You are not the targeted payer for this collect request.');
    }

    const result = await this.executePayment({
      senderUserId: payerUserId,
      receiverVpa: collect.payeeVpa,
      amount: collect.amount,
      mpin,
      remark: collect.remark,
    });

    collect.status = 'APPROVED';
    collect.txnId = result.transaction.id;
    db.save();

    return result.transaction;
  }
}
