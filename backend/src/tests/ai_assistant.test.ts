import test, { describe, it } from 'node:test';
import assert from 'node:assert';
import { db } from '../db/database.js';
import { runSeed } from '../db/seed.js';
import { ragService } from '../services/ai/rag.service.js';
import { vectorStore } from '../services/ai/vector_store.js';
import { executeAITool } from '../services/ai/tools/ai_tools.js';
import { aiAssistantService } from '../services/ai/ai_assistant.service.js';

describe('AI Financial Assistant Test Suite', async () => {
  await db.init();
  runSeed(true);

  it('1. RAG Service: Ingests and indexes knowledge base documents', async () => {
    const seedResult = await ragService.seedKnowledgeBase(false);
    assert.ok(seedResult.docCount >= 8, 'Should index at least 8 knowledge documents');
    assert.ok(seedResult.chunkCount >= 8, 'Should index chunks');

    const totalDocs = await vectorStore.getDocumentCount();
    assert.strictEqual(totalDocs, seedResult.docCount);
  });

  it('2. RAG Retrieval: Retrieves grounded citations for queries', async () => {
    const citations = await ragService.retrieve('How does multi-bank account switching work in AikSetra?');
    assert.ok(citations.length > 0, 'Should return at least one citation');
    assert.ok(citations[0].title.includes('Bank') || citations[0].snippet.includes('account'), 'Citation must be relevant');
  });

  it('3. AI Tools: get_user_financial_summary returns masked accounts and balances', async () => {
    const res = await executeAITool('get_user_financial_summary', {}, 'usr_simo_01');
    assert.strictEqual(res.success, true);
    assert.ok(Array.isArray(res.data.accounts), 'Should return accounts array');
    assert.ok(res.data.totalLiquidBalance >= 0, 'Should have positive liquid balance');
    assert.ok(res.data.accounts[0].accountNumber.startsWith('••••'), 'Account numbers must be masked for security');
  });

  it('4. AI Tools: calculate_financial accurately calculates SIP and EMI', async () => {
    const sipRes = await executeAITool('calculate_financial', {
      toolType: 'SIP',
      principal: 5000,
      ratePct: 12,
      tenure: 10,
    }, 'usr_simo_01');
    assert.strictEqual(sipRes.success, true);
    assert.strictEqual(sipRes.data.totalInvested, 600000);
    assert.ok(sipRes.data.maturityAmount > 1000000, 'SIP returns should exceed 10 lakhs');

    const emiRes = await executeAITool('calculate_financial', {
      toolType: 'EMI',
      principal: 500000,
      ratePct: 8.5,
      tenure: 60,
    }, 'usr_simo_01');
    assert.strictEqual(emiRes.success, true);
    assert.ok(emiRes.data.monthlyEmi > 10000, 'EMI should be calculated correctly');
  });

  it('5. AI Tools: get_market_quote returns real stock quote without advisory promises', async () => {
    const quoteRes = await executeAITool('get_market_quote', { symbol: 'RELIANCE' }, 'usr_simo_01');
    assert.strictEqual(quoteRes.success, true);
    assert.strictEqual(quoteRes.data.symbol, 'RELIANCE');
    assert.ok(quoteRes.data.price > 0, 'Stock price must be positive');
    assert.ok(quoteRes.data.source.includes('Non-Advisory'), 'Must contain non-advisory disclaimer');
  });

  it('6. AIAssistantService: Processes chat, grounds citations, and logs audit record', async () => {
    const response = await aiAssistantService.chat(
      'usr_simo_01',
      'What is my current total bank balance and how do I switch accounts?'
    );

    assert.ok(response.conversationId, 'Must generate or retain conversation ID');
    assert.ok(response.messageId, 'Must create message ID');
    assert.ok(response.reply.length > 20, 'Reply should be informative');
    assert.ok(Array.isArray(response.citations), 'Citations array present');
    assert.ok(Array.isArray(response.suggestedQuestions), 'Suggested questions present');
    assert.ok(response.toolsExecuted?.includes('get_user_financial_summary'), 'Should have executed financial summary tool');

    // Retrieve conversation history
    const conv = await aiAssistantService.getConversation(response.conversationId, 'usr_simo_01');
    assert.ok(conv !== null);
    assert.ok(conv.messages.length >= 2, 'Should contain user message and assistant reply');

    // Feedback
    const fb = await aiAssistantService.submitFeedback(response.messageId, 'usr_simo_01', 'helpful', 'Very clear!');
    assert.strictEqual(fb.success, true);
  });
});
