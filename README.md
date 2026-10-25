# ✨ AikSetra (एक क्षेत्र)

> **A Unified, Next-Generation Indian Financial Space**  
> *Derived from **ek** (one / unified) and **kshetra** (domain, field, or sphere).*

[![Flutter](https://img.shields.io/badge/Flutter-3.47%2B-02569B.svg?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13%2B-0175C2.svg?logo=dart&logoColor=white)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-22%2B-339933.svg?logo=node.js&logoColor=white)](https://nodejs.org)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.0%2B-3178C6.svg?logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![UPI 2.0](https://img.shields.io/badge/UPI-2.0%20NPCI%20Ready-FF671F.svg)](https://www.npci.org.in)
[![BBPS](https://img.shields.io/badge/BBPS-Bharat%20BillPay%20Enabled-008080.svg)](https://www.bharatbillpay.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 🏛️ About AikSetra

**AikSetra** is a complete, production-grade Indian financial ecosystem combining authentic **NPCI UPI 2.0 payments**, **BBPS utility billing with real SERC tariff calculations**, **wealth creation (Indian Stock Market & Bank SIPs)**, **RBI LRS-compliant Global FX remittances**, and **biometric zero-trust security**.

Designed from the ground up to eliminate fintech complexity, AikSetra replaces confusing jargon with transparent everyday banking, instant local-network settlement, and complete regulatory integrity.

```
                  ┌─────────────────────────────────────────────────────────┐
                  │                  ✨ AikSetra Ecosystem                  │
                  │                (A Shared Financial Space)               │
                  └────────────────────────────┬────────────────────────────┘
                                               │
         ┌───────────────────┬─────────────────┴─────────────────┬───────────────────┐
         ▼                   ▼                                   ▼                   ▼
 ┌───────────────┐   ┌───────────────┐                   ┌───────────────┐   ┌───────────────┐
 │  Core UPI 2.0 │   │ BBPS Utility  │                   │ Wealth & SIPs │   │ Global FX Rem │
 │ SIM Binding & │   │ SERC Tariffs  │                   │ NSE/BSE Stocks│   │ RBI LRS Taxes │
 │ Self Transfer │   │ Elect/Gas/Wat │                   │ Mutual Funds  │   │ 10-Min FX Lock│
 └───────────────┘   └───────────────┘                   └───────────────┘   └───────────────┘
```

---

## 🌟 Key Features & Architecture

### 1. Authentic UPI 2.0 & Device Binding Architecture
- **NPCI SIM-Binding Architecture:** Authentic dual-SIM detection (Jio vs Airtel) with simulated carrier SMS token handshakes.
- **Realistic Account-to-Account Settlement:** True to NPCI UPI architecture, AikSetra avoids artificial wallet deposits. All settlements occur bank-to-bank via:
  - **Self Transfer:** Instant transfers between your own linked bank accounts (e.g., SBI to HDFC).
  - **Check Balance:** Authenticated live CBS balance queries using your 4-digit UPI MPIN or biometric fingerprint.
- **Executive Profile & Account Modal:** Tapping the header ("Namaste, Soumo") displays full NPCI KYC verification status, primary bank details, masked account number, IFSC code, UPI ID (`soumo@aiksetra`) with 1-tap copy, daily limit tracker (₹1,00,000/day), and personal payment QR code.

### 2. Bharat BillPay (BBPS) with Real SERC Tariff Formulations
- **Official SERC Electricity Tariff Slabs:** Unlike apps that generate arbitrary bill amounts, AikSetra implements real State Electricity Regulatory Commission (SERC) telescopic billing:
  - Meter Number & kWh consumed calculation.
  - Slab 1 (0–100 kWh @ ₹4.15/kWh), Slab 2 (101–300 kWh @ ₹5.85/kWh), Slab 3 (>300 kWh @ ₹7.10/kWh).
  - Sanctioned load fixed charges (₹110.00).
  - 6% State Electricity Duty itemized on bill statements.
- **Complete Utility Suite:** Piped LPG Gas cylinders, Water utility consumption slabs, High-speed Fiber Broadband, Mobile Postpaid, and FASTag toll recharge.

### 3. Wealth Creation: Indian Stock Market (NSE / BSE) & Auto-SIPs
- **NSE / BSE Bluechip Watchlist:** Live real-time market tracker for top Indian enterprises: Reliance Industries, TCS, HDFC Bank, Infosys, Tata Motors, ITC, L&T, and Bharti Airtel with day gain/loss percentage indicators.
- **1-Tap "Buy Share":** Select quantity, view real-time debit calculation from your primary bank, and execute orders with UPI MPIN authorization.
- **Stock SIP & Mutual Fund SIPs:** Automate equity and mutual fund investments via NPCI UPI Autopay mandates (e.g., monthly debit on the 5th).
- **24K Digital Gold SIP:** Real-time 99.9% pure gold vault accumulation.

### 4. Global FX Remittance with RBI LRS Tax Breakdown
- **Send Money Abroad in INR:** Supports major global currency corridors: **USD**, **EUR**, **GBP**, **AED**, and **SGD**.
- **Full RBI Liberalised Remittance Scheme (LRS) Compliance:**
  - Guaranteed live mid-market exchange rate with 10-minute lock.
  - Base converted currency equivalent.
  - Authorized Dealer (AD) Bank Margin (0.15%).
  - GST on Forex Currency Conversion under Rule 32(2)(b) of CGST Rules.
  - Tax Collected at Source (TCS) itemization under Section 206C(1G) of the Income Tax Act.

### 5. Multi-Language Localization
- Working in-app localization supporting 5 major Indian languages: **English (`en-IN`)**, **Hindi (`hi-IN` - हिन्दी)**, **Bengali (`bn-IN` - বাংলা)**, **Tamil (`ta-IN` - தமிழ்)**, and **Telugu (`te-IN` - తెలుగు)**.
- Selecting a language from the top bar immediately updates navigation tabs, greetings, transaction headers, and utility bill screens in real-time.

### 6. Clean Payment Provider Architecture (Demo vs. Real Settlement)
- **Architectural Separation:** Strict separation between `IPaymentProvider` implementations:
  - **Demo Provider (`PspSimulatorProvider`):** Used during local development and demonstrations. Emulates bank latency and switch responses. Crucially, its responses are strictly tagged with `settlementType: 'DEMO_SIMULATION'` and `status: 'SIMULATED_SUCCESS'`, guaranteeing simulated payments can never be mislabeled as confirmed bank settlements.
  - **Real Provider Adapter (`RealPspAdapter`):** Connects to authorized banking PSP partner switches (Setu, YesBank, Razorpay UPI). Enforces production startup validation and bank certificate authorization.
- **Server-Authoritative Provider Selection:** Provider selection is determined strictly by server configuration (`isProduction`, environment credentials), never by client parameters.

### 7. Production PostgreSQL Database & ACID Ledger
- **PostgreSQL Database Engine:** Backed by PostgreSQL (`aiksetra_db`) running with atomic SQL transactions (`BEGIN`/`COMMIT`/`ROLLBACK`), strict foreign keys, and CHECK constraints.
- **Double-Entry Ledger:** Balanced debit and credit journal entries with per-account row mutexes (`AccountLockManager`), eliminating race conditions and double-spending.
- **Durable Idempotency Keys:** Unique database-enforced idempotency key reservation with automatic expiration and duplicate suppression.
- **Automated Crash Recovery:** Background recovery worker detects and resolves orphaned or in-flight transactions safely.

### 8. Two-Phone Local Network Settlement & Demo Transparency
- **P2P Transfer Over Local Wi-Fi:** Real-time transfer between two smartphones connected to the same network via standard ISO-18004 UPI QR codes.
- **Demo Mode Transparency:** UI clearly displays `"Demo payment — no real money transferred"` on QR codes, authorization sheets, and confirmation banners.
- **Instant Beneficiary Notification:** Real-time balance queries and transaction feed updates immediately upon transfer completion.

### 9. Enterprise Financial Integrity & Security Core
- **Double-Entry Ledger Architecture:** Full balanced accounting ledger with concurrent `DEBIT` and `CREDIT` entries for all transfers, investments, and utility payments.
- **Per-Account Concurrency Mutex:** `AccountLockManager` ensures parallel incoming requests to the same bank account are processed sequentially, eliminating race conditions and double-spending.
- **PBKDF2 Salted MPIN Verifiers:** Replaced plain hashes with 100,000 iterations of salted PBKDF2-HMAC-SHA256, attempt tracking, and 5-minute lockout security after 3 consecutive failures.
- **Durable Idempotency & Reconciliations:** Database-enforced idempotency prevents duplicate debits on network retries. Built-in audit logging (SHA-256 integrity hashes) and reconciliation endpoints (`/ledger/reconcile/:accountId`).
- **Zero Client-Side Fake Success:** Strict server-authoritative payment execution. All client-side mock fallbacks have been removed.

---

## 📁 Repository Structure

```
AikSetra/
├── app-release.apk               # Official Production Release APK
├── AikSetra-latest.apk           # Direct installer copy
├── app/                          # Flutter Mobile Application (Android & iOS)
│   ├── android/                  # Native Android configuration (API 34+ ready)
│   │   └── app/src/main/res/     # Custom AikSetra mipmap app icons
│   ├── lib/
│   │   ├── main.dart             # App entry with authentication state routing
│   │   ├── api_config.dart       # Dynamic backend gateway (192.168.29.90 / localhost)
│   │   ├── models/               # User, Bank, Scam Shield & Cross-Border models
│   │   ├── screens/
│   │   │   ├── login_screen.dart        # 5-step NPCI SIM binding onboarding flow
│   │   │   ├── app_lock_screen.dart     # PIN & Fingerprint biometric screen
│   │   │   └── simple_home_screen.dart  # Core Banking, BBPS, Wealth & FX UI
│   │   ├── services/
│   │   │   ├── bharat_one_pay_api.dart  # Live banking switch service client
│   │   │   └── biometric_service.dart   # Biometric fingerprint integration
│   │   └── utils/
│   │       └── app_translations.dart    # English, Hindi & Bengali localization
│   └── pubspec.yaml              # Flutter dependencies (mobile_scanner, qr_flutter, etc.)
│
├── backend/                      # Node.js + TypeScript Banking Switch & Simulator
│   ├── src/
│   │   ├── server.ts             # Express & WebSocket server initialization
│   │   ├── config/               # Secure environment validation & secret management
│   │   ├── db/
│   │   │   ├── database.ts       # Transactional store with re-entrant mutex
│   │   │   ├── postgres.ts       # PostgreSQL connection pool & SQL adapter
│   │   │   ├── migrations/       # Production schema (001_init.sql)
│   │   │   └── seed.ts           # Baseline verified accounts, PBKDF2 hashes & stocks
│   │   ├── middleware/
│   │   │   ├── auth.middleware.ts       # Strict Bearer JWT & Admin API authentication
│   │   │   └── rateLimit.middleware.ts  # Sliding-window rate limiters (OTP/Auth/Payment)
│   │   ├── services/
│   │   │   ├── auth.service.ts          # PBKDF2 MPIN, SMS OTP & Session management
│   │   │   ├── ledger.service.ts        # Double-entry ledger & per-account concurrency locks
│   │   │   ├── audit.service.ts         # Append-only SHA-256 hashed audit trail
│   │   │   ├── payment.service.ts       # Core UPI, Idempotency & Scam Shield
│   │   │   ├── providers/               # Formalized Payment Provider Architecture
│   │   │   │   ├── paymentProvider.interface.ts # IPaymentProvider contract
│   │   │   │   ├── pspSimulator.provider.ts     # Demo provider (SIMULATED_SUCCESS)
│   │   │   │   ├── realPsp.adapter.ts           # Authorized partner bank adapter
│   │   │   │   └── provider.factory.ts          # Server-configured provider resolver
│   │   │   └── crossBorder.service.ts   # RBI LRS FX Remittance engine
│   │   ├── tests/                # Automated Test Suite (24 tests)
│   │   │   ├── auth_security.test.ts        # PBKDF2, lockout, and registration tests
│   │   │   ├── api_security.test.ts         # HMAC webhooks, rate limits, input guards
│   │   │   └── financial_integrity.test.ts  # Double-entry ledger, mutex, recovery
│   │   └── routes/api.router.ts  # Hardened REST API endpoints (/api/v1/...)
│   ├── package.json
│   └── tsconfig.json
│
└── README.md                     # Documentation
```

---

## 🚀 Installation & Running

### 📲 Direct APK Installation (Android)
Download and install the pre-compiled release APK directly onto any Android device (Android 8.0+):
- **Path:** [`app-release.apk`](app-release.apk) or [`AikSetra-latest.apk`](AikSetra-latest.apk)

---

### 💻 Running from Source

#### 1. Start the Backend Banking Switch
```bash
cd backend
npm install
npm run build
npm run seed     # Initializes verified bank accounts, PBKDF2 hashes & BBPS billers
npm start        # Launches switch on http://0.0.0.0:4000
```

#### 2. Run the Flutter Mobile App
```bash
cd app
flutter pub get
flutter run --release
```

---

## 🛡️ Security & Regulatory Compliance
- **PBKDF2-HMAC-SHA256:** UPI MPIN verifiers use 100,000 salted iterations with 3-attempt lockouts; plaintext is never stored or transmitted.
- **Strict Bearer JWT:** All client APIs require valid signed bearer tokens; production header bypasses (`x-user-id`) are prohibited.
- **Biometric Authentication:** Local device biometric authentication protects app unlock and 1-tap UPI authorization.
- **DPDP Act 2023 & NPCI CL Guidelines:** Compliant user identity, device identifier management, and Common Library specifications.
- **RBI LRS & SERC Adherence:** Remittance calculations adhere to Section 206C(1G) and Rule 32(2)(b); utility formulas adhere to SERC slab guidelines.

---

## 🤝 Contributing & License
Distributed under the **MIT License**. Created with ❤️ by **Soumo Naskar**.
