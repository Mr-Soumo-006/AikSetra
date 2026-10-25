import { v4 as uuidv4 } from 'uuid';
import { db } from '../db/database.js';
import { config } from '../config/index.js';
import type { BankAccount, VpaRecord } from '../types/index.js';

const POPULAR_BANKS = [
  { bankName: 'State Bank of India', bankCode: 'SBIN', ifscPrefix: 'SBIN000' },
  { bankName: 'HDFC Bank', bankCode: 'HDFC', ifscPrefix: 'HDFC000' },
  { bankName: 'ICICI Bank', bankCode: 'ICIC', ifscPrefix: 'ICIC000' },
  { bankName: 'Axis Bank', bankCode: 'UTIB', ifscPrefix: 'UTIB000' },
  { bankName: 'Punjab National Bank', bankCode: 'PUNB', ifscPrefix: 'PUNB000' },
  { bankName: 'Bank of Baroda', bankCode: 'BARB', ifscPrefix: 'BARB000' },
  { bankName: 'Kotak Mahindra Bank', bankCode: 'KKBK', ifscPrefix: 'KKBK000' },
  { bankName: 'Canara Bank', bankCode: 'CNRB', ifscPrefix: 'CNRB000' },
  { bankName: 'Union Bank of India', bankCode: 'UBIN', ifscPrefix: 'UBIN053' },
  { bankName: 'Bank of India', bankCode: 'BKID', ifscPrefix: 'BKID000' },
  { bankName: 'IndusInd Bank', bankCode: 'INDB', ifscPrefix: 'INDB000' },
  { bankName: 'Yes Bank', bankCode: 'YESB', ifscPrefix: 'YESB000' },
  { bankName: 'IDFC FIRST Bank', bankCode: 'IDFB', ifscPrefix: 'IDFB004' },
  { bankName: 'Federal Bank', bankCode: 'FDRL', ifscPrefix: 'FDRL000' },
  { bankName: 'Bandhan Bank', bankCode: 'BDBL', ifscPrefix: 'BDBL000' },
  { bankName: 'Indian Bank', bankCode: 'IDIB', ifscPrefix: 'IDIB000' },
  { bankName: 'Central Bank of India', bankCode: 'CBIN', ifscPrefix: 'CBIN028' },
  { bankName: 'UCO Bank', bankCode: 'UCBA', ifscPrefix: 'UCBA000' },
  { bankName: 'Indian Overseas Bank', bankCode: 'IOBA', ifscPrefix: 'IOBA000' },
  { bankName: 'IDBI Bank', bankCode: 'IBKL', ifscPrefix: 'IBKL000' },
  { bankName: 'Bank of Maharashtra', bankCode: 'MAHB', ifscPrefix: 'MAHB000' },
  { bankName: 'Punjab & Sind Bank', bankCode: 'PSIB', ifscPrefix: 'PSIB000' },
  { bankName: 'AU Small Finance Bank', bankCode: 'AUBL', ifscPrefix: 'AUBL000' },
  { bankName: 'Airtel Payments Bank', bankCode: 'AIRP', ifscPrefix: 'AIRP000' },
  { bankName: 'India Post Payments Bank', bankCode: 'IPOS', ifscPrefix: 'IPOS000' },
];

export class AccountService {
  public static discoverBankAccounts(phone: string) {
    if (config.isProduction && !config.npciMerchantKey) {
      throw new Error('Real-time bank account discovery requires certified NPCI/Setu Account Aggregator integration in production.');
    }
    // Simulates NPCI/PSP device-bound SMS account discovery
    const lastDigits = phone.slice(-4);
    return POPULAR_BANKS.map((b, idx) => ({
      bankName: b.bankName,
      bankCode: b.bankCode,
      ifsc: `${b.ifscPrefix}${1000 + idx}`,
      maskedAccountNumber: `•••• •••• ${lastDigits}`,
      accountType: 'SAVINGS' as const,
      eligibleForUpi: true,
      isSimulated: config.isSimulationMode,
    }));
  }

  public static linkAccount(params: {
    userId: string;
    bankName: string;
    bankCode?: string;
    ifsc: string;
    maskedAccountNumber?: string;
    accountNumber?: string;
    accountType?: 'SAVINGS' | 'CURRENT';
    initialBalance?: number;
    setAsPrimary?: boolean;
    replaceOnboardingAccount?: boolean;
    verificationToken?: string;
    verificationMethod?: 'OTP' | 'PENNY_DROP' | 'CARD_CHALLENGE' | 'ACCOUNT_AGGREGATOR';
  }): BankAccount {
    if (config.isProduction && !params.verificationToken) {
      throw new Error('Bank account linking in production requires verified ownership challenge (penny-drop or OTP verification token).');
    }
    const allAccounts = db.get('accounts');
    const userAccounts = allAccounts.filter((a) => a.userId === params.userId);
    const user = db.get('users').find((u) => u.id === params.userId);

    const inferredCode =
      params.bankCode ||
      (params.ifsc && params.ifsc.length >= 4 ? params.ifsc.slice(0, 4).toUpperCase() : 'SBIN');
    const rawNum = (params.accountNumber || params.maskedAccountNumber || user?.phone || '4519').replace(/[^0-9]/g, '');
    const last4 = rawNum.length >= 4 ? rawNum.slice(-4) : '4519';
    const masked = `•••• •••• ${last4}`;
    const balanceVal =
      typeof params.initialBalance === 'number' && !isNaN(params.initialBalance) && params.initialBalance >= 0
        ? Number(params.initialBalance.toFixed(2))
        : 0.0;

    // If called during onboarding Step 4, update the default account created during Step 3 OTP verification
    if (params.replaceOnboardingAccount && userAccounts.length === 1) {
      const target = userAccounts[0];
      target.bankName = params.bankName;
      target.bankCode = inferredCode;
      target.ifsc = params.ifsc.toUpperCase();
      target.maskedAccountNumber = masked;
      target.accountType = params.accountType || 'SAVINGS';
      target.balance = balanceVal;
      target.openingBalance = balanceVal;
      target.isPrimary = true;
      target.upiPinSet = !!user?.mpinHash;
      db.save();
      return target;
    }

    const shouldBePrimary = params.setAsPrimary !== false || userAccounts.length === 0;
    if (shouldBePrimary) {
      for (const acc of userAccounts) {
        acc.isPrimary = false;
      }
    }

    const account: BankAccount = {
      id: `acc_${uuidv4().replace(/-/g, '').slice(0, 10)}`,
      userId: params.userId,
      bankName: params.bankName,
      bankCode: inferredCode,
      ifsc: params.ifsc.toUpperCase(),
      maskedAccountNumber: masked,
      accountType: params.accountType || 'SAVINGS',
      isPrimary: shouldBePrimary,
      balance: balanceVal,
      openingBalance: balanceVal,
      upiPinSet: !!user?.mpinHash,
    };

    db.insert('accounts', account);

    // Link to user's primary VPA
    if (user && user.primaryVpa) {
      const vpa = db.get('vpas').find((v) => v.vpa === user.primaryVpa);
      if (vpa && (shouldBePrimary || !vpa.accountId)) {
        vpa.accountId = account.id;
        db.save();
      }
    }

    console.log(
      `🏦 [AIKSETRA CBS LINK] Linked ${account.bankName} (${account.maskedAccountNumber}, IFSC: ${account.ifsc}) for ${user?.fullName || params.userId} | Balance: ₹${account.balance.toFixed(2)}`
    );

    return account;
  }

  public static setPrimaryAccount(userId: string, accountId: string): BankAccount {
    const userAccounts = db.get('accounts').filter((a) => a.userId === userId);
    const target = userAccounts.find((a) => a.id === accountId);
    if (!target) throw new Error('Bank account not found.');

    for (const acc of userAccounts) {
      acc.isPrimary = acc.id === accountId;
    }

    const user = db.get('users').find((u) => u.id === userId);
    if (user && user.primaryVpa) {
      const vpa = db.get('vpas').find((v) => v.vpa === user.primaryVpa);
      if (vpa) vpa.accountId = target.id;
    }
    db.save();
    return target;
  }

  public static addMoneyToAccount(params: {
    userId: string;
    accountId?: string;
    amount: number;
    sourceNote?: string;
  }) {
    if (config.isProduction) {
      throw new Error('Direct balance creation is prohibited in production. Account deposits must be confirmed through verified payment gateway settlement.');
    }

    const { userId, accountId, amount, sourceNote = 'Simulated Sandbox Deposit' } = params;
    if (!amount || amount <= 0) throw new Error('Please enter a valid deposit amount.');

    const userAccounts = db.get('accounts').filter((a) => a.userId === userId);
    const account =
      (accountId ? userAccounts.find((a) => a.id === accountId) : null) ||
      userAccounts.find((a) => a.isPrimary) ||
      userAccounts[0];
    if (!account) throw new Error('No linked bank account found.');

    const user = db.get('users').find((u) => u.id === userId);
    const txnId = `txn_cr_${uuidv4().replace(/-/g, '').slice(0, 10)}`;
    const newBal = Number((account.balance + amount).toFixed(2));
    account.balance = newBal;

    const rrn = `4291${Math.floor(10000000 + Math.random() * 90000000)}`;
    const transaction = {
      id: txnId,
      txnRef: `SIM_DEP_${Date.now().toString().slice(-8)}`,
      upiRrn: rrn,
      senderUserId: userId,
      senderAccountId: account.id,
      senderVpa: 'sandbox.gateway@npci',
      receiverVpa: user?.primaryVpa || 'user@aiksetra',
      receiverName: `${user?.fullName || 'Account Holder'} (${account.bankName})`,
      amount: Number(amount.toFixed(2)),
      currency: 'INR',
      txnType: 'P2P' as const,
      status: 'SIMULATED_SUCCESS' as const,
      remark: `${sourceNote} -> ${account.bankName} (${account.maskedAccountNumber})`,
      createdAt: new Date().toISOString(),
      metadata: {
        isCredit: true,
        isSelfDeposit: true,
        isSimulated: true,
        bankName: account.bankName,
      },
    };

    db.insert('transactions', transaction as any);
    db.insert('ledger', {
      id: `led_dep_${uuidv4().replace(/-/g, '').slice(0, 10)}`,
      transactionId: txnId,
      accountId: account.id,
      accountType: 'USER_ACCOUNT',
      entryType: 'CREDIT',
      amount: Number(amount.toFixed(2)),
      currency: 'INR',
      balanceAfter: newBal,
      description: `${sourceNote} -> ${account.bankName}`,
      createdAt: new Date().toISOString(),
    });
    db.save();

    return {
      success: true,
      account,
      transaction,
      isSimulated: true,
      newBalance: account.balance,
    };
  }

  /**
   * P0: Real Inbound Payment Gateway Deposit
   * Called strictly upon verified PG callback (e.g. Razorpay/Setu/YesBank)
   */
  public static async processVerifiedGatewayDeposit(params: {
    accountId: string;
    amount: number;
    providerTxnId: string;
    bankRrn: string;
    gatewayProvider: string;
  }) {
    const { accountId, amount, providerTxnId, bankRrn, gatewayProvider } = params;
    const account = db.get('accounts').find((a) => a.id === accountId);
    if (!account) throw new Error('Target bank account not found for verified deposit.');

    const user = db.get('users').find((u) => u.id === account.userId);

    return await db.transaction(async () => {
      account.balance = Number((account.balance + amount).toFixed(2));

      const txnId = `txn_dep_${uuidv4().slice(0, 10)}`;
      db.insert('ledger', {
        id: `led_dep_${uuidv4().slice(0, 10)}`,
        transactionId: txnId,
        accountId: account.id,
        accountType: 'USER_ACCOUNT',
        entryType: 'CREDIT',
        amount,
        currency: 'INR',
        balanceAfter: account.balance,
        description: `INBOUND GATEWAY DEPOSIT: ${gatewayProvider} (${providerTxnId})`,
        createdAt: new Date().toISOString(),
      });

      const transaction = {
        id: txnId,
        txnRef: providerTxnId,
        upiRrn: bankRrn,
        receiverUserId: account.userId,
        senderVpa: `${gatewayProvider.toLowerCase()}@settlement`,
        receiverVpa: user?.primaryVpa || 'user@aiksetra',
        receiverName: account.bankName,
        amount,
        currency: 'INR',
        txnType: 'P2M' as const,
        status: 'SUCCESS' as const,
        remark: `Verified Bank Deposit via ${gatewayProvider}`,
        createdAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
        metadata: {
          isDeposit: true,
          provider: gatewayProvider,
          providerTxnId,
        },
      };

      db.insert('transactions', transaction as any);
      return { success: true, balance: account.balance, transaction };
    });
  }

  public static getAccounts(userId: string): BankAccount[] {
    return db.get('accounts').filter((a) => a.userId === userId);
  }

  public static getBalance(accountId: string, userId: string): number {
    const account = db.get('accounts').find((a) => a.id === accountId && a.userId === userId);
    if (!account) throw new Error('Bank account not found.');
    return account.balance;
  }

  public static resolveVpa(vpaQuery: string): {
    valid: boolean;
    vpa: string;
    fullName?: string;
    trustScore?: number;
    isMerchant?: boolean;
    trustBadge: string;
  } {
    const cleanVpa = vpaQuery.trim().toLowerCase();
    const vpas = db.get('vpas');
    const record = vpas.find((v) => v.vpa.toLowerCase() === cleanVpa);

    if (record) {
      let trustBadge = 'Verified Contact';
      if (record.isMerchant) trustBadge = 'Verified AikSetra Merchant';
      else if (record.trustScore >= 90) trustBadge = 'Highly Trusted Payee';
      else if (record.trustScore < 50) trustBadge = 'Reported Unsafe';

      return {
        valid: true,
        vpa: record.vpa,
        fullName: record.fullName,
        trustScore: record.trustScore,
        isMerchant: record.isMerchant,
        trustBadge,
      };
    }

    // External VPA resolution simulation
    if (cleanVpa.includes('@')) {
      const parts = cleanVpa.split('@');
      const inferredName = parts[0]
        .replace(/[^a-zA-Z]/g, ' ')
        .split(' ')
        .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
        .join(' ')
        .trim();

      return {
        valid: true,
        vpa: cleanVpa,
        fullName: inferredName || 'Verified NPCI User',
        trustScore: 70,
        isMerchant: cleanVpa.includes('merchant') || cleanVpa.includes('bill'),
        trustBadge: 'Standard Verified Payee',
      };
    }

    return {
      valid: false,
      vpa: vpaQuery,
      trustBadge: 'Invalid VPA',
    };
  }
}
