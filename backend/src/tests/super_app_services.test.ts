import test, { describe, it } from 'node:test';
import assert from 'node:assert';
import { db } from '../db/database.js';
import { AutoPayService } from '../services/autopay.service.js';
import { RewardsService } from '../services/rewards.service.js';
import { BusinessService } from '../services/business.service.js';
import { FinancialToolsService } from '../services/financialTools.service.js';

describe('Super-App Services: AutoPay, Rewards, Business & Tools', async () => {
  await db.init();

  it('1. AutoPay: Retrieves seeded mandates and summary', () => {
    const data = AutoPayService.getMandates('usr_simo_01');
    assert.ok(data.mandates.length >= 3, 'Should have seeded mandates');
    assert.ok(data.summary.activeCount >= 2, 'Should have active mandates');
    assert.ok(data.summary.monthlyCommitment > 0, 'Should have positive commitment');
  });

  it('2. AutoPay: Creates new mandate with MPIN authorization', () => {
    const res = AutoPayService.createMandate({
      userId: 'usr_simo_01',
      billerOrPayeeName: 'BSES Yamuna Power',
      vpa: 'bses.delhi@bbps',
      category: 'ELECTRICITY',
      frequency: 'MONTHLY',
      maxAmount: 1800,
      scheduledDay: 12,
      mpin: '123456',
    });
    assert.strictEqual(res.success, true);
    assert.ok(res.mandate.umrn.startsWith('NPCI'), 'Should have valid UMRN');
    assert.strictEqual(res.mandate.status, 'ACTIVE');
  });

  it('3. AutoPay: Pauses, resumes and executes mandate debit', () => {
    const mandates = AutoPayService.getMandates('usr_simo_01').mandates;
    const target = mandates[0];

    const pauseRes = AutoPayService.updateMandateStatus(target.id, 'usr_simo_01', 'PAUSED');
    assert.strictEqual(pauseRes.mandate.status, 'PAUSED');

    const resumeRes = AutoPayService.updateMandateStatus(target.id, 'usr_simo_01', 'ACTIVE');
    assert.strictEqual(resumeRes.mandate.status, 'ACTIVE');

    const debitRes = AutoPayService.executeMandateDebit(target.id, 'usr_simo_01', 250);
    assert.strictEqual(debitRes.success, true);
    assert.ok(debitRes.transactionId.startsWith('txn_auto_'));
  });

  it('4. Rewards: Retrieves overview, coins balance and coupons', () => {
    const res = RewardsService.getRewardsOverview('usr_simo_01');
    assert.ok(res.coinsBalance >= 500, 'Should have coins balance');
    assert.ok(res.totalCashbackInr > 0, 'Should have earned cashback');
    assert.ok(res.referralCode.startsWith('AIK'), 'Should have referral code');
    assert.ok(res.coupons.length >= 3, 'Should have discount coupons');
  });

  it('5. Business Mode: Retrieves profile, invoicing and stats', () => {
    const biz = BusinessService.getBusinessProfile('usr_simo_01');
    assert.strictEqual(biz.profile.verified, true);
    assert.ok(biz.todayStats.volume > 0, 'Today volume should be positive');
    assert.strictEqual(biz.monthlyStats.mdrFees, 0, 'UPI MDR must be zero');
    assert.ok(biz.staff.length >= 2, 'Should have staff members');

    const invoices = BusinessService.getInvoices('usr_simo_01');
    assert.ok(invoices.length >= 1, 'Should have invoice');

    const newInv = BusinessService.createInvoice({
      userId: 'usr_simo_01',
      customerName: 'Test Client',
      customerPhone: '+91 9999988888',
      items: [{ name: 'IT Consulting Service', qty: 2, unitPrice: 5000, gstRate: 18 }],
    });
    assert.strictEqual(newInv.subtotal, 10000);
    assert.strictEqual(newInv.gstTotal, 1800);
    assert.strictEqual(newInv.grandTotal, 11800);
  });

  it('6. Financial Tools: Accurate calculations for EMI, SIP, FD and Tax', () => {
    const rates = FinancialToolsService.getLiveRates();
    assert.ok(rates.rates['USD'].rate > 80, 'USD rate should be > 80');

    const emi = FinancialToolsService.calculateEmi(100000, 10, 12);
    assert.ok(emi.monthlyEmi > 8700 && emi.monthlyEmi < 8900, '1L at 10% for 12mo EMI approx 8791');

    const sip = FinancialToolsService.calculateSip(5000, 12, 1);
    assert.strictEqual(sip.totalInvested, 60000);
    assert.ok(sip.maturityAmount > 63000, 'SIP return should compound');

    const gst = FinancialToolsService.calculateGst(1000, 18, true);
    assert.strictEqual(gst.gstAmount, 180);
    assert.strictEqual(gst.cgst, 90);
    assert.strictEqual(gst.sgst, 90);
    assert.strictEqual(gst.totalAmount, 1180);

    const tax = FinancialToolsService.estimateIncomeTax(1200000);
    assert.strictEqual(tax.assessmentYear, '2025-26 (FY 2024-25)');
    assert.ok(tax.totalTaxPayable > 0);
  });
});
