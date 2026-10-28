import pg from 'pg';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const { Client } = pg;

export async function runMigrations() {
  const adminClient = new Client({
    host: process.env.PG_HOST || 'localhost',
    port: parseInt(process.env.PG_PORT || '5432', 10),
    user: process.env.PG_USER || 'postgres',
    password: process.env.PG_PASSWORD || 'root',
    database: 'postgres',
  });

  try {
    await adminClient.connect();
    const res = await adminClient.query("SELECT 1 FROM pg_database WHERE datname='aiksetra_db'");
    if (res.rowCount === 0) {
      console.log('Creating database aiksetra_db...');
      await adminClient.query('CREATE DATABASE aiksetra_db');
    }
  } catch (err: any) {
    console.warn('Admin DB check skipped/failed:', err.message);
  } finally {
    await adminClient.end().catch(() => {});
  }

  const dbClient = new Client({
    connectionString: process.env.DATABASE_URL || 'postgresql://postgres:root@localhost:5432/aiksetra_db',
  });

  await dbClient.connect();
  const migrations = ['001_init.sql', '002_ai.sql'];
  for (const file of migrations) {
    const sqlPath = path.join(__dirname, 'migrations', file);
    if (fs.existsSync(sqlPath)) {
      const sql = fs.readFileSync(sqlPath, 'utf-8');
      await dbClient.query(sql);
      if (file === '001_init.sql') {
        await dbClient.query('ALTER TABLE ledger_entries DROP CONSTRAINT IF EXISTS ledger_entries_transaction_id_fkey;');
        await dbClient.query('ALTER TABLE collect_requests DROP CONSTRAINT IF EXISTS collect_requests_txn_id_fkey;');
      }
      console.log(`✅ PostgreSQL Schema migration (${file}) applied successfully.`);
    }
  }
  await dbClient.end();
}

if (process.argv[1] && process.argv[1].endsWith('migrate.ts')) {
  runMigrations().catch((e) => {
    console.error('Migration failed:', e);
    process.exit(1);
  });
}
