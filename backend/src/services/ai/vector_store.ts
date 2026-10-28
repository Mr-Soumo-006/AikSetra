import pg from 'pg';
import { AIDocument, AIDocumentChunk, AICitation } from './ai.types.js';

const { Pool } = pg;

export class VectorStore {
  private pool: pg.Pool;

  constructor() {
    this.pool = new Pool({
      connectionString: process.env.DATABASE_URL || 'postgresql://postgres:root@localhost:5432/aiksetra_db',
    });
  }

  public async insertDocument(doc: AIDocument): Promise<string> {
    const res = await this.pool.query(
      `INSERT INTO ai_documents (title, category, version, metadata)
       VALUES ($1, $2, $3, $4)
       RETURNING id`,
      [doc.title, doc.category, doc.version || '1.0', JSON.stringify(doc.metadata || {})]
    );
    return res.rows[0].id;
  }

  public async insertChunks(documentId: string, chunks: AIDocumentChunk[]): Promise<void> {
    for (const chunk of chunks) {
      await this.pool.query(
        `INSERT INTO ai_document_chunks (document_id, chunk_index, content, embedding, metadata)
         VALUES ($1, $2, $3, $4, $5)`,
        [
          documentId,
          chunk.chunkIndex,
          chunk.content,
          chunk.embedding || null,
          JSON.stringify(chunk.metadata || {}),
        ]
      );
    }
  }

  public async clearAll(): Promise<void> {
    await this.pool.query('DELETE FROM ai_documents');
  }

  public async getDocumentCount(): Promise<number> {
    const res = await this.pool.query('SELECT COUNT(*)::int AS count FROM ai_documents');
    return res.rows[0]?.count || 0;
  }

  public async getChunkCount(): Promise<number> {
    const res = await this.pool.query('SELECT COUNT(*)::int AS count FROM ai_document_chunks');
    return res.rows[0]?.count || 0;
  }

  private cosineSimilarity(a: number[], b: number[]): number {
    let dot = 0;
    let normA = 0;
    let normB = 0;
    for (let i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA === 0 || normB === 0) return 0;
    return dot / (Math.sqrt(normA) * Math.sqrt(normB));
  }

  public async searchSimilar(
    queryEmbedding?: number[],
    queryText?: string,
    topK = 4
  ): Promise<AICitation[]> {
    const res = await this.pool.query(
      `SELECT c.id, c.document_id, c.chunk_index, c.content, c.embedding,
              d.title, d.category,
              CASE WHEN $1::text IS NOT NULL THEN similarity(c.content, $1::text) ELSE 0 END AS text_sim
       FROM ai_document_chunks c
       JOIN ai_documents d ON c.document_id = d.id
       ORDER BY text_sim DESC
       LIMIT 50`,
      [queryText || null]
    );

    const scored: Array<{
      citation: AICitation;
      score: number;
    }> = [];

    for (const row of res.rows) {
      let vecScore = 0;
      if (queryEmbedding && row.embedding && Array.isArray(row.embedding)) {
        vecScore = this.cosineSimilarity(queryEmbedding, row.embedding);
      }
      const textScore = Number(row.text_sim) || 0;
      // Hybrid score: 70% vector semantic similarity, 30% text/trigram keyword match
      const finalScore = queryEmbedding ? vecScore * 0.7 + textScore * 0.3 : textScore;

      scored.push({
        score: finalScore,
        citation: {
          documentId: row.document_id,
          title: row.title,
          category: row.category,
          snippet: row.content,
          relevanceScore: parseFloat(finalScore.toFixed(3)),
        },
      });
    }

    scored.sort((a, b) => b.score - a.score);
    return scored.slice(0, topK).map((s) => s.citation);
  }
}

export const vectorStore = new VectorStore();
