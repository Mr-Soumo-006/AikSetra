import { db } from '../db/database.js';
import type { ScamShieldAnalysis, RiskLevel, VpaRecord } from '../types/index.js';

const URGENCY_SCAM_KEYWORDS = [
  'lottery',
  'winner',
  'kbc',
  'prize',
  'electricity cut',
  'bill update',
  'disconnection',
  'urgent',
  'emergency',
  'police fine',
  'customs clearance',
  'courier release',
  'telegram task',
  'part time job',
  'double money',
  'crypto investment',
  'activation fee',
  'refund claim',
];

export class ScamShieldService {
  public static analyzePaymentRisk(params: {
    senderUserId?: string;
    senderVpa: string;
    receiverVpa: string;
    amount: number;
    remark?: string;
    expectedPayeeName?: string;
  }): ScamShieldAnalysis {
    const { senderUserId, senderVpa, receiverVpa, amount, remark = '', expectedPayeeName } = params;

    const warnings: string[] = [];
    let riskScore = 0;

    // 1. Check Global Fraud Registry
    const fraudRegistry = db.get('fraudRegistry');
    const blacklisted = fraudRegistry.some(
      (f) => f.vpa.toLowerCase() === receiverVpa.toLowerCase()
    );

    if (blacklisted) {
      const match = fraudRegistry.find((f) => f.vpa.toLowerCase() === receiverVpa.toLowerCase());
      warnings.push(`🚨 STOP: This account was reported ${match?.reportCount || 'multiple'} times for scam (${match?.reason || 'fraud'}). Do NOT send money.`);
      riskScore += 95;
    }

    // 2. Lookup Payee details in VPA Registry
    const vpaList = db.get('vpas');
    const payeeRecord: VpaRecord | undefined = vpaList.find(
      (v) => v.vpa.toLowerCase() === receiverVpa.toLowerCase()
    );

    const verifiedLegalName = payeeRecord?.fullName || 'Verified Bank Account Holder';

    // 3. New Payee / Relationship History
    let newPayee = true;
    if (senderUserId) {
      const pastTxns = db.get('transactions').filter(
        (t) =>
          t.senderUserId === senderUserId &&
          t.receiverVpa.toLowerCase() === receiverVpa.toLowerCase() &&
          t.status === 'SUCCESS'
      );
      if (pastTxns.length > 0) {
        newPayee = false;
      }
    }

    if (newPayee && !payeeRecord?.isMerchant) {
      riskScore += 20;
      warnings.push('ℹ️ First time payment: You have never sent money to this person before. Double check the name.');
    }

    // Check account recency (< 72 hours old)
    if (payeeRecord) {
      const createdTime = new Date(payeeRecord.createdAt).getTime();
      const ageHours = (Date.now() - createdTime) / (1000 * 3600);
      if (ageHours < 72) {
        riskScore += 25;
        warnings.push('⚠️ Brand new account: This UPI ID was created less than 3 days ago. Be careful if paying an unknown person.');
      }
    }

    // 4. Urgency Keyword Analysis in Note/Remark
    const lowerRemark = remark.toLowerCase();
    const detectedKeywords: string[] = [];
    for (const kw of URGENCY_SCAM_KEYWORDS) {
      if (lowerRemark.includes(kw)) {
        detectedKeywords.push(kw);
      }
    }

    if (detectedKeywords.length > 0) {
      riskScore += 35;
      warnings.push(
        `⚠️ Fake Urgency Alert: Scammers often pressure people with threats like "urgent", "electricity disconnection", or "lottery fee". Please verify with official numbers first.`
      );
    }

    // 5. Payee Name Mismatch
    let nameMismatchDetected = false;
    if (expectedPayeeName && payeeRecord?.fullName) {
      const exp = expectedPayeeName.toLowerCase().replace(/[^a-z0-9]/g, '');
      const actual = payeeRecord.fullName.toLowerCase().replace(/[^a-z0-9]/g, '');

      if (!actual.includes(exp) && !exp.includes(actual)) {
        nameMismatchDetected = true;
        riskScore += 30;
        warnings.push(
          `⚠️ Name mismatch: You expected "${expectedPayeeName}", but the real bank account name is "${payeeRecord.fullName}".`
        );
      }
    }

    // 6. Unusual Amount Checks
    let unusualAmount = false;
    if (amount > 25000 && newPayee) {
      unusualAmount = true;
      riskScore += 15;
      warnings.push(`⚠️ Large transfer (₹${amount.toLocaleString('en-IN')}): Make sure you personally know this recipient.`);
    }

    // Cap risk score between 0 and 100
    riskScore = Math.min(100, Math.max(0, riskScore));

    let riskLevel: RiskLevel = 'SAFE';
    let recommendation: ScamShieldAnalysis['recommendation'] = 'PROCEED';
    let coolingOffRequired = false;
    let coolingOffSeconds = 0;

    if (riskScore >= 75) {
      riskLevel = 'HIGH';
      recommendation = blacklisted ? 'BLOCK' : 'REQUIRE_COOLING_OFF';
      coolingOffRequired = true;
      coolingOffSeconds = 300; // 5 minute protection
    } else if (riskScore >= 40) {
      riskLevel = 'MODERATE';
      recommendation = 'WARN_USER';
    } else if (riskScore >= 15) {
      riskLevel = 'LOW';
      recommendation = 'PROCEED';
    }

    return {
      riskScore,
      riskLevel,
      warnings,
      signals: {
        newPayee,
        unusualAmount,
        urgencyKeywordsDetected: detectedKeywords,
        nameMismatch: {
          detected: nameMismatchDetected,
          enteredName: expectedPayeeName,
          verifiedLegalName: payeeRecord?.fullName,
        },
        blacklisted,
        coolingOffRequired,
        coolingOffSeconds,
      },
      recommendation,
      verifiedLegalName,
    };
  }

  public static reportFraud(params: {
    vpa: string;
    phone?: string;
    reason: string;
    reportedByUserId: string;
  }): { success: boolean; message: string } {
    const fraudList = db.get('fraudRegistry');
    const existing = fraudList.find((f) => f.vpa.toLowerCase() === params.vpa.toLowerCase());

    if (existing) {
      existing.reportCount += 1;
      existing.flaggedAt = new Date().toISOString();
      db.save();
    } else {
      db.insert('fraudRegistry', {
        vpa: params.vpa,
        phone: params.phone,
        reportCount: 1,
        reason: params.reason,
        flaggedAt: new Date().toISOString(),
      });
    }

    // Also update VPA trust score if registered in system
    const vpaList = db.get('vpas');
    const vpaRecord = vpaList.find((v) => v.vpa.toLowerCase() === params.vpa.toLowerCase());
    if (vpaRecord) {
      vpaRecord.fraudReportCount += 1;
      vpaRecord.trustScore = Math.max(0, vpaRecord.trustScore - 25);
      db.save();
    }

    return {
      success: true,
      message: 'Fraud report successfully registered with Scam Shield. Payee trust score updated.',
    };
  }
}
