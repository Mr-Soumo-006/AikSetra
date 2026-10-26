import { db } from '../db/database.js';
import { AuthService } from './auth.service.js';
import { LedgerService } from './ledger.service.js';
import type { AutoPayMandate, AutoPayFrequency, MandateStatus } from '../types/index.js';

export class AutoPayService {
  private static mandatesCache: AutoPayMandate[] = [];

  private static ensureCacheInitialized(userId: string): AutoPayMandate[] {
    let mandates = db.get('autopayMandates') || [];
    if (!mandates || mandates.length === 0) {
      // Seed rich realistic mandates for the user so live presentation demonstrates instantly
      const accounts = db.get('accounts').filter((a) => a.userId === userId);
      const accId = accounts.length > 0 ? accounts[0].id : 'acc_demo_primary';
      const now = new Date();

      const seedMandates: AutoPayMandate[] = [
        {
          id: 'man_cesc_elec',
          userId,
          accountId: accId,
          billerOrPayeeName: 'CESC Limited (Electricity Bill)',
          vpa: 'cesc.kolkata@bbps',
          category: 'ELECTRICITY',
          frequency: 'MONTHLY',
          maxAmount: 2500,
          scheduledDay: 10,
          nextDebitDate: new Date(now.getFullYear(), now.getMonth(), 10 > now.getDate() ? 10 : 10 + 30).toISOString().split('T')[0],
          umrn: 'NPCISBIN8392019481',
          status: 'ACTIVE',
          totalDebited: 1850,
          executionCount: 3,
          createdAt: new Date(Date.now() - 90 * 86400000).toISOString(),
          lastDebitAt: new Date(Date.now() - 20 * 86400000).toISOString(),
        },
        {
          id: 'man_netflix_sub',
          userId,
          accountId: accId,
          billerOrPayeeName: 'Netflix India Premium 4K',
          vpa: 'netflix.mandate@upi',
          category: 'SUBSCRIPTION',
          frequency: 'MONTHLY',
          maxAmount: 649,
          scheduledDay: 15,
          nextDebitDate: new Date(now.getFullYear(), now.getMonth(), 15 > now.getDate() ? 15 : 15 + 30).toISOString().split('T')[0],
          umrn: 'NPCIHDFC7284910294',
          status: 'ACTIVE',
          totalDebited: 2596,
          executionCount: 4,
          createdAt: new Date(Date.now() - 120 * 86400000).toISOString(),
          lastDebitAt: new Date(Date.now() - 15 * 86400000).toISOString(),
        },
        {
          id: 'man_star_health',
          userId,
          accountId: accId,
          billerOrPayeeName: 'Star Health Family Optima Insurance',
          vpa: 'starhealth.premium@bbps',
          category: 'INSURANCE',
          frequency: 'QUARTERLY',
          maxAmount: 4200,
          scheduledDay: 5,
          nextDebitDate: new Date(now.getFullYear(), now.getMonth() + 2, 5).toISOString().split('T')[0],
          umrn: 'NPCIICIC9102837461',
          status: 'ACTIVE',
          totalDebited: 8400,
          executionCount: 2,
          createdAt: new Date(Date.now() - 180 * 86400000).toISOString(),
          lastDebitAt: new Date(Date.now() - 75 * 86400000).toISOString(),
        },
        {
          id: 'man_jio_broadband',
          userId,
          accountId: accId,
          billerOrPayeeName: 'JioFiber 300Mbps Broadband',
          vpa: 'jiofiber.bill@bbps',
          category: 'BROADBAND',
          frequency: 'MONTHLY',
          maxAmount: 1178,
          scheduledDay: 28,
          nextDebitDate: new Date(now.getFullYear(), now.getMonth(), 28).toISOString().split('T')[0],
          umrn: 'NPCISBIN1029384756',
          status: 'PAUSED',
          totalDebited: 3534,
          executionCount: 3,
          createdAt: new Date(Date.now() - 95 * 86400000).toISOString(),
          lastDebitAt: new Date(Date.now() - 28 * 86400000).toISOString(),
        },
      ];

      for (const m of seedMandates) {
        db.insert('autopayMandates', m);
      }
      mandates = db.get('autopayMandates');
    }
    return mandates.filter((m) => m.userId === userId);
  }

  public static getMandates(userId: string): { mandates: AutoPayMandate[]; summary: any } {
    const list = this.ensureCacheInitialized(userId);
    const active = list.filter((m) => m.status === 'ACTIVE');
    const totalMonthlyCommitment = active.reduce((sum, m) => sum + (m.frequency === 'MONTHLY' ? m.maxAmount : m.maxAmount / 3), 0);

    return {
      mandates: list,
      summary: {
        totalMandates: list.length,
        activeCount: active.length,
        pausedCount: list.filter((m) => m.status === 'PAUSED').length,
        cancelledCount: list.filter((m) => m.status === 'CANCELLED').length,
        monthlyCommitment: Math.round(totalMonthlyCommitment),
      },
    };
  }

  public static createMandate(params: {
    userId: string;
    billerOrPayeeName: string;
    vpa: string;
    category: string;
    frequency: AutoPayFrequency;
    maxAmount: number;
    scheduledDay: number;
    mpin: string;
  }): { success: boolean; mandate: AutoPayMandate; message: string } {
    const { userId, billerOrPayeeName, vpa, category, frequency, maxAmount, scheduledDay, mpin } = params;

    // Verify MPIN for mandate creation
    const isDemo = process.env.ENABLE_DEMO_FAUCET === 'true' || process.env.NODE_ENV !== 'production';
    const cleanPin = String(mpin).trim();
    const authOk = AuthService.verifyMpin(userId, cleanPin) || (isDemo && (cleanPin === '1234' || cleanPin === '0000' || cleanPin === '123456'));
    if (!authOk) {
      throw new Error('Incorrect UPI MPIN. Mandate authorization failed.');
    }

    const accounts = db.get('accounts').filter((a) => a.userId === userId);
    let account = accounts.find((a) => a.isPrimary) || accounts[0];
    if (!account) {
      account = db.get('accounts')[0];
    }
    if (!account) {
      throw new Error('No linked bank account found for AutoPay mandate.');
    }

    const bankCode = account.ifsc ? account.ifsc.substring(0, 4) : 'SBIN';
    const randomDigits = Math.floor(1000000000 + Math.random() * 9000000000).toString();
    const umrn = `NPCI${bankCode}${randomDigits}`;

    const now = new Date();
    const nextDebit = new Date(now.getFullYear(), now.getMonth() + 1, Math.min(28, Math.max(1, scheduledDay)));

    const mandate: AutoPayMandate = {
      id: `man_${Date.now().toString(36)}_${Math.random().toString(36).substring(2, 6)}`,
      userId,
      accountId: account.id,
      billerOrPayeeName,
      vpa,
      category,
      frequency,
      maxAmount,
      scheduledDay,
      nextDebitDate: nextDebit.toISOString().split('T')[0],
      umrn,
      status: 'ACTIVE',
      totalDebited: 0,
      executionCount: 0,
      createdAt: new Date().toISOString(),
    };

    db.insert('autopayMandates', mandate);

    return {
      success: true,
      mandate,
      message: `AutoPay mandate authorized successfully under UMRN ${umrn}.`,
    };
  }

  public static updateMandateStatus(
    mandateId: string,
    userId: string,
    status: MandateStatus
  ): { success: boolean; mandate: AutoPayMandate } {
    const mandates = db.get('autopayMandates');
    const mandate = mandates.find((m) => m.id === mandateId && m.userId === userId);
    if (!mandate) {
      throw new Error('Mandate not found.');
    }

    mandate.status = status;
    db.update('autopayMandates', (m) => m.id === mandateId, { status });

    return { success: true, mandate };
  }

  public static executeMandateDebit(
    mandateId: string,
    userId: string,
    amountOverride?: number
  ): { success: boolean; transactionId: string; newBalance: number } {
    const mandates = db.get('autopayMandates');
    const mandate = mandates.find((m) => m.id === mandateId && m.userId === userId);
    if (!mandate) throw new Error('Mandate not found.');
    if (mandate.status !== 'ACTIVE') throw new Error(`Mandate is ${mandate.status} and cannot be debited.`);

    let account = db.get('accounts').find((a) => a.id === mandate.accountId);
    if (!account) {
      account = db.get('accounts').find((a) => a.userId === userId) || db.get('accounts')[0];
    }
    if (!account) throw new Error('Mandate linked account not found.');

    const debitAmount = amountOverride && amountOverride > 0 ? amountOverride : mandate.maxAmount;
    if (account.balance < debitAmount) {
      account.balance = 25000.0; // demo auto-topup
    }

    account.balance = Number((account.balance - debitAmount).toFixed(2));
    db.update('accounts', (a) => a.id === account.id, { balance: account.balance });

    mandate.totalDebited = Number((mandate.totalDebited + debitAmount).toFixed(2));
    mandate.executionCount += 1;
    mandate.lastDebitAt = new Date().toISOString();
    db.update('autopayMandates', (m) => m.id === mandateId, {
      totalDebited: mandate.totalDebited,
      executionCount: mandate.executionCount,
      lastDebitAt: mandate.lastDebitAt,
    });

    const txnId = `txn_auto_${Date.now().toString(36)}`;
    const rrn = Math.floor(100000000000 + Math.random() * 900000000000).toString();

    db.insert('transactions', {
      id: txnId,
      txnRef: mandate.umrn,
      upiRrn: rrn,
      senderUserId: userId,
      senderAccountId: account.id,
      senderVpa: 'user@aiksetra',
      receiverVpa: mandate.vpa,
      receiverName: mandate.billerOrPayeeName,
      amount: debitAmount,
      currency: 'INR',
      txnType: 'P2M',
      status: 'SUCCESS',
      remark: `AutoPay Mandate Debit: ${mandate.billerOrPayeeName} (UMRN: ${mandate.umrn})`,
      metadata: { isAutoPay: true, mandateId: mandate.id, umrn: mandate.umrn },
      createdAt: new Date().toISOString(),
    });

    return {
      success: true,
      transactionId: txnId,
      newBalance: account.balance,
    };
  }
}
