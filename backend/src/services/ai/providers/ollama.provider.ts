import { ILLMProvider } from './llm.interface.js';
import { AIMessageInput, AIChatOptions, AIChatResponse } from '../ai.types.js';

export class OllamaProvider implements ILLMProvider {
  public readonly name = 'ollama';
  private baseUrl: string;
  private chatModel: string;
  private embedModel: string;

  constructor() {
    this.baseUrl = (process.env.OLLAMA_BASE_URL || 'http://127.0.0.1:11434').replace(/\/+$/, '');
    this.chatModel = process.env.OLLAMA_CHAT_MODEL || 'llama3.2:3b';
    this.embedModel = process.env.OLLAMA_EMBED_MODEL || 'nomic-embed-text';
  }

  public async isAvailable(): Promise<boolean> {
    try {
      const res = await fetch(`${this.baseUrl}/api/version`, { signal: AbortSignal.timeout(3000) });
      return res.ok;
    } catch {
      return false;
    }
  }

  public async getAvailableModels(): Promise<string[]> {
    try {
      const res = await fetch(`${this.baseUrl}/api/tags`, { signal: AbortSignal.timeout(3000) });
      if (!res.ok) return [];
      const data = await res.json() as { models?: Array<{ name: string }> };
      return (data.models || []).map((m) => m.name);
    } catch {
      return [];
    }
  }

  public async chat(messages: AIMessageInput[], options?: AIChatOptions): Promise<AIChatResponse> {
    const payload = {
      model: this.chatModel,
      messages: messages.map((m) => ({
        role: m.role,
        content: m.content,
      })),
      stream: false,
      options: {
        temperature: options?.temperature ?? 0.2,
        num_predict: options?.maxTokens ?? 1024,
      },
    };

    const res = await fetch(`${this.baseUrl}/api/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(60000),
    });

    if (!res.ok) {
      const errText = await res.text().catch(() => '');
      throw new Error(`Ollama chat error (${res.status}): ${errText}`);
    }

    const data = await res.json() as { message?: { content?: string } };
    const content = data.message?.content?.trim() || 'I am sorry, but I could not formulate a response.';
    return {
      content,
      rawText: content,
    };
  }

  public async embed(text: string): Promise<number[]> {
    const payload = {
      model: this.embedModel,
      prompt: text.trim(),
    };

    const res = await fetch(`${this.baseUrl}/api/embeddings`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(15000),
    });

    if (!res.ok) {
      const errText = await res.text().catch(() => '');
      throw new Error(`Ollama embedding error (${res.status}): ${errText}`);
    }

    const data = await res.json() as { embedding?: number[] };
    if (!data.embedding || !Array.isArray(data.embedding)) {
      throw new Error('Invalid embedding vector returned from Ollama');
    }

    return data.embedding;
  }
}

export const defaultLLMProvider = new OllamaProvider();
