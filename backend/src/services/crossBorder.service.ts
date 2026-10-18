import { v4 as uuidv4 } from 'uuid';
import { db } from '../db/database.js';
import { config } from '../config/index.js';
import type { CrossBorderQuote, CorridorType } from '../types/index.js';

interface CurrencyConfig {
  name: string;
  symbol: string;
  marketRate: number; // In INR per 1 foreign unit
  tier: CorridorType;
  partnerRail: string;
  isBilateralRupeeAgreement: boolean;
}

const SUPPORTED_CURRENCIES: Record<string, CurrencyConfig> = {
  AED: {
    name: 'UAE Dirham',
    symbol: 'د.إ',
    marketRate: 22.86,
    tier: 'RUPEE_FIRST_BILATERAL', // Local currency agreement between RBI & CBUAE
    partnerRail: 'NIPL - UAE AANI / Jaywan & Bilateral LC Rail',
    isBilateralRupeeAgreement: true,
  },
  SGD: {
    name: 'Singapore Dollar',
    symbol: 'S$',
    marketRate: 63.75,
    tier: 'TIER_1_NIPL',
    partnerRail: 'NIPL - Singapore PayNow Interlink',
    isBilateralRupeeAgreement: false,
  },
  EUR: {
    name: 'Euro',
    symbol: '€',
    marketRate: 91.4,
    tier: 'TIER_1_NIPL',
    partnerRail: 'NIPL - Lyra Network France / Eurozone',
    isBilateralRupeeAgreement: false,
  },
  MUR: {
    name: 'Mauritian Rupee',
    symbol: '₨',
    marketRate: 1.82,
    tier: 'RUPEE_FIRST_BILATERAL',
    partnerRail: 'NIPL - MauCAS Bilateral Local Currency Settlement',
    isBilateralRupeeAgreement: true,
  },
  NPR: {
    name: 'Nepalese Rupee',
    symbol: 'रू',
    marketRate: 0.625,
    tier: 'TIER_1_NIPL',
    partnerRail: 'NIPL - Fonepay Nepal UPI Interlink',
    isBilateralRupeeAgreement: false,
  },
  BTN: {
    name: 'Bhutanese Ngultrum',
    symbol: 'Nu.',
    marketRate: 1.0, // Pegged at parity 1:1
    tier: 'TIER_1_NIPL',
    partnerRail: 'NIPL - Royal Monetary Authority of Bhutan',
    isBilateralRupeeAgreement: false,
  },
  USD: {
    name: 'US Dollar',
    symbol: '$',
    marketRate: 83.95,
    tier: 'TIER_2_AD_BANK',
    partnerRail: 'Partner AD Category-I Bank Outward Remittance Network',
    isBilateralRupeeAgreement: false,
  },
  GBP: {
    name: 'British Pound',
    symbol: '£',
    marketRate: 107.8,
    tier: 'TIER_2_AD_BANK',
    partnerRail: 'Partner AD Category-I Bank Faster Payments Network',
    isBilateralRupeeAgreement: false,
  },
  CAD: {
    name: 'Canadian Dollar',
    symbol: 'CA$',
    marketRate: 61.2,
    tier: 'TIER_2_AD_BANK',
    partnerRail: 'Partner AD Category-I Bank Interac Remittance Rail',
    isBilateralRupeeAgreement: false,
  },
  AUD: {
    name: 'Australian Dollar',
    symbol: 'A$',
    marketRate: 55.4,
    tier: 'TIER_2_AD_BANK',
    partnerRail: 'Partner AD Category-I Bank NPP Payout Rail',
    isBilateralRupeeAgreement: false,
  },
};

export class CrossBorderService {
  private static activeRateLocks: Map<string, CrossBorderQuote> = new Map();

  public static getSupportedCurrencies() {
    return Object.entries(SUPPORTED_CURRENCIES).map(([code, details]) => ({
      code,
      ...details,
    }));
  }

  public static generateQuote(params: {
    userId: string;
    targetCurrency: string;
    targetAmount?: number;
    sourceAmountInr?: number;
  }): CrossBorderQuote {
    const { userId, targetCurrency, targetAmount, sourceAmountInr } = params;
    const currencyInfo = SUPPORTED_CURRENCIES[targetCurrency.toUpperCase()];

    if (!currencyInfo) {
      throw new Error(`Currency ${targetCurrency} is not currently supported.`);
    }

    // Check user LRS status
    const users = db.get('users');
    const user = users.find((u) => u.id === userId);
    const lrsUsedUsd = user ? user.lrsUsedUsd : 0;
    const lrsLimitRemainingUsd = Math.max(0, config.lrsAnnualLimitUsd - lrsUsedUsd);

    // Spread calculation: 0.45% for Rupee-First / NIPL corridors, 0.75% for Tier 2 AD bank
    const spreadPct = currencyInfo.tier === 'RUPEE_FIRST_BILATERAL' ? 0.0035 : currencyInfo.tier === 'TIER_1_NIPL' ? 0.005 : 0.0075;
    const effectiveRate = Number((currencyInfo.marketRate * (1 + spreadPct)).toFixed(4));

    let finalTargetAmount = 0;
    let finalSourceAmountInr = 0;

    if (targetAmount && targetAmount > 0) {
      finalTargetAmount = Number(targetAmount.toFixed(2));
      finalSourceAmountInr = Number((finalTargetAmount * effectiveRate).toFixed(2));
    } else if (sourceAmountInr && sourceAmountInr > 0) {
      finalSourceAmountInr = Number(sourceAmountInr.toFixed(2));
      finalTargetAmount = Number((finalSourceAmountInr / effectiveRate).toFixed(2));
    } else {
      throw new Error('Either targetAmount or sourceAmountInr must be provided.');
    }

    // Fixed AD Bank fee & GST (18%)
    const adBankFeeInr = currencyInfo.tier === 'TIER_2_AD_BANK' ? 150 : 25;
    const gstInr = Number((adBankFeeInr * 0.18).toFixed(2));
    const totalCostInr = Number((finalSourceAmountInr + adBankFeeInr + gstInr).toFixed(2));

    // Rate lock window: 10 minutes
    const quoteId = `quote_fx_${uuidv4().replace(/-/g, '').slice(0, 12)}`;
    const rateLockExpiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

    // Simple plain-language explanation
    const routeSimpleName = currencyInfo.tier === 'RUPEE_FIRST_BILATERAL'
      ? 'Direct Rupee Route (Zero USD conversion loss)'
      : currencyInfo.tier === 'TIER_1_NIPL'
      ? 'Fast UPI Corridor (Reaches in seconds)'
      : 'Standard International Bank Wire';

    const simpleUserSummary = `Pay ₹${totalCostInr.toLocaleString('en-IN')} from your bank account. Receiver gets exactly ${finalTargetAmount} ${targetCurrency.toUpperCase()} directly. Rate locked for 10 minutes.`;

    const quote: CrossBorderQuote & { simpleUserSummary: string; routeSimpleName: string; simpleExplanation: string } = {
      quoteId,
      sourceCurrency: 'INR',
      targetCurrency: targetCurrency.toUpperCase(),
      targetAmount: finalTargetAmount,
      sourceAmountInr: finalSourceAmountInr,
      exchangeRate: effectiveRate,
      marketReferenceRate: currencyInfo.marketRate,
      adBankFeeInr,
      gstInr,
      totalCostInr,
      corridorType: currencyInfo.tier,
      partnerRail: currencyInfo.partnerRail,
      rateLockExpiresAt,
      lrsLimitRemainingUsd,
      simpleUserSummary,
      routeSimpleName,
      simpleExplanation: `Your money travels via the ${routeSimpleName}. No hidden fees.`,
    };

    this.activeRateLocks.set(quoteId, quote);
    return quote;
  }

  public static getValidQuote(quoteId: string): CrossBorderQuote | null {
    const quote = this.activeRateLocks.get(quoteId);
    if (!quote) return null;

    if (new Date(quote.rateLockExpiresAt).getTime() < Date.now()) {
      this.activeRateLocks.delete(quoteId);
      return null;
    }
    return quote;
  }

  public static getLrsStatus(userId: string) {
    const user = db.get('users').find((u) => u.id === userId);
    const usedUsd = user ? user.lrsUsedUsd : 0;
    const totalLimit = config.lrsAnnualLimitUsd;
    const remainingUsd = Math.max(0, totalLimit - usedUsd);
    const percentUsed = Number(((usedUsd / totalLimit) * 100).toFixed(2));

    return {
      userId,
      panNumber: user?.panNumber || 'ABCDE1234F',
      financialYear: '2026-2027',
      totalAnnualLimitUsd: totalLimit,
      usedUsd,
      remainingUsd,
      percentUsed,
      taxImplication: usedUsd > 8500 ? 'Standard 20% TCS applies on excess outward remittance' : 'Exempt from TCS (< ₹7 Lakh equivalent)',
    };
  }
}
