import { vectorStore } from './vector_store.js';
import { defaultLLMProvider } from './providers/ollama.provider.js';
import { AIKSETRA_KNOWLEDGE_BASE } from './knowledge_base.js';
import { AICitation, AIDocumentChunk } from './ai.types.js';

export class RAGService {
  private isInitialized = false;

  public async seedKnowledgeBase(force = false): Promise<{ docCount: number; chunkCount: number }> {
    const existingCount = await vectorStore.getDocumentCount();
    if (existingCount > 0 && !force) {
      this.isInitialized = true;
      const chunkCount = await vectorStore.getChunkCount();
      return { docCount: existingCount, chunkCount };
    }

    if (force) {
      await vectorStore.clearAll();
    }

    let totalChunks = 0;
    for (const doc of AIKSETRA_KNOWLEDGE_BASE) {
      const docId = await vectorStore.insertDocument(doc);
      const chunks = await this.chunkDocument(doc.content, doc.title, doc.category);
      await vectorStore.insertChunks(docId, chunks);
      totalChunks += chunks.length;
    }

    this.isInitialized = true;
    return { docCount: AIKSETRA_KNOWLEDGE_BASE.length, chunkCount: totalChunks };
  }

  private async chunkDocument(content: string, title: string, category: string): Promise<AIDocumentChunk[]> {
    // Split by paragraphs or logical sections
    const paragraphs = content.split(/\n\s*\n/).filter((p) => p.trim().length > 0);
    const chunks: AIDocumentChunk[] = [];

    for (let i = 0; i < paragraphs.length; i++) {
      const text = paragraphs[i].trim();
      let embedding: number[] | undefined;

      try {
        embedding = await defaultLLMProvider.embed(text);
      } catch (err) {
        console.warn(`[RAG] Embedding generation skipped for chunk ${i} of "${title}":`, (err as Error).message);
      }

      chunks.push({
        chunkIndex: i,
        content: text,
        embedding,
        metadata: { title, category },
      });
    }

    return chunks;
  }

  public async retrieve(query: string, topK = 3): Promise<AICitation[]> {
    let queryEmbedding: number[] | undefined;
    try {
      queryEmbedding = await defaultLLMProvider.embed(query);
    } catch {
      // Fallback to text similarity if embedding server is busy
    }

    return vectorStore.searchSimilar(queryEmbedding, query, topK);
  }
}

export const ragService = new RAGService();
