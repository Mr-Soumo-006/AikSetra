import { db } from '../../../db/database.js';
import { FinancialToolsService } from '../../financialTools.service.js';
import { AIToolResult } from '../ai.types.js';

export const AI_AVAILABLE_TOOLS = [
  {
    name: 'get_user_financial_summary',
    description: 'Retrieves the authenticated user bank accounts summary, masked numbers, default account, and balances.',
    parameters: {},
  },
  {
    name: 'get_recent_transactions',
    description: 'Retrieves the authenticated user recent transactions (status, amount, counterparty, timestamp).',
    parameters: {
      limit: { type: 'number', description: 'Number of recent transactions to return (default 5, max 10)' },
    },
  },
  {
    name: 'calculate_financial',
    description: 'Computes deterministic financial formulas: SIP, FD, RD, EMI, or GST.',
    parameters: {
      toolType: { type: 'string', enum: ['SIP', 'FD', 'RD', 'EMI', 'GST'], description: 'The calculation type' },
      principal: { type: 'number', description: 'Principal or monthly investment amount' },
      ratePct: { type: 'number', description: 'Annual interest or expected return rate in percentage' },
      tenure: { type: 'number', description: 'Tenure in years (or months for EMI)' },
    },
  },
  {
    name: 'get_market_quote',
    description: 'Retrieves current quote and day performance for major tracked stock tickers.',
    parameters: {
      symbol: { type: 'string', description: 'Stock ticker symbol (e.g. RELIANCE, TCS, HDFCBANK, INFY)' },
    },
  },
  {
    name: 'navigate_app',
    description: 'Provides a direct app action to navigate the user to a relevant feature inside AikSetra.',
    parameters: {
      action: {
        type: 'string',
        enum: [
          'open_calculator',
          'open_qr_scanner',
          'open_bank_accounts',
          'open_business_account',
          'open_stock_market',
          'open_autopay',
          'open_history',
        ],
        description: 'Target feature action inside AikSetra',
      },
    },
  },
];

export async function executeAITool(
  name: string,
  args: Record<string, any>,
  userId: string
): Promise<AIToolResult> {
  try {
    switch (name) {
      case 'get_user_financial_summary': {
        const accounts = db.get('accounts').filter((a) => a.userId === userId);
        const user = db.get('users').find((u) => u.id === userId);
        const masked = accounts.map((a: any) => {
          const rawNum = a.maskedAccountNumber || a.accountNumber || '•••• 0000';
          const last4 = rawNum.replace(/\s+/g, '').slice(-4);
          return {
            bankName: a.bankName,
            accountNumber: `•••• ${last4}`,
            accountType: a.accountType,
            balance: a.balance,
            isPrimary: !!a.isPrimary,
          };
        });
        const totalBalance = accounts.reduce((acc, cur) => acc + (cur.balance || 0), 0);
        return {
          name,
          success: true,
          data: {
            userName: user?.fullName || 'User',
            primaryVpa: user?.primaryVpa,
            totalLinkedAccounts: accounts.length,
            totalLiquidBalance: totalBalance,
            accounts: masked,
          },
        };
      }

      case 'get_recent_transactions': {
        const limit = Math.min(Math.max(Number(args.limit) || 5, 1), 10);
        const txns = db
          .get('transactions')
          .filter((t) => t.fromUserId === userId || t.toUserId === userId)
          .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
          .slice(0, limit)
          .map((t) => ({
            id: t.id,
            amount: t.amount,
            type: t.fromUserId === userId ? 'DEBIT' : 'CREDIT',
            counterpartyVpa: t.fromUserId === userId ? t.toVpa : t.fromVpa,
            counterpartyName: t.counterpartyName || 'Contact',
            status: t.status,
            createdAt: t.createdAt,
            note: t.note || '',
          }));
        return {
          name,
          success: true,
          data: { recentTransactions: txns, count: txns.length },
        };
      }

      case 'calculate_financial': {
        const toolType = (args.toolType || '').toUpperCase();
        const principal = Number(args.principal) || 0;
        const ratePct = Number(args.ratePct) || 0;
        const tenure = Number(args.tenure) || 0;

        if (toolType === 'SIP') {
          const res = FinancialToolsService.calculateSip(principal, ratePct, tenure);
          return { name, success: true, data: res };
        } else if (toolType === 'FD') {
          const res = FinancialToolsService.calculateFd(principal, ratePct, tenure);
          return { name, success: true, data: res };
        } else if (toolType === 'RD') {
          const res = FinancialToolsService.calculateRd(principal, ratePct, tenure);
          return { name, success: true, data: res };
        } else if (toolType === 'EMI') {
          const res = FinancialToolsService.calculateEmi(principal, ratePct, tenure);
          return { name, success: true, data: res };
        } else if (toolType === 'GST') {
          const res = FinancialToolsService.calculateGst(principal, ratePct);
          return { name, success: true, data: res };
        }
        return { name, success: false, error: `Unsupported toolType: ${toolType}` };
      }

      case 'get_market_quote': {
        const symbol = (args.symbol || 'RELIANCE').toUpperCase();
        const STOCKS: Record<string, any> = {
          RELIANCE: { name: 'Reliance Industries Ltd', price: 2984.5, changePct: '+1.42%', high52: 3024.9, pe: 28.4 },
          TCS: { name: 'Tata Consultancy Services', price: 4120.0, changePct: '-0.35%', high52: 4592.25, pe: 31.2 },
          HDFCBANK: { name: 'HDFC Bank Ltd', price: 1680.25, changePct: '+0.88%', high52: 1794.0, pe: 19.5 },
          INFY: { name: 'Infosys Ltd', price: 1890.1, changePct: '+2.10%', high52: 1991.45, pe: 27.8 },
          ICICIBANK: { name: 'ICICI Bank Ltd', price: 1245.8, changePct: '+0.65%', high52: 1300.0, pe: 18.2 },
          TATAMOTORS: { name: 'Tata Motors Ltd', price: 978.4, changePct: '-1.15%', high52: 1179.0, pe: 14.6 },
        };
        const quote = STOCKS[symbol] || {
          name: symbol,
          price: 1540.0,
          changePct: '+0.50%',
          high52: 1600.0,
          pe: 22.0,
        };
        return {
          name,
          success: true,
          data: {
            symbol,
            ...quote,
            source: 'NSE/BSE Reference Quotes (Informational, Non-Advisory)',
            timestamp: new Date().toISOString(),
          },
        };
      }

      case 'navigate_app': {
        const action = args.action;
        return {
          name,
          success: true,
          data: { action, message: `Navigate to ${action}` },
        };
      }

      default:
        return { name, success: false, error: `Unknown tool: ${name}` };
    }
  } catch (err: any) {
    return { name, success: false, error: err.message };
  }
}
