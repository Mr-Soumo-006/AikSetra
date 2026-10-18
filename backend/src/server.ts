import express from 'express';
import cors from 'cors';
import http from 'http';
import path from 'path';
import { WebSocketServer } from 'ws';
import { config } from './config/index.js';
import { runSeed } from './db/seed.js';
import { apiRouter } from './routes/api.router.js';
import { soundboxService } from './services/soundbox.service.js';
import { MerchantService } from './services/merchant.service.js';

// Auto-seed if running fresh
runSeed(false);

const app = express();
const server = http.createServer(app);

// Initialize WebSocket server for Soundbox audio stream
const wss = new WebSocketServer({ server, path: '/ws/soundbox' });

wss.on('connection', (ws) => {
  soundboxService.registerWsClient(ws);
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve Developer & Switch Testing Console
const consoleDir = path.resolve(process.cwd(), 'src/public/console');
app.use('/console', express.static(consoleDir));

// Root redirect to console
app.get('/', (req, res) => {
  res.redirect('/console');
});

// Mobile Payment Link landing page
app.get('/pay/:id', (req, res) => {
  const payLink = MerchantService.getPayLink(req.params.id);
  if (!payLink) {
    return res.status(404).send('<h1>Payment Link Not Found or Expired</h1>');
  }

  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Pay ${payLink.merchantName} | Bharat One Pay</title>
      <script src="https://cdn.tailwindcss.com"></script>
    </head>
    <body class="bg-slate-900 text-slate-100 flex items-center justify-center min-h-screen p-4 font-sans">
      <div class="bg-slate-800 border border-slate-700 rounded-2xl max-w-sm w-full p-6 text-center shadow-2xl space-y-4">
        <div class="w-12 h-12 mx-auto rounded-full bg-orange-500/20 text-orange-400 flex items-center justify-center font-black text-xl">₹</div>
        <div>
          <h2 class="text-xs uppercase tracking-wider text-slate-400 font-bold">Paying to</h2>
          <h1 class="text-xl font-bold text-white mt-0.5">${payLink.merchantName}</h1>
          <p class="text-xs text-slate-400 mt-1">${payLink.description}</p>
        </div>

        <div class="py-4 border-y border-slate-700/60">
          <div class="text-3xl font-black text-emerald-400">₹${payLink.amount.toFixed(2)}</div>
        </div>

        ${payLink.qrCodeDataUrl ? `
          <div>
            <img src="${payLink.qrCodeDataUrl}" alt="Bharat QR" class="w-48 h-48 mx-auto rounded-xl bg-white p-2" />
            <p class="text-[11px] text-slate-400 mt-2">Scan with any UPI App (Bharat One Pay, BHIM, GPay, PhonePe)</p>
          </div>
        ` : ''}

        <a href="${payLink.upiIntentUrl}" class="block w-full bg-emerald-600 hover:bg-emerald-500 text-white font-bold py-3 rounded-xl transition text-sm">
          Open in Bharat One Pay / UPI App
        </a>
      </div>
    </body>
    </html>
  `);
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ONLINE',
    service: 'AikSetra Switch & Core Banking Platform',
    meaning: 'A shared financial space; inspired by ek (one) and kshetra (domain or field)',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    node: process.version,
    env: config.nodeEnv,
  });
});

// API Routes
app.use('/api/v1', apiRouter);

// Start server
server.listen(config.port, config.host, () => {
  console.log('===========================================================');
  console.log(`✨ AikSetra Core Banking & Switch Service is running!`);
  console.log(`   A shared financial space; inspired by ek and kshetra`);
  console.log(`📡 Base URL:          http://localhost:${config.port}`);
  console.log(`🖥️ Developer Console:  http://localhost:${config.port}/console`);
  console.log(`⚡ API Endpoints:      http://localhost:${config.port}/api/v1/...`);
  console.log(`🔊 Soundbox WS:       ws://localhost:${config.port}/ws/soundbox`);
  console.log('===========================================================');
});
