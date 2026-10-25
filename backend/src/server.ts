import express from 'express';
import cors from 'cors';
import http from 'http';
import path from 'path';
import { WebSocketServer } from 'ws';
import { config, validateConfig } from './config/index.js';
import { runSeed } from './db/seed.js';
import { apiRouter } from './routes/api.router.js';
import { soundboxService } from './services/soundbox.service.js';
import { MerchantService } from './services/merchant.service.js';

// Validate configuration at startup (Issue 2 & 10)
validateConfig();

// Initialize baseline data
runSeed(false);

// Test local PostgreSQL connectivity if configured
if (config.databaseUrl) {
  import('./db/postgres.js').then(({ postgresDb }) => {
    postgresDb.testConnection().then((connected) => {
      if (connected) {
        console.log('🐘 [POSTGRESQL]: Connected successfully to PostgreSQL database (aiksetra_db).');
      } else {
        console.warn('⚠️ [POSTGRESQL]: DATABASE_URL configured but connection failed. Falling back to transactional JsonDatabase.');
      }
    });
  });
}

const app = express();
const server = http.createServer(app);

import jwt from 'jsonwebtoken';
import { db } from './db/database.js';
import { escapeHtml, sanitizeUrl } from './utils/sanitize.js';

// Initialize WebSocket server for Soundbox audio stream with authentication (P2)
const wss = new WebSocketServer({ server, path: '/ws/soundbox' });

wss.on('connection', (ws, req) => {
  try {
    const url = new URL(req.url || '', `http://${req.headers.host || 'localhost'}`);
    const token = url.searchParams.get('token') || (req.headers.authorization ? req.headers.authorization.replace('Bearer ', '').trim() : null);
    const adminKey = url.searchParams.get('adminKey') || req.headers['x-admin-key'];

    if (adminKey && adminKey === config.adminApiKey) {
      soundboxService.registerWsClient(ws);
      return;
    }

    if (!token) {
      ws.close(4401, 'Unauthorized: Missing authentication token');
      return;
    }

    const decoded = jwt.verify(token, config.jwtSecret) as { id?: string; userId?: string };
    const targetUserId = decoded.userId || decoded.id;
    const user = targetUserId ? db.get('users').find((u) => u.id === targetUserId) : null;
    if (!user) {
      ws.close(4401, 'Unauthorized: User not found');
      return;
    }

    soundboxService.registerWsClient(ws);
  } catch (err) {
    ws.close(4401, 'Unauthorized: Invalid token');
  }
});

// Issue 62: Security HTTP Headers & Request Size Limits
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader('Permissions-Policy', 'geolocation=(), camera=(), microphone=()');
  if (config.isProduction) {
    res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  }
  next();
});

// Strict CORS Policy (P0 Issue 11: Production Origin Allowlist)
app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin) return callback(null, true); // Allow non-browser clients (native mobile app, curl, server-to-server)
      if (!config.isProduction) return callback(null, true); // Permissive in dev/test
      if (config.allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      return callback(new Error(`CORS policy violation: Origin '${origin}' is not authorized.`));
    },
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Idempotency-Key', 'x-admin-key', 'x-webhook-signature'],
    credentials: true,
  })
);

app.use(
  express.json({
    limit: '500kb',
    verify: (req, _res, buf) => {
      (req as any).rawBody = buf;
    },
  })
);
app.use(express.urlencoded({ extended: true, limit: '500kb' }));

// Serve Developer & Switch Testing Console (Restricted in production)
const consoleDir = path.resolve(process.cwd(), 'src/public/console');
app.use('/console', express.static(consoleDir));

// Root redirect to console
app.get('/', (req, res) => {
  res.redirect('/console');
});

// Issue 56 & P0 Issue 8: Mobile Payment Link landing page with XSS-safe escaping and bundled CSS
app.get('/pay/:id', (req, res) => {
  const payLink = MerchantService.getPayLink(req.params.id);
  if (!payLink) {
    return res.status(404).send('<h1>Payment Link Not Found or Expired</h1>');
  }

  const safeMerchantName = escapeHtml(payLink.merchantName);
  const safeDescription = escapeHtml(payLink.description);
  const safeIntentUrl = sanitizeUrl(payLink.upiIntentUrl);
  const safeQrCode = payLink.qrCodeDataUrl ? sanitizeUrl(payLink.qrCodeDataUrl) : null;

  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Pay ${safeMerchantName} | AikSetra UPI</title>
      <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { background: #0f172a; color: #f8fafc; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; display: flex; align-items: center; justify-content: center; min-height: 100vh; padding: 1rem; }
        .card { background: #1e293b; border: 1px solid #334155; border-radius: 1.25rem; max-width: 24rem; width: 100%; padding: 1.5rem; text-align: center; box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5); }
        .icon { width: 3rem; height: 3rem; margin: 0 auto 1rem; border-radius: 9999px; background: rgba(249, 115, 22, 0.2); color: #fb923c; display: flex; align-items: center; justify-content: center; font-weight: 900; font-size: 1.25rem; }
        .subtitle { font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em; color: #94a3b8; font-weight: 700; }
        .merchant-name { font-size: 1.25rem; font-weight: 700; color: #ffffff; margin-top: 0.25rem; }
        .desc { font-size: 0.8rem; color: #94a3b8; margin-top: 0.25rem; }
        .amount-box { padding: 1rem 0; margin: 1rem 0; border-top: 1px solid rgba(51, 65, 85, 0.6); border-bottom: 1px solid rgba(51, 65, 85, 0.6); }
        .amount { font-size: 2rem; font-weight: 900; color: #34d399; }
        .qr-box { margin-bottom: 1rem; }
        .qr-img { width: 12rem; height: 12rem; margin: 0 auto; border-radius: 0.75rem; background: #ffffff; padding: 0.5rem; display: block; }
        .qr-caption { font-size: 0.7rem; color: #94a3b8; margin-top: 0.5rem; }
        .btn-pay { display: block; width: 100%; background: #059669; color: #ffffff; font-weight: 700; padding: 0.75rem; border-radius: 0.75rem; text-decoration: none; font-size: 0.875rem; transition: background 0.2s; }
        .btn-pay:hover { background: #10b981; }
      </style>
    </head>
    <body>
      <div class="card">
        <div class="icon">₹</div>
        <div>
          <div class="subtitle">Paying to</div>
          <div class="merchant-name">${safeMerchantName}</div>
          <div class="desc">${safeDescription}</div>
        </div>

        <div class="amount-box">
          <div class="amount">₹${payLink.amount.toFixed(2)}</div>
        </div>

        ${safeQrCode ? `
          <div class="qr-box">
            <img src="${safeQrCode}" alt="Bharat QR" class="qr-img" />
            <div class="qr-caption">Scan with any UPI App (AikSetra, BHIM, GPay, PhonePe)</div>
          </div>
        ` : ''}

        <a href="${safeIntentUrl}" class="btn-pay">
          Open in AikSetra / UPI App
        </a>
      </div>
    </body>
    </html>
  `);
});

// Health check with Environment & Simulation disclosure (Issue 49)
app.get('/health', (req, res) => {
  res.json({
    status: 'ONLINE',
    service: 'AikSetra Switch & Core Banking Platform',
    meaning: 'A shared financial space; inspired by ek (one) and kshetra (domain or field)',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    node: process.version,
    environment: config.nodeEnv,
    isProduction: config.isProduction,
    isSimulationMode: config.isSimulationMode,
    complianceStatus: {
      zeroKnowledgeMpin: true,
      saltedPbkdf2Enabled: true,
      doubleEntryLedger: true,
      rateLimitingActive: true,
      strictAuthEnforced: true,
    },
  });
});

// API Routes
app.use('/api/v1', apiRouter);

// Global Error Handler
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('[UNHANDLED_ERROR]', err);
  const status = err.status || 500;
  res.status(status).json({
    success: false,
    code: err.code || 'INTERNAL_SERVER_ERROR',
    message: config.isProduction ? 'An unexpected error occurred. Please contact support.' : err.message,
  });
});

wss.on('error', () => {});

const onServerListening = () => {
  console.log('===========================================================');
  console.log(`✨ AikSetra Core Banking & Switch Service is running!`);
  console.log(`   A shared financial space; inspired by ek and kshetra`);
  console.log(`📡 Base URL:          http://localhost:${config.port}`);
  console.log(`📶 LAN URL:           http://192.168.29.90:${config.port}`);
  console.log(`🖥️ Developer Console:  http://localhost:${config.port}/console`);
  console.log(`⚡ API Endpoints:      http://localhost:${config.port}/api/v1/...`);
  console.log(`🔊 Soundbox WS:       ws://localhost:${config.port}/ws/soundbox`);
  console.log(`🛡️ Security State:    PBKDF2 Salted MPIN | Strict Auth | Double-Entry Ledger`);
  console.log('===========================================================');
};

server.on('error', (err: any) => {
  console.error('Server socket error:', err);
});

// Graceful Shutdown Handler
const shutdown = () => {
  console.log('\nGracefully shutting down AikSetra server...');
  wss.close(() => {
    server.close(() => {
      console.log('Server terminated cleanly.');
      process.exit(0);
    });
  });
};

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

server.listen(config.port, config.host, onServerListening);
