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
  fraudRegistry: [],
};

class JsonDatabase {
  private filePath: string;
  private data: DatabaseSchema;

  constructor() {
    const dir = path.resolve(process.cwd(), config.dataDir);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    this.filePath = path.join(dir, 'aiksetra_db.json');

    if (fs.existsSync(this.filePath)) {
      try {
        const raw = fs.readFileSync(this.filePath, 'utf-8');
        this.data = { ...defaultDatabase, ...JSON.parse(raw) };
      } catch (e) {
        console.warn('Could not parse existing database, initializing fresh one.', e);
        this.data = defaultDatabase;
        this.persist();
      }
    } else {
      this.data = defaultDatabase;
      this.persist();
    }
  }

  private persist(): void {
    try {
      fs.writeFileSync(this.filePath, JSON.stringify(this.data, null, 2), 'utf-8');
    } catch (err) {
      console.error('Failed to persist database:', err);
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
    this.persist();
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
    this.persist();
    return list[idx];
  }

  public save(): void {
    this.persist();
  }

  public reset(newData?: DatabaseSchema): void {
    this.data = newData || defaultDatabase;
    this.persist();
  }
}

export const db = new JsonDatabase();
