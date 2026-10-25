import type { DatabaseSchema } from './database.js';

/**
 * Unified Database Interface
 * Abstracts storage operations so production deployments can switch seamlessly
 * between JsonDatabase (embedded/development) and PostgreSQL / CockroachDB (enterprise ACID).
 */
export interface IDatabase {
  get<K extends keyof DatabaseSchema>(collection: K): DatabaseSchema[K];
  insert<K extends keyof DatabaseSchema>(
    collection: K,
    item: DatabaseSchema[K] extends Array<infer U> ? U : never
  ): DatabaseSchema[K] extends Array<infer U> ? U : never;
  update<K extends keyof DatabaseSchema>(
    collection: K,
    predicate: (item: any) => boolean,
    updater: Partial<any>
  ): any | null;
  transaction<T>(operation: () => Promise<T>): Promise<T>;
  reserveIdempotencyKey(key: string, ttlMs?: number): boolean | Promise<boolean>;
  releaseIdempotencyKey(key: string): void | Promise<void>;
  save(): void | Promise<void>;
}
