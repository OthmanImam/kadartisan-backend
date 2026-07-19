import 'dotenv/config';
import { readFileSync } from 'node:fs';
import { createHash, randomUUID } from 'node:crypto';
import { join } from 'node:path';
import pg from 'pg';

// The migration to apply is passed as argv[2] (folder name under prisma/migrations).
const MIGRATION = process.argv[2];
if (!MIGRATION) {
  console.error('Usage: node scripts/apply-migration.mjs <migration_folder_name>');
  process.exit(1);
}

const sqlPath = join(process.cwd(), 'prisma', 'migrations', MIGRATION, 'migration.sql');
const sql = readFileSync(sqlPath, 'utf8');
const checksum = createHash('sha256').update(readFileSync(sqlPath)).digest('hex');

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

const client = await pool.connect();
try {
  await client.query(`
    CREATE TABLE IF NOT EXISTS "_prisma_migrations" (
      id                      VARCHAR(36) PRIMARY KEY NOT NULL,
      checksum                VARCHAR(64) NOT NULL,
      finished_at             TIMESTAMPTZ,
      migration_name          VARCHAR(255) NOT NULL,
      logs                    TEXT,
      rolled_back_at          TIMESTAMPTZ,
      started_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
      applied_steps_count     INTEGER NOT NULL DEFAULT 0
    );
  `);

  const { rows } = await client.query(
    'SELECT 1 FROM "_prisma_migrations" WHERE migration_name = $1 AND rolled_back_at IS NULL',
    [MIGRATION],
  );
  if (rows.length > 0) {
    console.log('Migration already recorded as applied. Nothing to do.');
    process.exit(0);
  }

  console.log('Applying migration', MIGRATION, '...');
  // Apply exactly like Prisma's migrate runner: send the whole file in one
  // simple-query call. Do NOT wrap in an outer transaction — the file contains
  // its own explicit BEGIN/COMMIT block and ALTER TYPE ... ADD VALUE statements
  // that must run in autocommit.
  await client.query(sql);

  await client.query(
    `INSERT INTO "_prisma_migrations"
       (id, checksum, migration_name, started_at, finished_at, applied_steps_count)
     VALUES ($1, $2, $3, now(), now(), 1)`,
    [randomUUID(), checksum, MIGRATION],
  );
  console.log('Migration applied and recorded successfully.');
} catch (err) {
  console.error('Failed to apply migration:', err.message);
  process.exit(1);
} finally {
  client.release();
  await pool.end();
}
