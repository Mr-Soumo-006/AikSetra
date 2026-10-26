import { v4 as uuidv4 } from 'uuid';
import { db } from '../db/database.js';
import { AuthService } from './auth.service.js';
import { soundboxService } from './soundbox.service.js';

export interface BillerInfo {
  id: string;
  name: string;
  category: 'ELECTRICITY' | 'WATER' | 'GAS' | 'BROADBAND' | 'MOBILE' | 'DTH' | 'FASTAG';
  stateOrCircle: string;
  vpa: string;
  consumerIdLabel: string;
  sampleConsumerId: string;
}

export const BBPS_BILLERS: BillerInfo[] = [
  // Electricity
  {
    id: 'elec_cesc',
    name: 'CESC Limited (Kolkata)',
    category: 'ELECTRICITY',
    stateOrCircle: 'West Bengal',
    vpa: 'cesc.bbps@aiksetra',
    consumerIdLabel: '11-Digit Consumer Number',
    sampleConsumerId: '19002847561',
  },
  {
    id: 'elec_wbsedcl',
    name: 'WBSEDCL Electricity',
    category: 'ELECTRICITY',
    stateOrCircle: 'West Bengal',
    vpa: 'wbsedcl.bbps@aiksetra',
    consumerIdLabel: '9-Digit Consumer ID',
    sampleConsumerId: '400291847',
  },
  {
    id: 'elec_tatapower',
    name: 'Tata Power Electricity',
    category: 'ELECTRICITY',
    stateOrCircle: 'Mumbai / Delhi / Pan-India',
    vpa: 'tatapower.bbps@aiksetra',
    consumerIdLabel: 'CA Number',
    sampleConsumerId: '9001827364',
  },
  {
    id: 'elec_bescom',
    name: 'BESCOM Bengaluru',
    category: 'ELECTRICITY',
    stateOrCircle: 'Karnataka',
    vpa: 'bescom.bbps@aiksetra',
    consumerIdLabel: 'Account ID (10 Digits)',
    sampleConsumerId: '5182930411',
  },
  // Water
  {
    id: 'water_kmc',
    name: 'Kolkata Municipal Water (KMC)',
    category: 'WATER',
    stateOrCircle: 'West Bengal',
    vpa: 'kmcwater.bbps@aiksetra',
    consumerIdLabel: 'Assessee / Consumer No',
    sampleConsumerId: '1104928374',
  },
  {
    id: 'water_djb',
    name: 'Delhi Jal Board (DJB)',
    category: 'WATER',
    stateOrCircle: 'Delhi NCR',
    vpa: 'djbwater.bbps@aiksetra',
    consumerIdLabel: 'KNO Number',
    sampleConsumerId: '7201938475',
  },
  {
    id: 'water_bwssb',
    name: 'BWSSB Water Supply',
    category: 'WATER',
    stateOrCircle: 'Bengaluru',
    vpa: 'bwssb.bbps@aiksetra',
    consumerIdLabel: 'RR Number',
    sampleConsumerId: 'RR928371',
  },
  // Piped Gas & LPG Cylinder
  {
    id: 'gas_indane',
    name: 'Indane Gas (IndianOil LPG)',
    category: 'GAS',
    stateOrCircle: 'Pan-India',
    vpa: 'indanegas.bbps@aiksetra',
    consumerIdLabel: 'LPG ID / Registered Mobile',
    sampleConsumerId: '9830113038',
  },
  {
    id: 'gas_bharat',
    name: 'Bharat Gas (BPCL LPG)',
    category: 'GAS',
    stateOrCircle: 'Pan-India',
    vpa: 'bharatgas.bbps@aiksetra',
    consumerIdLabel: 'Consumer No / Mobile',
    sampleConsumerId: '7192837465',
  },
  {
    id: 'gas_igl',
    name: 'IGL Piped Natural Gas',
    category: 'GAS',
    stateOrCircle: 'NCR / Metro',
    vpa: 'iglpng.bbps@aiksetra',
    consumerIdLabel: 'BP Number',
    sampleConsumerId: '4001928374',
  },
  // Broadband
  {
    id: 'bb_jiofiber',
    name: 'JioFiber Broadband',
    category: 'BROADBAND',
    stateOrCircle: 'Pan-India',
    vpa: 'jiofiber.bbps@aiksetra',
    consumerIdLabel: 'JioFiber Landline / Service ID',
    sampleConsumerId: '03329184756',
  },
  {
    id: 'bb_airtel',
    name: 'Airtel Xstream Fiber',
    category: 'BROADBAND',
    stateOrCircle: 'Pan-India',
    vpa: 'airtelfiber.bbps@aiksetra',
    consumerIdLabel: 'Account No / Landline ID',
    sampleConsumerId: '03340192837',
  },
  // Mobile Recharge / Postpaid
  {
    id: 'mob_jio',
    name: 'Jio 5G Mobile Recharge',
    category: 'MOBILE',
    stateOrCircle: 'All India 5G',
    vpa: 'jiorecharge.bbps@aiksetra',
    consumerIdLabel: '10-Digit Mobile Number',
    sampleConsumerId: '9830113038',
  },
  {
    id: 'mob_airtel',
    name: 'Airtel 5G Plus Recharge',
    category: 'MOBILE',
    stateOrCircle: 'All India 5G',
    vpa: 'airtelrecharge.bbps@aiksetra',
    consumerIdLabel: '10-Digit Mobile Number',
    sampleConsumerId: '9830113038',
  },
  // FASTag & DTH
  {
    id: 'fastag_nhai',
    name: 'NHAI / IHMCL FASTag Recharge',
    category: 'FASTAG',
    stateOrCircle: 'National Highways',
    vpa: 'fastag.bbps@aiksetra',
    consumerIdLabel: 'Vehicle Registration Number',
    sampleConsumerId: 'WB02AK4921',
  },
  {
    id: 'dth_tataplay',
    name: 'Tata Play DTH',
    category: 'DTH',
    stateOrCircle: 'Pan-India',
    vpa: 'tataplay.bbps@aiksetra',
    consumerIdLabel: '10-Digit Subscriber ID',
    sampleConsumerId: '1092837465',
  },
];

export class BillPayService {
  public static getBillers(category?: string) {
    if (!category) return BBPS_BILLERS;
    return BBPS_BILLERS.filter((b) => b.category.toUpperCase() === category.toUpperCase());
  }

  public static fetchBillDetails(params: {
    userId: string;
    billerId: string;
    consumerNumber: string;
  }) {
    const { userId, billerId, consumerNumber } = params;
    const cleanConsumer = consumerNumber.trim();
    if (cleanConsumer.length < 4) {
      throw new Error('Please enter a valid Consumer / Account / Vehicle Number.');
    }

    const biller = BBPS_BILLERS.find((b) => b.id === billerId) || BBPS_BILLERS[0];
    const user = db.get('users').find((u) => u.id === userId);
    const consumerName = user?.fullName || 'Verified Consumer';

    // Deterministic realistic bill amount from consumer number digits
    let seed = 0;
    for (let i = 0; i < cleanConsumer.length; i++) {
      seed = (seed * 31 + cleanConsumer.charCodeAt(i)) % 10000;
    }

    let amount = 450;
    let planOrUsage = 'Monthly Billing Cycle';
    let unitsConsumed: number | undefined;
    let energyCharges: number | undefined;
    let fixedCharge: number | undefined;
    let electricityDuty: number | undefined;
    let meterNumber: string | undefined;

    if (biller.category === 'ELECTRICITY') {
      unitsConsumed = 110 + (seed % 240);
      energyCharges = Number((unitsConsumed * 6.50).toFixed(2));
      fixedCharge = 75.00;
      electricityDuty = Number(((energyCharges + fixedCharge) * 0.06).toFixed(2));
      amount = Math.round(energyCharges + fixedCharge + electricityDuty);
      meterNumber = `WB-MTR-${seed + 10492}`;
      planOrUsage = `${unitsConsumed} kWh • Slabs: 0-100 @₹5.50, >100 @₹7.20 + ₹75 Fixed + 6% Duty`;
    } else if (biller.category === 'WATER') {
      const kl = 12 + (seed % 18);
      amount = Math.round(kl * 24);
      planOrUsage = `${kl} kL Municipal Water Supply`;
    } else if (biller.category === 'GAS') {
      amount = biller.id.includes('igl') ? 640 + (seed % 400) : 829;
      planOrUsage = biller.id.includes('igl') ? 'Piped Natural Gas Monthly Meter' : '14.2 Kg Domestic LPG Refill';
    } else if (biller.category === 'BROADBAND') {
      const plans = [589, 825, 1179];
      amount = plans[seed % plans.length];
      planOrUsage = amount === 589 ? '100 Mbps Unlimited Fiber + GST' : amount === 825 ? '150 Mbps + OTT Bundle + GST' : '300 Mbps Pro Fiber + GST';
    } else if (biller.category === 'MOBILE') {
      const plans = [299, 349, 749, 899];
      amount = plans[seed % plans.length];
      planOrUsage = `${amount === 299 ? '1.5GB/Day • 28 Days' : amount === 349 ? '2GB/Day Unlimited 5G • 28 Days' : '2GB/Day Unlimited 5G • 84 Days'}`;
    } else if (biller.category === 'FASTAG') {
      amount = 500;
      planOrUsage = `Vehicle ${cleanConsumer.toUpperCase()} Toll Wallet Top-up`;
    } else {
      amount = 350 + (seed % 200);
      planOrUsage = 'HD Family Sports & Entertainment Pack';
    }

    const now = new Date();
    const dueDate = new Date(now.getTime() + 5 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const billPeriod = now.toLocaleString('en-IN', { month: 'short', year: 'numeric' });
    const billNumber = `BBPS-${biller.category.slice(0, 3)}-${cleanConsumer.slice(-4).toUpperCase()}-${now.getMonth() + 1}${now.getFullYear()}`;

    // Check if already paid in transactions
    const alreadyPaid = db.get('transactions').find(
      (t) =>
        t.senderUserId === userId &&
        t.status === 'SUCCESS' &&
        (t as any).metadata?.billNumber === billNumber
    );

    return {
      billerId: biller.id,
      billerName: biller.name,
      category: biller.category,
      vpa: biller.vpa,
      consumerNumber: cleanConsumer,
      consumerName,
      billNumber,
      billPeriod,
      dueDate,
      planOrUsage,
      amount,
      unitsConsumed,
      energyCharges,
      fixedCharge,
      electricityDuty,
      meterNumber,
      alreadyPaid: !!alreadyPaid,
      paidTxnId: alreadyPaid?.id,
    };
  }

  public static payBill(params: {
    userId: string;
    billerId: string;
    consumerNumber: string;
    amount: number;
    mpin: string;
    billNumber?: string;
    planOrUsage?: string;
  }) {
    const { userId, billerId, consumerNumber, amount, mpin, billNumber, planOrUsage } = params;

    if (!AuthService.verifyMpin(userId, mpin)) {
      throw new Error('Incorrect 4-digit UPI MPIN.');
    }

    const user = db.get('users').find((u) => u.id === userId);
    if (!user) throw new Error('User not found.');

    const accounts = db.get('accounts').filter((a) => a.userId === userId);
    const account = accounts.find((a) => a.isPrimary) || accounts[0];
    if (!account) throw new Error('No linked bank account found.');

    if (account.balance < amount) {
      throw new Error(`Insufficient bank balance (₹${account.balance.toFixed(2)}) to pay bill of ₹${amount.toFixed(2)}.`);
    }

    const biller = BBPS_BILLERS.find((b) => b.id === billerId) || {
      id: billerId,
      name: 'BBPS Utility Biller',
      category: 'ELECTRICITY',
      vpa: 'biller.bbps@aiksetra',
    };

    // Deduct from real bank account
    account.balance = Number((account.balance - amount).toFixed(2));
    db.update('accounts', (a) => a.id === account.id, { balance: account.balance });

    const rrn = Math.floor(100000000000 + Math.random() * 900000000000).toString();
    const bbpsRef = `BBPS${Date.now().toString().slice(-8)}IN`;
    const now = new Date().toISOString();

    const transaction = {
      id: `txn_bbps_${uuidv4().replace(/-/g, '').slice(0, 10)}`,
      txnRef: bbpsRef,
      upiRrn: rrn,
      senderUserId: userId,
      senderAccountId: account.id,
      senderVpa: user.primaryVpa,
      receiverVpa: biller.vpa,
      receiverName: biller.name,
      amount: Number(amount.toFixed(2)),
      currency: 'INR',
      txnType: 'P2M' as const,
      status: 'SUCCESS' as const,
      remark: `${biller.category} Bill • ${biller.name} (${consumerNumber})`,
      createdAt: now,
      metadata: {
        isBbpsBill: true,
        category: biller.category,
        billerId: biller.id,
        billerName: biller.name,
        consumerNumber,
        billNumber: billNumber || bbpsRef,
        planOrUsage: planOrUsage || biller.category,
        bbpsRef,
      },
    };

    db.insert('transactions', transaction as any);
    db.save();

    console.log(`\n🧾 [AIKSETRA BBPS UTILITY BILL SETTLEMENT]`);
    console.log(`   Biller   : ${biller.name} (${biller.category})`);
    console.log(`   Consumer : ${consumerNumber} (${user.fullName})`);
    console.log(`   Amount   : ₹${amount.toFixed(2)} | BBPS Ref: ${bbpsRef} | RRN: ${rrn}`);
    console.log(`   Balance  : ₹${account.balance.toFixed(2)}\n`);

    soundboxService.broadcastPayment({
      merchantId: 'merch_bbps',
      merchantName: biller.name,
      amount: Number(amount.toFixed(2)),
      currency: 'INR',
      payerName: user.fullName,
      payerVpa: user.primaryVpa,
      language: 'en',
    });

    return {
      success: true,
      transaction,
      bbpsRef,
      updatedBalance: account.balance,
    };
  }

  public static getUserBillHistory(userId: string) {
    return db
      .get('transactions')
      .filter((t) => t.senderUserId === userId && (t as any).metadata?.isBbpsBill)
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  }
}
