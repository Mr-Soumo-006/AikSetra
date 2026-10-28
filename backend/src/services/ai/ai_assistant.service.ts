import pg from 'pg';
import { defaultLLMProvider } from './providers/ollama.provider.js';
import { ragService } from './rag.service.js';
import { executeAITool } from './tools/ai_tools.js';
import {
  AIMessageInput,
  AIAssistantResponse,
  AICitation,
} from './ai.types.js';

const { Pool } = pg;

export class AIAssistantService {
  private pool: pg.Pool;

  constructor() {
    this.pool = new Pool({
      connectionString: process.env.DATABASE_URL || 'postgresql://postgres:root@localhost:5432/aiksetra_db',
    });
  }

  public async getConversations(userId: string) {
    const res = await this.pool.query(
      `SELECT id, user_id, title, created_at, updated_at
       FROM ai_conversations
       WHERE user_id = $1
       ORDER BY updated_at DESC`,
      [userId]
    );
    return res.rows;
  }

  public async getConversation(conversationId: string, userId: string) {
    const convRes = await this.pool.query(
      `SELECT id, user_id, title, created_at, updated_at
       FROM ai_conversations
       WHERE id = $1 AND user_id = $2`,
      [conversationId, userId]
    );
    if (convRes.rowCount === 0) return null;

    const messagesRes = await this.pool.query(
      `SELECT id, role, content, citations, suggested_questions, action_type, action_payload, created_at
       FROM ai_messages
       WHERE conversation_id = $1
       ORDER BY created_at ASC`,
      [conversationId]
    );

    return {
      conversation: convRes.rows[0],
      messages: messagesRes.rows,
    };
  }

  public async deleteConversation(conversationId: string, userId: string) {
    const res = await this.pool.query(
      `DELETE FROM ai_conversations
       WHERE id = $1 AND user_id = $2`,
      [conversationId, userId]
    );
    return (res.rowCount ?? 0) > 0;
  }

  public async submitFeedback(messageId: string, userId: string, rating: 'helpful' | 'unhelpful', comment?: string) {
    await this.pool.query(
      `INSERT INTO ai_feedback (message_id, user_id, rating, comment)
       VALUES ($1, $2, $3, $4)`,
      [messageId, userId, rating, comment || null]
    );
    return { success: true };
  }

  private detectToolsAndIntent(query: string): {
    toolsToRun: Array<{ name: string; args: Record<string, any> }>;
    suggestedAction?: { type: string; payload?: Record<string, any> };
  } {
    const q = query.toLowerCase();
    const tools: Array<{ name: string; args: Record<string, any> }> = [];
    let action: { type: string; payload?: Record<string, any> } | undefined;

    // Check account / balance inquiry
    if (q.includes('balance') || q.includes('how much money') || q.includes('my account') || q.includes('my banks')) {
      tools.push({ name: 'get_user_financial_summary', args: {} });
      action = { type: 'open_bank_accounts' };
    }

    // Check transaction inquiry
    if (q.includes('transaction') || q.includes('spend') || q.includes('spent') || q.includes('history') || q.includes('last payment')) {
      tools.push({ name: 'get_recent_transactions', args: { limit: 5 } });
      action = { type: 'open_history' };
    }

    // Check stock market investment ideas & research
    if (
      q.includes('investment idea') ||
      q.includes('ideas') ||
      q.includes('which stock') ||
      q.includes('stocks to buy') ||
      q.includes('where to invest') ||
      q.includes('recommend') ||
      q.includes('invest on which') ||
      q.includes('stock market invest') ||
      q.includes('swing trade') ||
      q.includes('breakout stock') ||
      q.includes('value stock')
    ) {
      let category = 'MOMENTUM';
      if (q.includes('value')) category = 'VALUE';
      if (q.includes('swing')) category = 'SWING';
      if (q.includes('growth')) category = 'GROWTH';
      tools.push({ name: 'get_stock_investment_ideas', args: { category } });
      action = { type: 'open_stock_market' };
    }

    // Check individual stock market quote
    const stockSymbols = ['RELIANCE', 'TCS', 'HDFCBANK', 'INFY', 'ICICIBANK', 'TATAMOTORS'];
    for (const sym of stockSymbols) {
      if (q.includes(sym.toLowerCase()) || (sym === 'HDFCBANK' && q.includes('hdfc')) || (sym === 'TATAMOTORS' && q.includes('tata motors'))) {
        tools.push({ name: 'get_market_quote', args: { symbol: sym } });
        action = { type: 'open_stock_market', payload: { symbol: sym } };
        break;
      }
    }

    // Check calculator navigation or calculation
    if (q.includes('sip') || q.includes('emi') || q.includes('fd') || q.includes('rd') || q.includes('gst') || q.includes('calc')) {
      action = { type: 'open_calculator' };
      // Regex parse simple SIP e.g. "sip 5000 12% 5 years"
      const sipMatch = q.match(/sip.*?(\d+).*?(\d+(\.\d+)?)%.*?(\d+)/i);
      if (sipMatch) {
        tools.push({
          name: 'calculate_financial',
          args: {
            toolType: 'SIP',
            principal: Number(sipMatch[1]),
            ratePct: Number(sipMatch[2]),
            tenure: Number(sipMatch[4]),
          },
        });
      }
    }

    // App section navigation
    if (q.includes('qr') || q.includes('scan')) {
      action = { type: 'open_qr_scanner' };
    } else if (q.includes('business account') || q.includes('merchant')) {
      action = { type: 'open_business_account' };
    } else if (q.includes('autopay') || q.includes('mandate')) {
      action = { type: 'open_autopay' };
    }

    return { toolsToRun: tools, suggestedAction: action };
  }

  public async chat(
    userId: string,
    query: string,
    conversationId?: string
  ): Promise<AIAssistantResponse> {
    const startTime = Date.now();

    // 1. Ensure conversation exists
    let activeConvId = conversationId;
    if (!activeConvId) {
      const convRes = await this.pool.query(
        `INSERT INTO ai_conversations (user_id, title)
         VALUES ($1, $2)
         RETURNING id`,
        [userId, query.slice(0, 40) + (query.length > 40 ? '...' : '')]
      );
      activeConvId = convRes.rows[0].id;
    }

    // 2. Save user message
    await this.pool.query(
      `INSERT INTO ai_messages (conversation_id, role, content)
       VALUES ($1, 'user', $2)`,
      [activeConvId, query]
    );

    // 3. Retrieve relevant knowledge chunks (RAG)
    let citations: AICitation[] = [];
    try {
      citations = await ragService.retrieve(query, 3);
    } catch (err) {
      console.warn('[AI Assistant] RAG retrieval error:', err);
    }

    // 4. Run authorized tools if applicable
    const { toolsToRun, suggestedAction } = this.detectToolsAndIntent(query);
    const toolsExecutedNames: string[] = [];
    let toolContextText = '';

    for (const tool of toolsToRun) {
      const res = await executeAITool(tool.name, tool.args, userId);
      toolsExecutedNames.push(tool.name);
      if (res.success) {
        toolContextText += `\n[VERIFIED SYSTEM DATA FROM ${tool.name.toUpperCase()}]:\n${JSON.stringify(res.data, null, 2)}\n`;
      }
    }

    // 5. Construct Grounded Prompt for LLM
    const systemPrompt = `You are the AikSetra AI Financial Assistant, an intelligent, transparent, and security-first assistant built into AikSetra.
Your primary goals:
- Help users navigate and use AikSetra features (UPI, Multi-Bank Accounts, AutoPay, Business Accounts, Financial Calculators, Stock Market).
- Explain financial concepts clearly (SIP, FD, RD, EMI, compounding, diversification).
- Accurately summarize verified ledger facts when tool data is provided.
- Present market research, technical screeners, and stock investment ideas when provided in the verified data, formatted clearly with stock symbol, current price, strategy, target zone, support level, and technical rationale (similar to Upstox, Zerodha, or Groww screeners).
- Never guarantee investment returns. Conclude stock discussions with an educational research disclaimer.
- Never ask for, store, or output MPINs, OTPs, CVVs, or card credentials.

OFFICIAL AIKSETRA DOCUMENTATION CONTEXT:
${citations.map((c, idx) => `[Source ${idx + 1}: ${c.title} (${c.category})]\n${c.snippet}`).join('\n\n')}

${toolContextText ? `CURRENT VERIFIED SYSTEM DATA (AUTHORIZED & ACCURATE):\n${toolContextText}` : ''}

INSTRUCTIONS:
1. Provide a direct, helpful, and concise answer.
2. If tool data contains stock investment ideas or market quotes, present each stock idea clearly with its strategy, current price, target zone, support level, and technical rationale. Do not refuse to show verified technical screening data.
3. If tool data shows the user's balances or transactions, present them clearly.
4. If the user asks how to do an action, inform them that you have provided a shortcut button below.`;

    // 6. Fetch previous 6 messages for context
    const historyRes = await this.pool.query(
      `SELECT role, content
       FROM ai_messages
       WHERE conversation_id = $1
       ORDER BY created_at DESC
       LIMIT 6`,
      [activeConvId]
    );
    const recentMessages = historyRes.rows.reverse();

    const llmMessages: AIMessageInput[] = [
      { role: 'system', content: systemPrompt },
      ...recentMessages.map((m) => ({ role: m.role as 'user' | 'assistant', content: m.content })),
    ];

    let reply = '';
    let usedOllama = false;

    // 7. Invoke Ollama Provider if available
    try {
      const isOllamaOnline = await defaultLLMProvider.isAvailable();
      if (isOllamaOnline) {
        const response = await defaultLLMProvider.chat(llmMessages, { temperature: 0.3 });
        if (response && response.content) {
          reply = response.content;
          usedOllama = true;
        }
      }
    } catch (err: any) {
      console.warn('[AI Assistant] Ollama chat unavailable, using deterministic RAG response:', err.message);
    }

    // If model gave a standard advisory refusal when stock ideas are requested, override with the technical screener
    if (
      toolsExecutedNames.includes('get_stock_investment_ideas') &&
      (!reply || reply.toLowerCase().includes("can't provide") || reply.toLowerCase().includes("cannot provide") || !reply.includes('₹'))
    ) {
      reply = ''; // trigger the structured stock investment ideas formatter below
    }

    // 8. Grounded fallback generator if LLM is currently downloading or offline
    if (!reply) {
      if (toolContextText) {
        if (toolsExecutedNames.includes('get_user_financial_summary')) {
          reply = `Here is your current AikSetra financial summary:\n`;
          const summary = JSON.parse(toolContextText.split('[VERIFIED SYSTEM DATA FROM GET_USER_FINANCIAL_SUMMARY]:\n')[1].split('\n[VERIFIED')[0] || '{}');
          reply += `• Total Liquid Balance: ₹${summary.totalLiquidBalance?.toLocaleString('en-IN') || '0.00'}\n`;
          reply += `• Linked Accounts: ${summary.totalLinkedAccounts || 0}\n`;
          if (Array.isArray(summary.accounts)) {
            for (const acc of summary.accounts) {
              reply += `  - ${acc.bankName} (${acc.accountNumber}): ₹${acc.balance?.toLocaleString('en-IN') || '0'} ${acc.isPrimary ? '[Primary]' : ''}\n`;
            }
          }
          reply += `\nYou can switch your primary account or deposit funds into any account from the Bank Accounts section.`;
        } else if (toolsExecutedNames.includes('get_recent_transactions')) {
          const txData = JSON.parse(toolContextText.split('[VERIFIED SYSTEM DATA FROM GET_RECENT_TRANSACTIONS]:\n')[1].split('\n[VERIFIED')[0] || '{}');
          reply = `Here are your recent transactions:\n`;
          if (Array.isArray(txData.recentTransactions) && txData.recentTransactions.length > 0) {
            for (const t of txData.recentTransactions) {
              reply += `• ₹${t.amount} ${t.type === 'DEBIT' ? 'sent to' : 'received from'} ${t.counterpartyName} (${t.status})\n`;
            }
          } else {
            reply += `No recent transactions found in your account history.\n`;
          }
        } else if (toolsExecutedNames.includes('calculate_financial')) {
          reply = `Financial calculation result:\n`;
          const calcData = JSON.parse(toolContextText.split('[VERIFIED SYSTEM DATA FROM CALCULATE_FINANCIAL]:\n')[1].split('\n[VERIFIED')[0] || '{}');
          if (calcData.maturityAmount) {
            reply += `• Estimated Maturity Value: ₹${calcData.maturityAmount?.toLocaleString('en-IN')}\n`;
            reply += `• Total Invested: ₹${calcData.totalInvested?.toLocaleString('en-IN')}\n`;
            reply += `• Estimated Wealth Gain: ₹${calcData.estimatedReturns?.toLocaleString('en-IN')}\n`;
          } else if (calcData.monthlyEmi) {
            reply += `• Monthly EMI: ₹${calcData.monthlyEmi?.toLocaleString('en-IN')}\n`;
            reply += `• Total Interest Payable: ₹${calcData.totalInterest?.toLocaleString('en-IN')}\n`;
            reply += `• Total Amount Payable: ₹${calcData.totalPayable?.toLocaleString('en-IN')}\n`;
          }
        } else if (toolsExecutedNames.includes('get_stock_investment_ideas')) {
          const raw = toolContextText.split('[VERIFIED SYSTEM DATA FROM GET_STOCK_INVESTMENT_IDEAS]:\n')[1].split('\n[VERIFIED')[0] || '{}';
          const ideasData = JSON.parse(raw);
          reply = `📈 **AikSetra Stock Market Research & Investment Ideas**\n`;
          reply += `*Market Condition: ${ideasData.marketCondition || 'Bullish Momentum'}*\n\n`;
          if (Array.isArray(ideasData.ideas)) {
            for (const item of ideasData.ideas) {
              reply += `**${item.name} (${item.symbol})** — ₹${item.currentPrice} (${item.changePct})\n`;
              reply += `• Strategy: ${item.investmentCategory.replace(/_/g, ' ')} [${item.timeHorizon}]\n`;
              reply += `• Target Range: ${item.targetPriceZone} | Support Level: ₹${item.supportLevel}\n`;
              reply += `• Rationale: ${item.thesis}\n`;
              reply += `• Key Indicators: ${item.keyIndicators.join(' • ')}\n\n`;
            }
          }
          reply += `💡 *Disclaimer: Technical indicators and screener ideas are algorithmically derived for research and educational purposes. AikSetra does not promise guaranteed financial returns.*`;
        } else if (toolsExecutedNames.includes('get_market_quote')) {
          const mData = JSON.parse(toolContextText.split('[VERIFIED SYSTEM DATA FROM GET_MARKET_QUOTE]:\n')[1].split('\n[VERIFIED')[0] || '{}');
          reply = `Market Quote for ${mData.name} (${mData.symbol}):\n`;
          reply += `• Current Price: ₹${mData.price} (${mData.changePct})\n`;
          reply += `• 52-Week High: ₹${mData.high52}\n`;
          reply += `• P/E Ratio: ${mData.pe}\n`;
          reply += `\n*Note: Market quotes are for informational and research purposes only. AikSetra does not offer guaranteed investment advice.*`;
        }
      } else if (citations.length > 0) {
        reply = `Based on AikSetra documentation (${citations[0].title}):\n\n${citations[0].snippet}\n\n`;
        if (citations.length > 1) {
          reply += `Additionally from ${citations[1].title}:\n${citations[1].snippet}\n`;
        }
      } else {
        reply = `I am your AikSetra Financial Assistant. I can help you check balances, view transaction history, calculate SIP or EMI returns, track stock prices, or explain any feature of AikSetra. How may I assist you today?`;
      }
    }

    // 9. Generate suggested follow-up questions
    const suggestedQuestions: string[] = [];
    if (query.toLowerCase().includes('balance') || query.toLowerCase().includes('account')) {
      suggestedQuestions.push('How do I switch my primary bank account?');
      suggestedQuestions.push('Show my recent transactions');
    } else if (query.toLowerCase().includes('sip') || query.toLowerCase().includes('calc')) {
      suggestedQuestions.push('Calculate EMI for a ₹5,00,000 personal loan');
      suggestedQuestions.push('How does the AikSetra standard calculator work?');
    } else if (query.toLowerCase().includes('stock') || query.toLowerCase().includes('market') || query.toLowerCase().includes('invest')) {
      suggestedQuestions.push('What are the top momentum breakout stocks today?');
      suggestedQuestions.push('Show value investing picks with low P/E');
      suggestedQuestions.push('Show quote for Reliance');
      suggestedQuestions.push('How do I buy demo stocks in AikSetra?');
    } else {
      suggestedQuestions.push('What is my total account balance?');
      suggestedQuestions.push('Calculate SIP of ₹5,000 at 12% for 10 years');
      suggestedQuestions.push('How do I use the Business Account?');
    }

    // 10. Save assistant message to PostgreSQL
    const msgRes = await this.pool.query(
      `INSERT INTO ai_messages (conversation_id, role, content, citations, suggested_questions, action_type, action_payload)
       VALUES ($1, 'assistant', $2, $3, $4, $5, $6)
       RETURNING id`,
      [
        activeConvId,
        reply,
        JSON.stringify(citations),
        JSON.stringify(suggestedQuestions),
        suggestedAction?.type || null,
        JSON.stringify(suggestedAction?.payload || {}),
      ]
    );

    // Update conversation timestamp
    await this.pool.query(
      `UPDATE ai_conversations SET updated_at = CURRENT_TIMESTAMP WHERE id = $1`,
      [activeConvId]
    );

    const latencyMs = Date.now() - startTime;

    // 11. Audit event
    await this.pool.query(
      `INSERT INTO ai_audit_events (user_id, action, query_preview, tools_invoked, latency_ms)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        userId,
        usedOllama ? 'chat_ollama' : 'chat_rag_deterministic',
        query.slice(0, 100),
        JSON.stringify(toolsExecutedNames),
        latencyMs,
      ]
    );

    return {
      conversationId: activeConvId!,
      messageId: msgRes.rows[0].id,
      reply,
      citations,
      suggestedQuestions,
      actionType: suggestedAction?.type,
      actionPayload: suggestedAction?.payload,
      toolsExecuted: toolsExecutedNames,
      latencyMs,
    };
  }
}

export const aiAssistantService = new AIAssistantService();
