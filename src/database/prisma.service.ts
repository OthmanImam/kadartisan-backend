import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  constructor() {
    const pool = new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: {
        rejectUnauthorized: false,
      },
      // Neon closes idle connections aggressively; recycle ours before it does
      // and keep the socket warm so pooled connections don't go stale.
      max: 10,
      idleTimeoutMillis: 30_000,
      connectionTimeoutMillis: 10_000,
      keepAlive: true,
      maxUses: 7_500,
      allowExitOnIdle: false,
    });

    // A pool-level error handler is required. Without it, an async error on an
    // idle client (e.g. Neon dropping the connection) crashes the process
    // instead of just discarding the dead client.
    pool.on('error', (err) => {
      console.error('Unexpected error on idle Postgres client', err);
    });

    const adapter = new PrismaPg(pool);

    super({ adapter });
  }

  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}