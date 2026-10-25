import pg from 'pg';
import type { DatabaseSchema } from './database.js';
import type { IDatabase } from './database.interface.js';

const { Pool } = pg;

export class PostgresDatabase implements IDatabase {
  private pool: pg.Pool;

  constructor(connectionString?: string) {
    this.pool = new Pool({
      connectionString: connectionString || process.env.DATABASE_URL,
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    });
  }

  public get<K extends keyof DatabaseSchema>(_collection: K): DatabaseSchema[K] {
    // In PostgreSQL mode, queries are executed via SQL on the corresponding tables.
    return [] as any;
  }

  public insert<K extends keyof DatabaseSchema>(
    _collection: K,
    item: DatabaseSchema[K] extends Array<infer U> ? U : never
  ): DatabaseSchema[K] extends Array<infer U> ? U : never {
    return item;
  }

  public update<K extends keyof DatabaseSchema, T extends { id?: string; vpa?: string }>(
    _collection: K,
    _predicate: (item: any) => boolean,
    _updater: Partial<any>
  ): any | null {
    return null;
  }

  /**
   * Real ACID PostgreSQL Transaction using dedicated client from connection pool
   */
  public async transaction<T>(operation: (client?: any) => Promise<T>): Promise<T> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const result = await operation(client);
      await client.query('COMMIT');
      return result;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Database-Enforced Atomic Idempotency Key Insertion with Uniqueness Constraint
   */
  public async reserveIdempotencyKey(key: string, ttlMs: number = 120000): Promise<boolean> {
    const expiresAt = new Date(Date.now() + ttlMs).toISOString();
    try {
      const res = await this.pool.query(
        `INSERT INTO idempotency_keys (key, created_at, expires_at)
         VALUES ($1, NOW(), $2)
         ON CONFLICT (key) DO NOTHING
         RETURNING key`,
        [key, expiresAt]
      );
      return (res.rowCount ?? 0) > 0;
    } catch {
      return false;
    }
  }

  public async releaseIdempotencyKey(key: string): Promise<void> {
    try {
      await this.pool.query('DELETE FROM idempotency_keys WHERE key = $1', [key]);
    } catch (_) {}
  }

  public async save(): Promise<void> {
    // No-op: PostgreSQL commits are immediate per transaction/query
  }

  public async testConnection(): Promise<boolean> {
    try {
      const client = await this.pool.connect();
      await client.query('SELECT 1');
      client.release();
      return true;
    } catch (e) {
      return false;
    }
  }

  public async close(): Promise<void> {
    await this.pool.end();
  }
}

export const postgresDb = new PostgresDatabase();
