export interface AICitation {
  documentId: string;
  title: string;
  category: string;
  snippet: string;
  relevanceScore: number;
}

export interface AIToolCall {
  name: string;
  arguments: Record<string, any>;
}

export interface AIToolResult {
  name: string;
  success: boolean;
  data: any;
  error?: string;
}

export interface AIMessageInput {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

export interface AIChatOptions {
  temperature?: number;
  maxTokens?: number;
}

export interface AIChatResponse {
  content: string;
  rawText: string;
}

export interface AIDocument {
  id?: string;
  title: string;
  category: string;
  version?: string;
  content: string;
  metadata?: Record<string, any>;
}

export interface AIDocumentChunk {
  id?: string;
  documentId?: string;
  chunkIndex: number;
  content: string;
  embedding?: number[];
  metadata?: Record<string, any>;
}

export interface AIAssistantResponse {
  conversationId: string;
  messageId: string;
  reply: string;
  citations: AICitation[];
  suggestedQuestions: string[];
  actionType?: string;
  actionPayload?: Record<string, any>;
  toolsExecuted?: string[];
  latencyMs: number;
}
