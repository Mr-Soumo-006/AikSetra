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
  const sqlPath = path.join(__dirname, 'migrations', '001_init.sql');
  if (fs.existsSync(sqlPath)) {
    const sql = fs.readFileSync(sqlPath, 'utf-8');
    await dbClient.query(sql);
    console.log('✅ PostgreSQL Schema migrations (001_init.sql) applied successfully.');
  }
  await dbClient.end();
}

if (process.argv[1] && process.argv[1].endsWith('migrate.ts')) {
  runMigrations().catch((e) => {
    console.error('Migration failed:', e);
    process.exit(1);
  });
}
