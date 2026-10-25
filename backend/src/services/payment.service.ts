import { v4 as uuidv4 } from 'uuid';
import { db } from '../db/database.js';
import { pspSimulator } from './psp.simulator.js';
import { ScamShieldService } from './scamShield.service.js';
import { soundboxService } from './soundbox.service.js';
import { VaultService } from './vault.service.js';
import { AuthService } from './auth.service.js';
import type { Transaction, CollectRequest } from '../types/index.js';

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

    // 1. Idempotency Check
    if (idempotencyKey) {
      const existing = db.get('transactions').find((t) => t.idempotencyKey === idempotencyKey);
      if (existing) {
        return { success: true, transaction: existing };
      }
    }

    // 2. Fetch sender user & accounts
    const user = db.get('users').find((u) => u.id === senderUserId);
    if (!user) throw new Error('Sender user not found.');

    const accounts = db.get('accounts').filter((a) => a.userId === senderUserId);
    if (accounts.length === 0) {
      throw new Error('No linked bank accounts found. Please link an account first.');
    }

    const remitterAccount = senderAccountId
      ? accounts.find((a) => a.id === senderAccountId)
      : accounts.find((a) => a.isPrimary) || accounts[0];

    if (!remitterAccount) {
      throw new Error('Selected bank account could not be found.');
    }

    // 3. Verify MPIN (unless UPI Lite)
    if (mpin && !AuthService.verifyMpin(senderUserId, mpin)) {
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

    // 5. Balance check
    if (remitterAccount.balance < amount) {
      throw new Error('Insufficient account balance in selected bank account.');
    }

    // 6. Invoke PSP / NPCI Switch Simulator
    const txnRef = `BOP${Date.now()}`;
    const pspResult = await pspSimulator.executeReqPay({
      payerVpa: user.primaryVpa,
      payeeVpa: receiverVpa,
      amount,
      encryptedMpinBlock: 'NPCI_CL_ENC_MOCK_BLOCK',
      txnRef,
      remitterBankCode: remitterAccount.bankCode,
    });

    if (!pspResult.success) {
      const failedTxn: Transaction = {
        id: `txn_${uuidv4().replace(/-/g, '').slice(0, 12)}`,
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
      throw new Error(`Bank Payment Failed: ${pspResult.responseMessage}`);
    }

    // 7. Debit remitter account
    remitterAccount.balance = Number((remitterAccount.balance - amount).toFixed(2));

    // 8. Credit beneficiary if internal account exists (Two-Phone Transfer Resolution)
    let beneficiaryUserId: string | undefined;
    let beneficiaryName = scamAnalysis.verifiedLegalName;

    // Check by VPA table
    const beneficiaryVpa = db.get('vpas').find((v) => v.vpa.toLowerCase() === receiverVpa.toLowerCase());
    if (beneficiaryVpa && beneficiaryVpa.accountId) {
      const benAcc = db.get('accounts').find((a) => a.id === beneficiaryVpa.accountId);
      if (benAcc) {
        benAcc.balance = Number((benAcc.balance + amount).toFixed(2));
        beneficiaryUserId = benAcc.userId;
      }
    }

    // Check by User table (primaryVpa, phone, or prefix match)
    if (!beneficiaryUserId) {
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
        const targetAcc = benAccounts.find((a) => a.isPrimary) || benAccounts[0];
        if (targetAcc) {
          targetAcc.balance = Number((targetAcc.balance + amount).toFixed(2));
        }
      }
    }

    // 9. Create Successful Transaction Record
    const transaction: Transaction = {
      id: `txn_${uuidv4().replace(/-/g, '').slice(0, 12)}`,
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
    };

    db.insert('transactions', transaction);

    // 10. Soundbox Audio Trigger (if recipient is a merchant)
    let soundboxAnnounced = false;
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
      soundboxAnnounced = true;
    }

    // 11. Money Vaults Auto Round-up Rule
    let roundedUpAmount = 0;
    try {
      const roundUpResult = VaultService.applyAutoRoundUp(senderUserId, amount);
      if (roundUpResult.roundedUpAmount > 0) {
        roundedUpAmount = roundUpResult.roundedUpAmount;
        remitterAccount.balance = Number((remitterAccount.balance - roundedUpAmount).toFixed(2));
      }
    } catch (e) {
      console.warn('Vault round-up skipped:', e);
    }

    db.save();

    console.log(`💸 [AIKSETRA NPCI SETTLEMENT] ₹${amount} paid from ${user.primaryVpa} -> ${receiverVpa} | RRN: ${transaction.upiRrn}`);

    return {
      success: true,
      transaction,
      scamShieldAnalysis: scamAnalysis,
      soundboxAnnounced,
      roundedUpAmount,
      updatedBalance: remitterAccount.balance,
    };
  }

  public static async executeLitePayment(params: {
    senderUserId: string;
    receiverVpa: string;
    amount: number;
    remark?: string;
  }): Promise<Transaction> {
    const { senderUserId, receiverVpa, amount, remark = 'UPI Lite Payment' } = params;

    if (amount > 500) {
      throw new Error('UPI Lite maximum transaction limit is ₹500 per payment.');
    }

    const user = db.get('users').find((u) => u.id === senderUserId);
    if (!user) throw new Error('User not found.');

    if (user.liteBalance < amount) {
      throw new Error(`Insufficient UPI Lite balance (Available: ₹${user.liteBalance}).`);
    }

    user.liteBalance = Number((user.liteBalance - amount).toFixed(2));

    const txnRef = `LITE${Date.now()}`;
    const upiRrn = `4291${Math.floor(10000000 + Math.random() * 90000000)}`;

    const transaction: Transaction = {
      id: `txn_lite_${uuidv4().slice(0, 8)}`,
      txnRef,
      upiRrn,
      senderUserId,
      senderVpa: user.primaryVpa,
      receiverVpa,
      receiverName: 'UPI Lite Beneficiary',
      amount,
      currency: 'INR',
      txnType: 'LITE',
      status: 'SUCCESS',
      remark,
      createdAt: new Date().toISOString(),
      completedAt: new Date().toISOString(),
    };

    db.insert('transactions', transaction);

    // Soundbox trigger if merchant
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

    db.save();
    return transaction;
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
