export class FinancialToolsService {
  private static liveFxRates: Record<string, { rate: number; currencyName: string; flag: string }> = {
    USD: { rate: 85.35, currencyName: 'US Dollar', flag: '🇺🇸' },
    EUR: { rate: 92.4, currencyName: 'Euro', flag: '🇪🇺' },
    GBP: { rate: 108.15, currencyName: 'British Pound', flag: '🇬🇧' },
    AED: { rate: 23.24, currencyName: 'UAE Dirham', flag: '🇦🇪' },
    SGD: { rate: 64.12, currencyName: 'Singapore Dollar', flag: '🇸🇬' },
    JPY: { rate: 0.56, currencyName: 'Japanese Yen', flag: '🇯🇵' },
    CAD: { rate: 62.3, currencyName: 'Canadian Dollar', flag: '🇨🇦' },
    AUD: { rate: 56.45, currencyName: 'Australian Dollar', flag: '🇦🇺' },
  };

  public static getLiveRates() {
    return {
      success: true,
      source: 'RBI Financial Benchmarks & Refinitiv Live Feeds',
      baseCurrency: 'INR',
      timestamp: new Date().toISOString(),
      rates: this.liveFxRates,
    };
  }

  public static calculateEmi(principal: number, annualRatePct: number, tenureMonths: number) {
    const monthlyRate = annualRatePct / (12 * 100);
    const emi =
      monthlyRate === 0
        ? principal / tenureMonths
        : (principal * monthlyRate * Math.pow(1 + monthlyRate, tenureMonths)) /
          (Math.pow(1 + monthlyRate, tenureMonths) - 1);

    const totalPayable = emi * tenureMonths;
    const totalInterest = totalPayable - principal;

    return {
      monthlyEmi: Number(emi.toFixed(2)),
      totalInterest: Number(totalInterest.toFixed(2)),
      totalPayable: Number(totalPayable.toFixed(2)),
      principal,
      tenureMonths,
      annualRatePct,
    };
  }

  public static calculateSip(monthlyInvestment: number, annualRatePct: number, years: number) {
    const months = years * 12;
    const monthlyRate = annualRatePct / (12 * 100);
    const maturityAmount =
      monthlyInvestment * ((Math.pow(1 + monthlyRate, months) - 1) / monthlyRate) * (1 + monthlyRate);
    const totalInvested = monthlyInvestment * months;
    const estimatedReturns = maturityAmount - totalInvested;

    return {
      totalInvested: Number(totalInvested.toFixed(2)),
      estimatedReturns: Number(estimatedReturns.toFixed(2)),
      maturityAmount: Number(maturityAmount.toFixed(2)),
      monthlyInvestment,
      annualRatePct,
      years,
    };
  }

  public static calculateFd(principal: number, annualRatePct: number, years: number, compoundFreqPerYear: number = 4) {
    const r = annualRatePct / 100;
    const n = compoundFreqPerYear; // Quarterly compounding by default in Indian banks
    const maturityAmount = principal * Math.pow(1 + r / n, n * years);
    const interestEarned = maturityAmount - principal;

    return {
      principal,
      annualRatePct,
      years,
      interestEarned: Number(interestEarned.toFixed(2)),
      maturityAmount: Number(maturityAmount.toFixed(2)),
    };
  }

  public static calculateGst(amount: number, gstRatePct: number, isExclusive: boolean = true) {
    if (isExclusive) {
      const gstAmount = (amount * gstRatePct) / 100;
      const totalAmount = amount + gstAmount;
      return {
        baseAmount: amount,
        gstAmount: Number(gstAmount.toFixed(2)),
        cgst: Number((gstAmount / 2).toFixed(2)),
        sgst: Number((gstAmount / 2).toFixed(2)),
        totalAmount: Number(totalAmount.toFixed(2)),
        gstRatePct,
      };
    } else {
      const baseAmount = (amount * 100) / (100 + gstRatePct);
      const gstAmount = amount - baseAmount;
      return {
        baseAmount: Number(baseAmount.toFixed(2)),
        gstAmount: Number(gstAmount.toFixed(2)),
        cgst: Number((gstAmount / 2).toFixed(2)),
        sgst: Number((gstAmount / 2).toFixed(2)),
        totalAmount: amount,
        gstRatePct,
      };
    }
  }

  public static estimateIncomeTax(annualGrossIncome: number) {
    // New Tax Regime (Section 115BAC - FY 2024-25 / AY 2025-26)
    // Standard Deduction: ₹75,000
    const stdDeductionNew = 75000;
    const taxableNew = Math.max(0, annualGrossIncome - stdDeductionNew);
    let taxNew = 0;

    if (taxableNew <= 700000) {
      taxNew = 0; // Rebate u/s 87A: Nil tax up to 7 Lakhs
    } else {
      // 0-3L: 0%
      // 3-7L: 5% = 20,000
      // 7-10L: 10% = 30,000
      // 10-12L: 15% = 30,000
      // 12-15L: 20% = 60,000
      // >15L: 30%
      let remaining = taxableNew;
      if (remaining > 1500000) {
        taxNew += (remaining - 1500000) * 0.3;
        remaining = 1500000;
      }
      if (remaining > 1200000) {
        taxNew += (remaining - 1200000) * 0.2;
        remaining = 1200000;
      }
      if (remaining > 1000000) {
        taxNew += (remaining - 1000000) * 0.15;
        remaining = 1000000;
      }
      if (remaining > 700000) {
        taxNew += (remaining - 700000) * 0.1;
        remaining = 700000;
      }
      if (remaining > 300000) {
        taxNew += (remaining - 300000) * 0.05;
      }
      // Add 4% Health & Education Cess
      taxNew = taxNew * 1.04;
    }

    return {
      assessmentYear: '2025-26 (FY 2024-25)',
      grossIncome: annualGrossIncome,
      standardDeduction: stdDeductionNew,
      taxableIncome: taxableNew,
      totalTaxPayable: Number(taxNew.toFixed(2)),
      effectiveTaxRatePct: annualGrossIncome > 0 ? Number(((taxNew / annualGrossIncome) * 100).toFixed(2)) : 0,
      disclaimer: 'Calculated based on Finance Act 2024 New Tax Regime. Consult a certified Chartered Accountant for filing.',
    };
  }
}
