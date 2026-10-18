# 🇮🇳 Bharat One Pay (Core Banking, Switch & Platform Backend)

> **"Make in India, Hosted in India, Rupee-First Cross-Border Payments."**

Bharat One Pay is an Indian UPI 2.0 platform architecture and backend service engineered according to NPCI TPAP guidelines, RBI regulations, and FEMA foreign exchange compliance.

It delivers standard UPI rails alongside key differentiators: **Scam Shield real-time fraud defense**, **Protected Pay (RBI-compliant buyer escrow)**, **Rupee-First Any-Currency Cross-Border Remittance**, **Multi-Lingual Merchant Soundbox**, **Money Vaults (Auto Round-Up)**, and **Smart Bill Split**.

---

## 🏛️ System Architecture

```text
       [ Flutter Mobile App (Android & iOS) ]
                         │
     HTTPS + TLS Pinning │ NPCI Common Library (MPIN Encryption)
                         ▼
             [ API Gateway & Security ]
                         │
    ┌────────────────────┼─────────────────────────┐
    │                    │                         │
[Core UPI Engine]  [Scam Shield Engine]   [Cross-Border FX Engine]
• Registration      • National Fraud Reg   • 10-Min Rate Lock
• Device Binding    • Urgency NLP          • NIPL Corridors (Tier 1)
• VPA Management    • Name Mismatch        • AD Bank Outward (Tier 2)
• Pay & Collect     • Cooling-Off (300s)   • Rupee-First Bilateral Rails
• UPI Lite Wallet                          • Annual RBI LRS Tracker
    │                    │                         │
    ├────────────────────┼─────────────────────────┤
    │                    │                         │
[Protected Pay Escrow] [Merchant Services]  [Dispute Tracker & Vaults]
• Bank Escrow Hold   • Dynamic Bharat QR   • Auto Debit Reconciliation
• Delivery Release   • Instant Pay Links   • Auto Round-Up Savings
• In-App Dispute     • Live Soundbox (WS)  • Smart Bill Split
    │
    ▼
[ PSP Integration Adapter & NPCI UPI Switch Simulator ]
    │
    ▼
[ Partner PSP Bank (HDFC / SBI / ICICI) <-> NPCI Central Switch ]
```

---

## ⚡ Quick Start

### 1. Requirements
- Node.js (v20+ or v22+)
- Windows, macOS, or Linux

### 2. Install & Start
```bash
# Navigate to backend directory
cd bharat-one-pay-backend

# Install dependencies
npm install

# Start development server
npm run dev
```

### 3. Open Developer Console
Open your browser to:
👉 **`http://localhost:4000/console`**

From the Web Console, you can:
- **Test Real-Time Scam Shield**: Enter test VPAs, amounts, and scam keywords to inspect live risk scoring.
- **Trigger Live Multi-Lingual Soundbox**: Hear actual vocal payment announcements in Hindi (`भारत वन पे पर ₹80 प्राप्त हुए`), Bengali, Tamil, Telugu, and English via Web Speech.
- **Lock Cross-Border FX Rates**: Calculate total cost preview with NIPL corridor routing and RBI LRS limits.
- **Inspect Protected Pay**: Create escrows, test item delivery release, and simulate dispute workflows.
- **Switch PSP Simulator Modes**: Toggle between `SUCCESS`, `FAIL_MPIN`, `INSUFFICIENT_FUNDS`, `TIMEOUT`, and `FLAKY` to test edge cases in Flutter.

---

## 📡 Core API Reference

All endpoints accept JSON. Authenticate via `Authorization: Bearer <jwt>` or pass `x-user-id: usr_simo_01` for development.

| Category | Method | Endpoint | Description |
|---|---|---|---|
| **Auth** | `POST` | `/api/v1/auth/register-device` | SIM & device fingerprint binding |
| **Auth** | `POST` | `/api/v1/auth/set-mpin` | Set 4 or 6-digit MPIN |
| **Accounts** | `GET` | `/api/v1/accounts/discover` | Discover bank accounts via linked phone |
| **Accounts** | `POST` | `/api/v1/accounts/link` | Link bank account to primary VPA |
| **Accounts** | `GET` | `/api/v1/accounts/:id/balance` | Real-time balance check via PSP |
| **VPA** | `GET` | `/api/v1/vpa/resolve?vpa=...` | NPCI VPA lookup & legal payee name |
| **Payments** | `POST` | `/api/v1/payments/pay` | Core UPI payment with Scam Shield pre-check |
| **Payments** | `POST` | `/api/v1/payments/lite-pay` | On-device PIN-less wallet (< ₹500) |
| **Payments** | `GET` | `/api/v1/payments/history` | Chronological transaction receipts |
| **Collect** | `POST` | `/api/v1/payments/collect` | Request money from another VPA |
| **Collect** | `POST` | `/api/v1/payments/collect/:id/approve` | Approve and debit collect request |
| **Scam Shield** | `POST` | `/api/v1/scam-shield/analyze` | Real-time pre-payment risk assessment |
| **Scam Shield** | `POST` | `/api/v1/scam-shield/report` | Report malicious VPA to fraud registry |
| **Protected Pay**| `POST` | `/api/v1/protected-pay/initiate` | Lock funds in bank escrow for unknown seller |
| **Protected Pay**| `POST` | `/api/v1/protected-pay/:id/confirm-delivery` | Release escrow funds to seller |
| **Protected Pay**| `POST` | `/api/v1/protected-pay/:id/dispute` | Freeze escrow payout & initiate dispute |
| **Cross-Border**| `GET` | `/api/v1/cross-border/currencies` | List 10+ supported currencies & corridors |
| **Cross-Border**| `POST` | `/api/v1/cross-border/quote` | Generate Total Cost Preview with 10-min rate lock |
| **Cross-Border**| `GET` | `/api/v1/cross-border/lrs-status` | RBI Liberalised Remittance Scheme ($250k limit) |
| **Merchants** | `POST` | `/api/v1/merchants/qr` | Generate Bharat UPI QR code & URI |
| **Merchants** | `POST` | `/api/v1/merchants/paylinks` | Create shareable WhatsApp payment link |
| **Soundbox** | `GET` | `/api/v1/merchants/soundbox/stream` | Real-time SSE stream for voice alerts |
| **Vaults** | `POST` | `/api/v1/vaults` | Create savings bucket with auto round-up |
| **Split** | `POST` | `/api/v1/split` | Split bills & generate auto-collect requests |
| **Disputes** | `GET` | `/api/v1/disputes` | Central tracker with T+1 SLA resolution |
| **Simulator** | `POST` | `/api/v1/psp-simulator/mode` | Switch bank switch response mode |

---

## 🛡️ Key Original Differentiators

### 1. Scam Shield Engine
- **Pre-Payment Analysis**: Scores transactions from 0 to 100 before the MPIN screen opens.
- **5 Signal Vectors**:
  1. *National Fraud Blacklist*: Immediate check against known scam VPAs.
  2. *VPA Recency & History*: Flags accounts created within 72 hours.
  3. *Urgency NLP*: Scans payment notes for manipulative words (`lottery`, `electricity cut`, `police fine`, `urgent`).
  4. *Name Mismatch*: Alerts if entered name does not match the bank-registered legal entity name.
  5. *Unusual Velocity*: Flags disproportionate amounts to new contacts.
- **Cooling-Off Period**: High-risk payments trigger a mandatory 5-minute pause or explicit risk acknowledgement.

### 2. Protected Pay (Escrow)
- Eliminates risk when buying from unknown sellers on OLX, Instagram, or informal marketplaces.
- Buyer's money is debited into a partner-bank escrow account.
- Seller receives a "Payment Secured" webhook/notification to ship the item.
- Buyer clicks "Confirm Delivery" upon receiving goods, instantly releasing funds.
- Includes a 7-day auto-release timer and one-click dispute escalation.

### 3. Rupee Bridge & Cross-Border Any-Currency
- **Tier 1 (NIPL UPI Corridors)**: Instant settlement in UAE, Singapore, France, Mauritius, Nepal, Bhutan, Sri Lanka, Qatar, Cambodia, Maldives.
- **Rupee-First Bilateral Rails**: Direct INR-to-local currency clearing with countries having bilateral currency agreements (e.g., UAE, Mauritius, Maldives), bypassing intermediate USD exchange loss.
- **Tier 2 (AD Bank Remittance)**: Outward remittance to US, UK, Canada, Australia under RBI LRS regulations.
- **Total Cost Preview**: Transparently displays market rate, applied rate, AD bank fee (₹25 or ₹150), GST, and net debit.
- **10-Minute Guaranteed Rate Lock**: Eliminates currency volatility while completing verification.

### 4. Multi-Lingual Merchant Soundbox
- Real-time WebSocket and Server-Sent Events (SSE) broadcaster.
- Supports English, Hindi, Bengali, Tamil, and Telugu vocal formats.
- Integrates seamlessly with low-cost hardware soundboxes or runs directly inside the merchant app.

---

## 📱 Flutter Development Integration

See [`flutter-client-kit/README.md`](file:///C:/Users/Soumo%20Naskar/.gemini/antigravity/scratch/bharat-one-pay-backend/flutter-client-kit/README.md) for pre-built Dart data models and API services ready to drop into your Flutter project.
