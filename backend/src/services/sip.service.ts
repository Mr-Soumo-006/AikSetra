import { v4 as uuidv4 } from 'uuid';
import { db } from '../db/database.js';
import { AuthService } from './auth.service.js';

export interface SipPlan {
  id: string;
  name: string;
  amcOrIssuer: string;
  category: string;
  cagr3Y: number;
  minMonthlyAmount: number;
  riskLevel: 'Low' | 'Low-Moderate' | 'Moderate' | 'High Growth';
  navOrUnitPrice: number;
  vpa: string;
  description: string;
}

export interface UserSipMandate {
  id: string;
  userId: string;
  accountId: string;
  bankName: string;
  planId: string;
  planName: string;
  category: string;
  cagr3Y: number;
  monthlyAmount: number;
  debitDay: number;
  installmentsPaid: number;
  totalInvested: number;
  currentValue: number;
  unitsHeld: number;
  umrn: string; // NPCI NACH Mandate Reference Number
  status: 'ACTIVE' | 'PAUSED' | 'REDEEMED';
  nextDebitDate: string;
  createdAt: string;
}

export const SIP_PLANS: SipPlan[] = [
  {
    id: 'sip_nifty50',
    name: 'SBI Nifty 50 Index Direct Growth',
    amcOrIssuer: 'SBI Mutual Fund (Direct Plan)',
    category: 'Index Equity',
    cagr3Y: 15.6,
    minMonthlyAmount: 500,
    riskLevel: 'Moderate',
    navOrUnitPrice: 214.8,
    vpa: 'sbinifty50.sip@aiksetra',
    description: 'Invests in India’s top 50 bluechip companies (Reliance, TCS, HDFC, Infosys) with 0.18% expense ratio.',
  },
  {
    id: 'sip_hdfc_flexi',
    name: 'HDFC Flexi Cap Direct Growth',
    amcOrIssuer: 'HDFC Asset Management',
    category: 'Flexi Cap Equity',
    cagr3Y: 19.4,
    minMonthlyAmount: 500,
    riskLevel: 'High Growth',
    navOrUnitPrice: 1842.5,
    vpa: 'hdfcflexi.sip@aiksetra',
    description: 'Dynamic allocation across large, mid, and small-cap Indian leaders for long-term wealth compounding.',
  },
  {
    id: 'sip_icici_bluechip',
    name: 'ICICI Prudential Bluechip Direct',
    amcOrIssuer: 'ICICI Prudential AMC',
    category: 'Large Cap Equity',
    cagr3Y: 16.8,
    minMonthlyAmount: 500,
    riskLevel: 'Moderate',
    navOrUnitPrice: 108.4,
    vpa: 'icicibluechip.sip@aiksetra',
    description: 'Consistent compounder focused on established market leaders with strong dividend & cash flows.',
  },
  {
    id: 'sip_gold_24k',
    name: 'MMTC-PAMP 24K Digital Gold Auto-SIP',
    amcOrIssuer: 'MMTC-PAMP Sovereign Vault',
    category: '24K Pure Gold (99.9%)',
    cagr3Y: 14.2,
    minMonthlyAmount: 100,
    riskLevel: 'Low-Moderate',
    navOrUnitPrice: 7850.0,
    vpa: 'gold24k.sip@aiksetra',
    description: 'Accumulate physical 999.9purity 24K gold in insured bank vaults automatically every month.',
  },
  {
    id: 'sip_rbi_liquid',
    name: 'SBI Magnum Govt Treasury & Liquid SIP',
    amcOrIssuer: 'SBI Mutual Fund • Sovereign T-Bills',
    category: 'Sovereign Debt / Liquid',
    cagr3Y: 7.45,
    minMonthlyAmount: 500,
    riskLevel: 'Low',
    navOrUnitPrice: 3910.0,
    vpa: 'sbiliquid.sip@aiksetra',
    description: 'Backed by Government of India Treasury Bills with instant T+0 bank redemption and zero lock-in.',
  },
];

export class SipService {
  private static userSips: UserSipMandate[] = [];

  private static getSipList(): UserSipMandate[] {
    // Populate from recorded transactions if memory cache is empty
    if (this.userSips.length === 0) {
      try {
        const txns = db.get('transactions') || [];
        for (const t of txns) {
          const meta = t.metadata;
          if (meta && meta.isSip && meta.sipId) {
            const sipId = meta.sipId as string;
            const alreadyIn = this.userSips.some((s) => s.id === sipId);
            if (!alreadyIn) {
              const plan = SIP_PLANS.find((p) => p.name === meta.planName) || SIP_PLANS[0];
              this.userSips.push({
                id: sipId,
                userId: t.senderUserId || 'user',
                accountId: t.senderAccountId || 'acc_primary',
                bankName: 'State Bank of India (•••• 3038)',
                planId: plan.id,
                planName: plan.name,
                category: plan.category,
                cagr3Y: plan.cagr3Y,
                monthlyAmount: t.amount,
                debitDay: 5,
                installmentsPaid: 1,
                totalInvested: t.amount,
                currentValue: Number((t.amount * 1.02).toFixed(2)),
                unitsHeld: Number((t.amount / plan.navOrUnitPrice).toFixed(4)),
                umrn: (meta.umrn as string) || t.txnRef,
                status: 'ACTIVE',
                nextDebitDate: new Date(Date.now() + 30 * 86400000).toISOString().split('T')[0],
                createdAt: t.createdAt,
              });
            }
          }
        }
      } catch (_) {}
    }
    return this.userSips;
  }

  public static getPlansAndPortfolio(userId: string) {
    const allSips = this.getSipList().filter((s) => s.userId === userId && s.status !== 'REDEEMED');
    let totalInvested = 0;
    let currentValue = 0;

    for (const s of allSips) {
      totalInvested += s.totalInvested;
      currentValue += s.currentValue;
    }

    const totalReturns = Number((currentValue - totalInvested).toFixed(2));
    const returnPct = totalInvested > 0 ? Number(((totalReturns / totalInvested) * 100).toFixed(2)) : 0;

    return {
      plans: SIP_PLANS,
      mySips: allSips,
      portfolio: {
        totalInvested: Number(totalInvested.toFixed(2)),
        currentValue: Number(currentValue.toFixed(2)),
        totalReturns,
        returnPct,
        activeMandatesCount: allSips.length,
      },
    };
  }

  public static createSipMandate(params: {
    userId: string;
    planId: string;
    monthlyAmount: number;
    debitDay: number;
    mpin: string;
  }) {
    const { userId, planId, monthlyAmount, debitDay = 5, mpin } = params;

    if (!AuthService.verifyMpin(userId, mpin)) {
      throw new Error('Incorrect 4-digit UPI MPIN.');
    }

    // Resilient plan resolution: handles 'sip_bluechip', 'sip_icici_bluechip', stock SIPs, and defaults safely
    let plan = SIP_PLANS.find((p) => p.id === planId || p.id === `sip_${planId}` || planId.includes(p.id.replace('sip_', '')));
    if (!plan && (planId === 'sip_bluechip' || planId.includes('bluechip'))) {
      plan = SIP_PLANS.find((p) => p.id === 'sip_icici_bluechip') || SIP_PLANS[0];
    }
    if (!plan) {
      plan = SIP_PLANS[0]; // Guaranteed fallback to SBI Nifty 50 Index
    }

    const user = db.get('users').find((u) => u.id === userId);
    if (!user) throw new Error('User not found.');

    const accounts = db.get('accounts').filter((a) => a.userId === userId);
    const account = accounts.find((a) => a.isPrimary) || accounts[0];
    if (!account) throw new Error('No linked bank account found for SIP Auto-Debit.');

    // In demo mode: automatically ensure spendable balance so presentation never blocks
    const isDemo = process.env.ENABLE_DEMO_FAUCET === 'true' || process.env.NODE_ENV !== 'production';
    if (account.balance < monthlyAmount) {
      if (isDemo) {
        account.balance = 25000.0;
        db.update('accounts', (a) => a.id === account.id, { balance: 25000.0 });
      } else {
        throw new Error(
          `Insufficient bank balance (₹${account.balance.toFixed(2)}) for 1st SIP installment of ₹${monthlyAmount.toFixed(2)}.`
        );
      }
    }

    // Deduct 1st installment immediately
    account.balance = Number((account.balance - monthlyAmount).toFixed(2));
    db.update('accounts', (a) => a.id === account.id, { balance: account.balance });

    const now = new Date();
    const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, Math.min(28, Math.max(1, debitDay)));
    const umrn = `NPCI${account.bankCode}${Date.now().toString().slice(-10)}`;
    const unitsAllotted = Number((monthlyAmount / plan.navOrUnitPrice).toFixed(4));
    // Apply initial realistic NAV appreciation (+1.2% initial mark-to-market)
    const initialCurrentVal = Number((monthlyAmount * (1 + plan.cagr3Y / 1200)).toFixed(2));

    const sipMandate: UserSipMandate = {
      id: `sip_${uuidv4().replace(/-/g, '').slice(0, 10)}`,
      userId,
      accountId: account.id,
      bankName: `${account.bankName} (${account.maskedAccountNumber})`,
      planId: plan.id,
      planName: plan.name,
      category: plan.category,
      cagr3Y: plan.cagr3Y,
      monthlyAmount: Number(monthlyAmount.toFixed(2)),
      debitDay,
      installmentsPaid: 1,
      totalInvested: Number(monthlyAmount.toFixed(2)),
      currentValue: initialCurrentVal,
      unitsHeld: unitsAllotted,
      umrn,
      status: 'ACTIVE',
      nextDebitDate: nextMonth.toISOString().split('T')[0],
      createdAt: now.toISOString(),
    };

    this.getSipList().unshift(sipMandate);

    const rrn = Math.floor(100000000000 + Math.random() * 900000000000).toString();
    const transaction = {
      id: `txn_sip_${uuidv4().replace(/-/g, '').slice(0, 10)}`,
      txnRef: umrn,
      upiRrn: rrn,
      senderUserId: userId,
      senderAccountId: account.id,
      senderVpa: user.primaryVpa,
      receiverVpa: plan.vpa,
      receiverName: plan.name,
      amount: Number(monthlyAmount.toFixed(2)),
      currency: 'INR',
      txnType: 'P2M' as const,
      status: 'SUCCESS' as const,
      remark: `Bank SIP 1st Installment • ${plan.name} (UMRN: ${umrn})`,
      createdAt: now.toISOString(),
      metadata: {
        isSip: true,
        sipId: sipMandate.id,
        planName: plan.name,
        umrn,
        unitsAllotted,
      },
    };

    db.insert('transactions', transaction as any);
    db.save();

    console.log(`\n📈 [AIKSETRA BANK AUTO-SIP MANDATE CREATED]`);
    console.log(`   Investor : ${user.fullName} | Bank: ${account.bankName}`);
    console.log(`   Fund     : ${plan.name} (${plan.cagr3Y}% 3Y CAGR)`);
    console.log(`   1st Inst.: ₹${monthlyAmount.toFixed(2)} | Units: ${unitsAllotted} | UMRN: ${umrn}`);
    console.log(`   Balance  : ₹${account.balance.toFixed(2)}\n`);

    return {
      success: true,
      sip: sipMandate,
      transaction,
      updatedBalance: account.balance,
    };
  }

  public static payAdditionalInstallment(params: {
    userId: string;
    sipId: string;
    amount?: number;
    mpin: string;
  }) {
    const { userId, sipId, amount, mpin } = params;

    if (!AuthService.verifyMpin(userId, mpin)) {
      throw new Error('Incorrect 4-digit UPI MPIN.');
    }

    const sips = this.getSipList();
    const sip = sips.find((s) => s.id === sipId && s.userId === userId);
    if (!sip) throw new Error('SIP Mandate not found.');

    const payAmount = amount && amount > 0 ? amount : sip.monthlyAmount;
    const accounts = db.get('accounts').filter((a) => a.userId === userId);
    const account = accounts.find((a) => a.id === sip.accountId) || accounts.find((a) => a.isPrimary) || accounts[0];
    if (!account) throw new Error('Linked bank account not found.');

    if (account.balance < payAmount) {
      throw new Error(`Insufficient bank balance (₹${account.balance.toFixed(2)}) for SIP installment of ₹${payAmount.toFixed(2)}.`);
    }

    const user = db.get('users').find((u) => u.id === userId);
    const plan = SIP_PLANS.find((p) => p.id === sip.planId) || SIP_PLANS[0];

    account.balance = Number((account.balance - payAmount).toFixed(2));
    db.update('accounts', (a) => a.id === account.id, { balance: account.balance });
    const addedUnits = Number((payAmount / plan.navOrUnitPrice).toFixed(4));
    sip.installmentsPaid += 1;
    sip.totalInvested = Number((sip.totalInvested + payAmount).toFixed(2));
    sip.unitsHeld = Number((sip.unitsHeld + addedUnits).toFixed(4));
    // Simulate compounding growth on portfolio
    const growthFactor = 1 + plan.cagr3Y / 1000;
    sip.currentValue = Number(((sip.currentValue + payAmount) * growthFactor).toFixed(2));

    const rrn = Math.floor(100000000000 + Math.random() * 900000000000).toString();
    const transaction = {
      id: `txn_sip_${uuidv4().replace(/-/g, '').slice(0, 10)}`,
      txnRef: sip.umrn,
      upiRrn: rrn,
      senderUserId: userId,
      senderAccountId: account.id,
      senderVpa: user?.primaryVpa || 'user@aiksetra',
      receiverVpa: plan.vpa,
      receiverName: sip.planName,
      amount: Number(payAmount.toFixed(2)),
      currency: 'INR',
      txnType: 'P2M' as const,
      status: 'SUCCESS' as const,
      remark: `SIP Installment #${sip.installmentsPaid} • ${sip.planName}`,
      createdAt: new Date().toISOString(),
      metadata: {
        isSip: true,
        sipId: sip.id,
        planName: sip.planName,
        umrn: sip.umrn,
      },
    };

    db.insert('transactions', transaction as any);
    db.save();

    return {
      success: true,
      sip,
      transaction,
      updatedBalance: account.balance,
    };
  }

  public static redeemSipToBank(params: { userId: string; sipId: string; mpin: string }) {
    const { userId, sipId, mpin } = params;

    if (!AuthService.verifyMpin(userId, mpin)) {
      throw new Error('Incorrect 4-digit UPI MPIN.');
    }

    const sips = this.getSipList();
    const sip = sips.find((s) => s.id === sipId && s.userId === userId && s.status !== 'REDEEMED');
    if (!sip) throw new Error('Active SIP not found.');

    const accounts = db.get('accounts').filter((a) => a.userId === userId);
    const account = accounts.find((a) => a.id === sip.accountId) || accounts.find((a) => a.isPrimary) || accounts[0];
    if (!account) throw new Error('Linked bank account not found.');

    const user = db.get('users').find((u) => u.id === userId);
    const payoutAmount = sip.currentValue;
    account.balance = Number((account.balance + payoutAmount).toFixed(2));
    db.update('accounts', (a) => a.id === account.id, { balance: account.balance });
    sip.status = 'REDEEMED';

    const rrn = Math.floor(100000000000 + Math.random() * 900000000000).toString();
    const transaction = {
      id: `txn_sip_red_${uuidv4().replace(/-/g, '').slice(0, 10)}`,
      txnRef: `RED-${sip.umrn}`,
      upiRrn: rrn,
      senderUserId: 'amc_settlement_desk',
      senderAccountId: 'acc_amc_pool',
      senderVpa: 'redemption.amc@aiksetra',
      receiverVpa: user?.primaryVpa || 'user@aiksetra',
      receiverName: user?.fullName || 'Investor',
      amount: Number(payoutAmount.toFixed(2)),
      currency: 'INR',
      txnType: 'P2P' as const,
      status: 'SUCCESS' as const,
      remark: `SIP Redemption Credited • ${sip.planName}`,
      createdAt: new Date().toISOString(),
      metadata: {
        isSipRedemption: true,
        isCredit: true,
        sipId: sip.id,
        planName: sip.planName,
      },
    };

    db.insert('transactions', transaction as any);
    db.save();

    console.log(`\n🏦 [AIKSETRA SIP REDEMPTION CREDITED TO BANK]`);
    console.log(`   Fund     : ${sip.planName}`);
    console.log(`   Credited : +₹${payoutAmount.toFixed(2)} -> ${account.bankName}`);
    console.log(`   Balance  : ₹${account.balance.toFixed(2)}\n`);

    return {
      success: true,
      creditedAmount: payoutAmount,
      updatedBalance: account.balance,
      transaction,
    };
  }
}
