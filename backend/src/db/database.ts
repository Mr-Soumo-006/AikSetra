import fs from 'fs';
import path from 'path';
import { config } from '../config/index.js';
import type {
  User,
  BankAccount,
  VpaRecord,
  Transaction,
  CollectRequest,
  ProtectedPayEscrow,
  Merchant,
  PayLink,
  MoneyVault,
  SplitBill,
  DisputeTicket,
  LedgerEntry,
  AuditLog,
  IdempotencyRecord,
} from '../types/index.js';

export interface DatabaseSchema {
  users: User[];
  accounts: BankAccount[];
  vpas: VpaRecord[];
  transactions: Transaction[];
  collectRequests: CollectRequest[];
  protectedEscrows: ProtectedPayEscrow[];
  merchants: Merchant[];
  payLinks: PayLink[];
  vaults: MoneyVault[];
  splitBills: SplitBill[];
  disputes: DisputeTicket[];
  ledger: LedgerEntry[];
  auditLogs: AuditLog[];
  idempotencyKeys: IdempotencyRecord[];
  fraudRegistry: Array<{
    vpa: string;
    phone?: string;
    reportCount: number;
    reason: string;
    flaggedAt: string;
  }>;
}

const defaultDatabase: DatabaseSchema = {
  users: [],
  accounts: [],
  vpas: [],
  transactions: [],
  collectRequests: [],
  protectedEscrows: [],
  merchants: [],
  payLinks: [],
  vaults: [],
  splitBills: [],
  disputes: [],
  ledger: [],
  auditLogs: [],
  idempotencyKeys: [],
  fraudRegistry: [],
};

class JsonDatabase {
  private filePath: string;
  private backupPath: string;
  private data: DatabaseSchema;
  private inFlightKeys: Set<string> = new Set();
  private transactionDepth: number = 0;

  constructor() {
    const dir = path.resolve(process.cwd(), config.dataDir);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    this.filePath = path.join(dir, 'aiksetra_db.json');
    this.backupPath = path.join(dir, 'aiksetra_db.bak');

    if (fs.existsSync(this.filePath)) {
      try {
        const raw = fs.readFileSync(this.filePath, 'utf-8');
        const parsed = JSON.parse(raw);
        this.data = {
          ...defaultDatabase,
          ...parsed,
          ledger: parsed.ledger || [],
          auditLogs: parsed.auditLogs || [],
          idempotencyKeys: parsed.idempotencyKeys || [],
        };
      } catch (e) {
        console.warn('Could not parse existing database, trying backup file...', e);
        if (fs.existsSync(this.backupPath)) {
          try {
            const rawBak = fs.readFileSync(this.backupPath, 'utf-8');
            this.data = JSON.parse(rawBak);
            console.log('Successfully recovered database from backup snapshot.');
          } catch {
            this.data = defaultDatabase;
            this.persist();
          }
        } else {
          this.data = defaultDatabase;
          this.persist();
        }
      }
    } else {
      this.data = defaultDatabase;
      this.persist();
    }
  }

  // P1 Issue 28: Crash-Safe Atomic Persistence via Temp-Swap & Rolling Backup
  private persist(): void {
    if (
      this.transactionDepth > 0 ||
      process.env.NODE_ENV === 'test' ||
      Boolean(process.env.NODE_TEST_CONTEXT) ||
      process.argv.some((a) => a.toLowerCase().includes('test'))
    ) {
      return;
    }
    try {
      const serialized = JSON.stringify(this.data, null, 2);
      const tempPath = `${this.filePath}.tmp.${Date.now()}`;

      // 1. Write to temporary file
      fs.writeFileSync(tempPath, serialized, 'utf-8');

      // 2. Atomic swap to production file
      fs.renameSync(tempPath, this.filePath);

      // 3. Keep rolling backup
      try {
        fs.copyFileSync(this.filePath, this.backupPath);
      } catch (_) {}
    } catch (err) {
      console.error('Failed to atomically persist database:', err);
    }
  }

  // P1 Issue 15 & P1 Checklist: Database-Enforced Persistent Idempotency Keys
  public reserveIdempotencyKey(key: string, ttlMs: number = 120000): boolean {
    const now = Date.now();
    this.data.idempotencyKeys = (this.data.idempotencyKeys || []).filter(
      (k) => new Date(k.expiresAt).getTime() > now
    );

    if (this.inFlightKeys.has(key)) return false;
    const existsInDb = this.data.idempotencyKeys.some((k) => k.key === key);
    if (existsInDb) return false;
    const existsInTransactions = this.data.transactions.some((t) => t.idempotencyKey === key);
    if (existsInTransactions) return false;

    this.inFlightKeys.add(key);
    this.data.idempotencyKeys.push({
      key,
      createdAt: new Date().toISOString(),
      expiresAt: new Date(now + ttlMs).toISOString(),
    });

    if (this.transactionDepth === 0) {
      this.persist();
    }
    return true;
  }

  public releaseIdempotencyKey(key: string): void {
    this.inFlightKeys.delete(key);
  }

  // P1 Issue 17 & 27: Transactional Execution with Automatic Rollback (suppresses intermediate persist)
  public async transaction<T>(operation: () => Promise<T>): Promise<T> {
    const snapshot = JSON.stringify(this.data);
    this.transactionDepth++;
    try {
      const result = await operation();
      this.transactionDepth--;
      if (this.transactionDepth === 0) {
        this.persist();
      }
      return result;
    } catch (err) {
      this.transactionDepth--;
      // Roll back in-memory state on failure
      this.data = JSON.parse(snapshot);
      if (this.transactionDepth === 0) {
        this.persist();
      }
      throw err;
    }
  }

  public get<K extends keyof DatabaseSchema>(collection: K): DatabaseSchema[K] {
    return this.data[collection];
  }

  public insert<K extends keyof DatabaseSchema>(
    collection: K,
    item: DatabaseSchema[K] extends Array<infer U> ? U : never
  ): DatabaseSchema[K] extends Array<infer U> ? U : never {
    (this.data[collection] as any[]).push(item);
    if (this.transactionDepth === 0) {
      this.persist();
    }
    return item;
  }

  public update<K extends keyof DatabaseSchema, T extends { id?: string; vpa?: string }>(
    collection: K,
    predicate: (item: any) => boolean,
    updater: Partial<any>
  ): any | null {
    const list = this.data[collection] as any[];
    const idx = list.findIndex(predicate);
    if (idx === -1) return null;
    list[idx] = { ...list[idx], ...updater };
    if (this.transactionDepth === 0) {
      this.persist();
    }
    return list[idx];
  }

  public save(): void {
    if (this.transactionDepth === 0) {
      this.persist();
    }
  }

  public reset(newData?: DatabaseSchema): void {
    this.data = newData || defaultDatabase;
    this.persist();
  }
}

export const db = new JsonDatabase();
