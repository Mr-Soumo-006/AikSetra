# ✨ AikSetra (एक क्षेत्र)

> **A shared financial space**  
> *Inspired by **ek** (one / unified) and **kshetra** (domain, field, or sphere).*

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-22+-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.0+-3178C6?logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![UPI 2.0](https://img.shields.io/badge/UPI-2.0%20NPCI%20Ready-FF671F)](https://www.npci.org.in)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 🏛️ About AikSetra

**AikSetra** is a unified, user-first Indian financial ecosystem combining the simplicity of everyday UPI payments with next-generation banking intelligence. Built from the ground up to eliminate fintech complexity, AikSetra replaces confusing banking jargon with transparent, intuitive everyday protections.

```
                  ┌─────────────────────────────────────────┐
                  │          ✨ AikSetra Ecosystem          │
                  │        (A Shared Financial Space)       │
                  └────────────────────┬────────────────────┘
                                       │
        ┌───────────────────┬──────────┴──────────┬───────────────────┐
        ▼                   ▼                     ▼                   ▼
┌───────────────┐   ┌───────────────┐     ┌───────────────┐   ┌───────────────┐
│  Core UPI 2.0 │   │  Scam Shield  │     │ Protected Pay │   │ Rupee Remit   │
│ SIM Binding & │   │ Real-time AI  │     │ Buyer Escrow  │   │ 10-Min FX Lock│
│ Bank Discovery│   │ Fraud Defense │     │ for Strangers │   │  Global Pay   │
└───────────────┘   └───────────────┘     └───────────────┘   └───────────────┘
```

---

## 🌟 Key Features

### 1. Authentic Indian UPI Onboarding & Device Binding
- **NPCI SIM-Binding Architecture**: Supports dual SIM selection (SIM 1 Jio vs SIM 2 Airtel) with secure SMS token handshake.
- **Automated SMS OTP Verification**: 6-digit OTP verification with SMS user consent integration and resend timers.
- **Account Discovery**: Automatically queries NPCI switches for linked bank accounts (SBI, HDFC, ICICI, etc.) and issues personalized `@aiksetra` UPI IDs.
- **App Security Lock**: Google Pay-style 4-digit App PIN and biometric fingerprint authentication.

### 2. Scam Shield (Suraksha Check)
- Real-time pre-payment risk analysis powered by fraud registry matching and behavioral velocity scoring.
- Proactively flags suspicious payment requests, urgent phishing keywords, unverified high-risk accounts, and spoofed bills before any money leaves your account.

### 3. Protected Pay for Strangers (Buyer Escrow)
- Eliminates marketplace fraud (OLX, peer-to-peer sales, freelance jobs).
- Funds are safely held in trust by the banking switch and only released to the seller once the buyer inspects and approves the item.
- Built-in dispute management and automated delivery release countdown.

### 4. Rupee-First Cross-Border Payments
- Send money abroad directly in Indian Rupees (INR) with guaranteed 10-minute live FX rate lock.
- Supports major destination currencies: **AED (UAE Dirham)**, **USD (US Dollar)**, **EUR (Euro)**, **SGD (Singapore Dollar)**, and **GBP (British Pound)**.
- Automated Reserve Bank of India (RBI) Liberalised Remittance Scheme (LRS) annual limit tracking ($250,000 USD limit).

### 5. Digital Gullak (Chillar Bachat)
- Micro-savings auto round-up engine: every transaction rounds up to the nearest ₹10 or ₹50, depositing the change into dedicated savings vaults (Goa Trip, House Rent, Emergency Fund).

### 6. Giant QR & Merchant Suite
- High-visibility **Giant QR Scanner** for instant scanning in bustling markets.
- Dynamic merchant QR generation, bill-splitting with automated UPI collect requests, and multi-lingual voice chimes (Hindi, Bengali, Tamil, Telugu, English).

---

## 📁 Repository Structure

```
AikSetra/
├── app/                          # Flutter Mobile Application (Android & iOS)
│   ├── android/                  # Native Android configuration (API 34+ ready)
│   ├── ios/                      # Native iOS configuration
│   ├── lib/
│   │   ├── main.dart             # App entry with authentication state routing
│   │   ├── api_config.dart       # Dynamic backend gateway (10.0.2.2 / localhost)
│   │   ├── models/               # User, Bank, Scam Shield & Escrow models
│   │   ├── screens/
│   │   │   ├── login_screen.dart        # 5-step NPCI onboarding flow
│   │   │   ├── app_lock_screen.dart     # PIN & Fingerprint lock screen
│   │   │   └── simple_home_screen.dart  # Home UI, Giant QR & Account modal
│   │   └── services/
│   │       ├── aiksetra_api.dart        # AikSetra API service client
│   │       └── bharat_one_pay_api.dart  # Backward-compatible redirect
│   └── pubspec.yaml              # Flutter dependencies (http, cupertino_icons, etc.)
│
├── backend/                      # Node.js + TypeScript Banking Switch & Simulator
│   ├── src/
│   │   ├── server.ts             # Express & WebSocket server initialization
│   │   ├── config/index.ts       # Application & VPA handle configuration
│   │   ├── db/
│   │   │   ├── database.ts       # File-based persistent JSON store (aiksetra_db.json)
│   │   │   └── seed.ts           # Baseline verified accounts, merchants & fraud registry
│   │   ├── services/             # Auth, Payment, ScamShield, Escrow, FX, Soundbox
│   │   ├── routes/api.router.ts  # REST API endpoints (/api/v1/...)
│   │   └── public/console/       # Interactive Web Developer Switch Console
│   ├── package.json
│   └── tsconfig.json
│
├── .gitignore                    # Comprehensive repository gitignore
└── README.md                     # Documentation
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `^3.47.0` (with Dart `^3.13.0`)
- **Node.js**: `v20.0.0` or newer
- **Android Studio** (for Android Emulator testing) or a physical Android device

---

### 1. Launching the Backend Service

```bash
cd backend
npm install
npm run seed     # Initializes baseline banks, merchants and verified accounts
npm start        # Starts the service on http://localhost:4000
```

Once running:
- **Developer Switch Console**: Open [http://localhost:4000/console](http://localhost:4000/console) in your browser.
- **Health Check**: `GET http://localhost:4000/health`
- **API Base**: `http://localhost:4000/api/v1/...`

---

### 2. Launching the Flutter Mobile App (Android Studio)

1. Open **Android Studio**.
2. Click **Open** and select the directory:
   ```
   AikSetra/app
   ```
3. Allow Flutter and Gradle to sync dependencies.
4. Launch any Android Virtual Device (AVD) (e.g., Pixel 7 / Pixel 8 running API 34).
5. Run `lib/main.dart` or execute in your terminal:
   ```bash
   cd app
   flutter pub get
   flutter run
   ```

*(Note: The app automatically connects to `http://10.0.2.2:4000/api/v1` on Android Emulators and `http://localhost:4000/api/v1` on iOS or desktop).*

---

## ⚙️ Production Configuration & Environment Variables

AikSetra is architected for real-world launch. Configure your production credentials in `backend/.env`:

```env
# Application
PORT=4000
NODE_ENV=production
JWT_SECRET=your_high_entropy_jwt_secret_64_bytes

# UPI Handles
DEFAULT_VPA_HANDLE=@aiksetra

# Real SMS Gateway (Fast2SMS / MSG91 / Twilio / Gupshup)
SMS_GATEWAY_PROVIDER=FAST2SMS # or MSG91 / TWILIO
FAST2SMS_API_KEY=your_fast2sms_dlt_api_key
MSG91_AUTH_KEY=your_msg91_dlt_auth_key
MSG91_SENDER_ID=AIKSET
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_token
TWILIO_PHONE_NUMBER=+1234567890

# NPCI & Banking PSP Switch Rails
NPCI_PSP_GATEWAY=YESBANK_UPI20 # or ICICI / AXIS / RAZORPAY / CASHFREE
NPCI_MERCHANT_KEY=your_bank_issued_switch_key
NPCI_MERCHANT_SECRET=your_bank_issued_switch_secret
```

---

## 🛡️ Security & Compliance
- **Zero-Knowledge MPIN**: UPI MPIN hashes are computed client-side with SHA-256 and never transmitted as plaintext.
- **DPDP Act 2023**: Digital Personal Data Protection compliant consent handling for phone and device identifiers.
- **NPCI Device Binding**: Cryptographic SIM slot binding matching UPI 2.0 standards.
- **Real OTP Rate-Limiting**: Max 3 verification attempts per 5-minute window with phone-level throttling.

---

## 🤝 Contributing & License
Contributions, feedback, and pull requests are welcome!

Distributed under the **MIT License**. Created with ❤️ by **Soumo Naskar**.
