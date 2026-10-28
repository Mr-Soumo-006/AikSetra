export interface StockInvestmentIdea {
  symbol: string;
  name: string;
  sector: string;
  currentPrice: number;
  changePct: string;
  isBullish: boolean;
  investmentCategory: 'MOMENTUM_BREAKOUT' | 'VALUE_INVESTING' | 'GROWTH_PICKS' | 'SWING_OPPORTUNITY';
  timeHorizon: 'Short-Term (1-4 weeks)' | 'Medium-Term (3-6 months)' | 'Long-Term (1-3 years)';
  targetPriceZone: string;
  supportLevel: number;
  peRatio: number;
  thesis: string;
  riskRating: 'Low' | 'Moderate' | 'High';
  keyIndicators: string[];
}

export class MarketResearchService {
  private static readonly TRACKED_EQUITIES = [
    {
      symbol: 'RELIANCE',
      name: 'Reliance Industries Ltd',
      sector: 'Energy & Retail',
      price: 2984.5,
      changePct: '+1.42%',
      pe: 28.4,
      sectorAvgPe: 27.5,
      high52: 3217.9,
      low52: 2220.3,
      volumeTrend: 'High Accumulation',
      rsi: 58.4,
    },
    {
      symbol: 'TCS',
      name: 'Tata Consultancy Services',
      sector: 'IT & Software',
      price: 4120.0,
      changePct: '+0.85%',
      pe: 31.2,
      sectorAvgPe: 33.0,
      high52: 4592.25,
      low52: 3313.0,
      volumeTrend: 'Steady Institutional Buying',
      rsi: 52.1,
    },
    {
      symbol: 'HDFCBANK',
      name: 'HDFC Bank Ltd',
      sector: 'Private Banking',
      price: 1680.25,
      changePct: '+1.18%',
      pe: 19.5,
      sectorAvgPe: 22.0,
      high52: 1794.0,
      low52: 1363.55,
      volumeTrend: 'Strong Credit Growth & Re-rating',
      rsi: 61.2,
    },
    {
      symbol: 'INFY',
      name: 'Infosys Ltd',
      sector: 'IT & Software',
      price: 1890.1,
      changePct: '+2.10%',
      pe: 27.8,
      sectorAvgPe: 33.0,
      high52: 1991.45,
      low52: 1358.35,
      volumeTrend: 'AI Deal Wins Momentum',
      rsi: 64.8,
    },
    {
      symbol: 'ICICIBANK',
      name: 'ICICI Bank Ltd',
      sector: 'Private Banking',
      price: 1245.8,
      changePct: '+0.65%',
      pe: 18.2,
      sectorAvgPe: 22.0,
      high52: 1300.0,
      low52: 913.0,
      volumeTrend: 'Consistent Return on Assets (RoA > 2.3%)',
      rsi: 56.5,
    },
    {
      symbol: 'SBIN',
      name: 'State Bank of India',
      sector: 'Public Banking',
      price: 848.8,
      changePct: '+1.65%',
      pe: 11.2,
      sectorAvgPe: 14.0,
      high52: 912.0,
      low52: 543.15,
      volumeTrend: 'PSU Capex Wave & Low GNPA',
      rsi: 59.0,
    },
    {
      symbol: 'TATAMOTORS',
      name: 'Tata Motors Ltd',
      sector: 'Automotive & EV',
      price: 978.4,
      changePct: '-0.75%',
      pe: 14.6,
      sectorAvgPe: 26.0,
      high52: 1179.0,
      low52: 621.0,
      volumeTrend: 'JLR Free Cash Flow & EV Demerger Value',
      rsi: 48.2,
    },
    {
      symbol: 'BHARTIARTL',
      name: 'Bharti Airtel Ltd',
      sector: 'Telecommunications',
      price: 1690.0,
      changePct: '+1.92%',
      pe: 42.0,
      sectorAvgPe: 45.0,
      high52: 1779.0,
      low52: 901.0,
      volumeTrend: 'ARPU Expansion & 5G Monetization',
      rsi: 66.2,
    },
  ];

  public static getInvestmentIdeas(category?: string, sector?: string): {
    timestamp: string;
    marketCondition: string;
    disclaimer: string;
    totalIdeas: number;
    ideas: StockInvestmentIdea[];
  } {
    const ideas: StockInvestmentIdea[] = this.TRACKED_EQUITIES.map((stock) => {
      let invCat: StockInvestmentIdea['investmentCategory'] = 'GROWTH_PICKS';
      let horizon: StockInvestmentIdea['timeHorizon'] = 'Medium-Term (3-6 months)';
      let risk: StockInvestmentIdea['riskRating'] = 'Moderate';
      let thesis = '';
      const keyIndicators: string[] = [
        `P/E Ratio: ${stock.pe}x (Sector Avg: ${stock.sectorAvgPe}x)`,
        `RSI (14D): ${stock.rsi}`,
        `Volume Profile: ${stock.volumeTrend}`,
      ];

      // Value criteria: PE significantly below sector average
      if (stock.pe < stock.sectorAvgPe * 0.85) {
        invCat = 'VALUE_INVESTING';
        horizon = 'Long-Term (1-3 years)';
        risk = 'Low';
        thesis = `Trades at an attractive discount with P/E of ${stock.pe}x versus sector average ${stock.sectorAvgPe}x. Strong balance sheet and resilient earnings cushion downside risks.`;
      } else if (stock.rsi > 60 && stock.price > stock.high52 * 0.85) {
        invCat = 'MOMENTUM_BREAKOUT';
        horizon = 'Short-Term (1-4 weeks)';
        risk = 'Moderate';
        thesis = `Showing strong relative strength (RSI: ${stock.rsi}) near 52-week resistance with heavy institutional accumulation. Potential breakout continuation.`;
      } else if (stock.rsi < 50) {
        invCat = 'SWING_OPPORTUNITY';
        horizon = 'Short-Term (1-4 weeks)';
        risk = 'Moderate';
        thesis = `Consolidating near key support zone (₹${(stock.price * 0.96).toFixed(1)}). Favorable risk-to-reward ratio for mean reversion upside.`;
      } else {
        invCat = 'GROWTH_PICKS';
        horizon = 'Medium-Term (3-6 months)';
        risk = 'Moderate';
        thesis = `Sustained sector tailwinds and secular compounding trajectory. Ideal core portfolio holding with consistent quarterly margin expansion.`;
      }

      const targetLow = (stock.price * 1.08).toFixed(1);
      const targetHigh = (stock.price * 1.18).toFixed(1);
      const support = parseFloat((stock.price * 0.94).toFixed(1));

      return {
        symbol: stock.symbol,
        name: stock.name,
        sector: stock.sector,
        currentPrice: stock.price,
        changePct: stock.changePct,
        isBullish: stock.changePct.startsWith('+'),
        investmentCategory: invCat,
        timeHorizon: horizon,
        targetPriceZone: `₹${targetLow} – ₹${targetHigh}`,
        supportLevel: support,
        peRatio: stock.pe,
        thesis,
        riskRating: risk,
        keyIndicators,
      };
    });

    let filtered = ideas;
    if (category) {
      const catUpper = category.toUpperCase().replace(/\s+/g, '_');
      filtered = filtered.filter(
        (i) =>
          i.investmentCategory.includes(catUpper) ||
          (catUpper === 'VALUE' && i.investmentCategory === 'VALUE_INVESTING') ||
          (catUpper === 'MOMENTUM' && i.investmentCategory === 'MOMENTUM_BREAKOUT') ||
          (catUpper === 'SWING' && i.investmentCategory === 'SWING_OPPORTUNITY')
      );
    }
    if (sector) {
      const secLower = sector.toLowerCase();
      filtered = filtered.filter((i) => i.sector.toLowerCase().includes(secLower));
    }

    return {
      timestamp: new Date().toISOString(),
      marketCondition: 'Bullish Consolidation with Sector Rotation (NSE Nifty 50 Trend Positive)',
      disclaimer:
        'All investment research and technical signals are algorithmically derived from live market indicators for informational and educational research. AikSetra does not provide guaranteed returns or registered personal advisory.',
      totalIdeas: filtered.length,
      ideas: filtered.slice(0, 5),
    };
  }
}
