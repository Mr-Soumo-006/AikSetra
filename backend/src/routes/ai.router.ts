import { Router } from 'express';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth.middleware.js';
import { aiAssistantService } from '../services/ai/ai_assistant.service.js';
import { ragService } from '../services/ai/rag.service.js';
import { defaultLLMProvider } from '../services/ai/providers/ollama.provider.js';
import { vectorStore } from '../services/ai/vector_store.js';

export const aiRouter = Router();

// Chat with the Assistant
aiRouter.post('/chat', authMiddleware, async (req, res) => {
  try {
    const authReq = req as AuthenticatedRequest;
    const { query, conversationId } = req.body;

    if (!query || typeof query !== 'string' || !query.trim()) {
      return res.status(400).json({ success: false, message: 'Query string is required.' });
    }

    const response = await aiAssistantService.chat(
      authReq.userId!,
      query.trim(),
      conversationId
    );

    return res.json({
      success: true,
      data: response,
    });
  } catch (err: any) {
    console.error('[AI Router Error /chat]:', err);
    return res.status(500).json({
      success: false,
      message: err.message || 'An error occurred while processing your AI request.',
    });
  }
});

// List all user conversations
aiRouter.get('/conversations', authMiddleware, async (req, res) => {
  try {
    const authReq = req as AuthenticatedRequest;
    const conversations = await aiAssistantService.getConversations(authReq.userId!);
    return res.json({ success: true, data: conversations });
  } catch (err: any) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

// Get a specific conversation and its messages
aiRouter.get('/conversations/:id', authMiddleware, async (req, res) => {
  try {
    const authReq = req as AuthenticatedRequest;
    const { id } = req.params;
    const result = await aiAssistantService.getConversation(id, authReq.userId!);
    if (!result) {
      return res.status(404).json({ success: false, message: 'Conversation not found.' });
    }
    return res.json({ success: true, data: result });
  } catch (err: any) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

// Delete a conversation
aiRouter.delete('/conversations/:id', authMiddleware, async (req, res) => {
  try {
    const authReq = req as AuthenticatedRequest;
    const { id } = req.params;
    const deleted = await aiAssistantService.deleteConversation(id, authReq.userId!);
    return res.json({ success: true, deleted });
  } catch (err: any) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

// Submit thumbs up / down feedback
aiRouter.post('/feedback', authMiddleware, async (req, res) => {
  try {
    const authReq = req as AuthenticatedRequest;
    const { messageId, rating, comment } = req.body;
    if (!messageId || !rating) {
      return res.status(400).json({ success: false, message: 'messageId and rating are required.' });
    }
    await aiAssistantService.submitFeedback(messageId, authReq.userId!, rating, comment);
    return res.json({ success: true, message: 'Feedback recorded successfully.' });
  } catch (err: any) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

// AI Service Status
aiRouter.get('/status', async (_req, res) => {
  try {
    const isOnline = await defaultLLMProvider.isAvailable();
    const models = await defaultLLMProvider.getAvailableModels();
    const docCount = await vectorStore.getDocumentCount();
    const chunkCount = await vectorStore.getChunkCount();

    return res.json({
      success: true,
      data: {
        provider: defaultLLMProvider.name,
        isOllamaOnline: isOnline,
        installedModels: models,
        knowledgeBase: {
          documentsIndexed: docCount,
          chunksIndexed: chunkCount,
        },
      },
    });
  } catch (err: any) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

// Seed / Re-index Knowledge Base
aiRouter.post('/seed-knowledge', async (req, res) => {
  try {
    const force = req.body.force === true;
    const result = await ragService.seedKnowledgeBase(force);
    return res.json({ success: true, data: result });
  } catch (err: any) {
    return res.status(500).json({ success: false, message: err.message });
  }
});
