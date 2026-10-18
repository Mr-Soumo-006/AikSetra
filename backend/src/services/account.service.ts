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
  { bankName: 'Kotak Mahindra Bank', bankCode: 'KKBK', ifscPrefix: 'KKBK000' },
];

export class AccountService {
  public static discoverBankAccounts(phone: string) {
    // Simulates NPCI/PSP device-bound SMS account discovery
    const lastDigits = phone.slice(-4);
    return POPULAR_BANKS.map((b, idx) => ({
      bankName: b.bankName,
      bankCode: b.bankCode,
      ifsc: `${b.ifscPrefix}${1000 + idx}`,
      maskedAccountNumber: `•••• •••• ${lastDigits}`,
      accountType: 'SAVINGS' as const,
      eligibleForUpi: true,
    }));
  }

  public static linkAccount(params: {
    userId: string;
    bankName: string;
    bankCode: string;
    ifsc: string;
    maskedAccountNumber: string;
    accountType?: 'SAVINGS' | 'CURRENT';
  }): BankAccount {
    const existing = db.get('accounts').filter((a) => a.userId === params.userId);
    const isFirstAccount = existing.length === 0;

    const account: BankAccount = {
      id: `acc_${uuidv4().replace(/-/g, '').slice(0, 10)}`,
      userId: params.userId,
      bankName: params.bankName,
      bankCode: params.bankCode,
      ifsc: params.ifsc,
      maskedAccountNumber: params.maskedAccountNumber,
      accountType: params.accountType || 'SAVINGS',
      isPrimary: isFirstAccount,
      balance: Math.floor(10000 + Math.random() * 90000) + 0.5,
      upiPinSet: true,
    };

    db.insert('accounts', account);

    // Link to user's primary VPA
    const user = db.get('users').find((u) => u.id === params.userId);
    if (user && user.primaryVpa) {
      const vpa = db.get('vpas').find((v) => v.vpa === user.primaryVpa);
      if (vpa && !vpa.accountId) {
        vpa.accountId = account.id;
        db.save();
      }
    }

    return account;
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
