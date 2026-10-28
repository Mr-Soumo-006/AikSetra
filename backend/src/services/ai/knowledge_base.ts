import { AIDocument } from './ai.types.js';

export const AIKSETRA_KNOWLEDGE_BASE: AIDocument[] = [
  {
    title: 'AikSetra Overview and Core Architecture',
    category: 'Product Overview',
    version: '1.0',
    content: `AikSetra is an advanced, privacy-first financial platform inspired by 'ek' (one) and 'kshetra' (field/domain), representing a unified financial domain.
AikSetra combines UPI 2.0 digital payments, multi-bank account management, merchant and business operations, financial calculators, and evidence-based stock market tracking into a single cohesive mobile and web experience.
All financial transactions follow dual-entry ledger principles, ensuring mathematical consistency across debits and credits.
The platform includes built-in security features like ScamShield threat detection, biometric locks, and local encrypted vault storage for sensitive credentials.`,
  },
  {
    title: 'Bank Account Management and Multi-Bank Switching',
    category: 'Bank Accounts',
    version: '1.0',
    content: `AikSetra allows users to link multiple bank accounts from supported Indian banks (including State Bank of India, HDFC Bank, ICICI Bank, Axis Bank, and Punjab National Bank).
Key capabilities include:
1. Multi-Bank Linking: Link both Savings and Current accounts to the same profile.
2. Default Account Switching: Users can switch their primary account anytime. The primary account is automatically selected for outgoing payments.
3. Adding Money to Specific Accounts: Users can add demo funds or deposit funds into any linked account individually by selecting the target account from the accounts sheet.
4. Real-time Balance Checking: Accounts show current verified ledger balance. Users enter their 4-digit or 6-digit MPIN securely to authenticate balance inquiries.
5. Account Removal: Users can unlink an account as long as it has no pending active mandates or disputes.`,
  },
  {
    title: 'UPI Payments, QR Scanning, and Contacts Demo Payment',
    category: 'UPI & Payments',
    version: '1.0',
    content: `AikSetra provides full UPI 2.0 compliant peer-to-peer and peer-to-merchant payments:
1. Dynamic & Static QR Codes: Users can scan any standard BharatQR or UPI QR code using the in-app scanner to instantly extract payee VPA and amount. Users can also generate their own personal or business QR codes.
2. Real Contacts Demo Payment: AikSetra allows selecting real contacts from the device contact book. Because official NPCI banking partner agreements are currently in demo/sandbox status, payments to arbitrary contacts run safely in realistic demo mode.
3. Transaction History & Pay Again: Every payment (including QR scan payments) stores the payee's name, UPI ID, timestamp, and transaction reference. Users can tap any past transaction in history to view details or pay the contact again immediately.
4. ScamShield Verification: Before payment authorization, ScamShield evaluates the receiver's VPA against known scam registries and warns the user if risk signals are detected.`,
  },
  {
    title: 'Business Accounts and Merchant Operations',
    category: 'Business Account',
    version: '1.0',
    content: `AikSetra offers a dedicated Business Account mode designed for merchants and enterprise users:
1. One-time Setup: When accessing the Business Account for the first time, users complete a quick setup form entering company name, business category, business email, and phone.
2. Business Profile & Switcher: Once set up, the app provides a switcher between personal accounts and business accounts. Business accounts can link separate commercial/current bank accounts.
3. Company Balance Sheet & Digital Ledger: Merchants can view their incoming revenue, daily settlements, customer debits, and balance sheet summaries in real time.
4. Business QR Code & Soundbox: Every business account has a dedicated Merchant QR code. When customers pay, the integrated virtual Soundbox plays an audio confirmation of the received amount.`,
  },
  {
    title: 'Financial Calculators and Standard Calculator',
    category: 'Financial Tools',
    version: '1.0',
    content: `AikSetra provides a complete financial calculation suite accessible from the home screen:
1. Standard Normal Calculator: A clean arithmetic calculator for daily addition, subtraction, multiplication, division, and percentages.
2. Built-in Financial Shortcuts: Quick access directly from the calculator to specialized financial estimators:
   - SIP Calculator: Calculates future wealth and total returns for monthly Systematic Investment Plans given monthly investment, expected annual return rate, and time period in years: M * (( (1 + i)^n - 1 ) / i) * (1 + i).
   - FD (Fixed Deposit) Calculator: Calculates maturity amount for lump-sum deposits: P * (1 + r/n)^(n*t).
   - RD (Recurring Deposit) Calculator: Computes maturity returns for fixed monthly savings with quarterly compounding.
   - EMI Calculator: Calculates monthly loan repayments: [P * r * (1 + r)^n] / [(1 + r)^n - 1].
   - GST Calculator: Computes net and gross amounts for 5%, 12%, 18%, and 28% GST brackets.
   - Currency Converter: Converts between INR, USD, EUR, GBP, and AED.`,
  },
  {
    title: 'AutoPay and Recurring Mandates',
    category: 'AutoPay',
    version: '1.0',
    content: `AikSetra AutoPay enables scheduled recurring debits for utility bills, subscriptions, SIP investments, and loan EMIs:
1. Mandate Creation: Enter beneficiary UPI ID, recurrence frequency (daily, weekly, monthly, quarterly), mandate start date, and maximum debit limit.
2. Authentication: The user authorizes the mandate with their UPI PIN once during setup.
3. Mandate Controls: Users can pause, resume, or revoke any active mandate at any time directly from the AutoPay screen without visiting a bank branch.
4. Execution Notifications: Users receive advance push notifications 24 hours prior to a scheduled debit.`,
  },
  {
    title: 'Stock Market and Real-Time Financial Research',
    category: 'Market Research',
    version: '1.0',
    content: `AikSetra includes a dedicated Stock Market section for market tracking and evidence-based financial research:
1. Real Market Quotes: Displays quotes for major Indian equities (e.g. Reliance, TCS, HDFC Bank, Infosys, ICICI Bank, Tata Motors) and global benchmarks.
2. Interactive Price Charts: Tapping any stock displays an interactive candlestick or bar chart illustrating historical price performance over 1D, 1W, 1M, 1Y, and 5Y horizons.
3. Live Changes & Search: A live ticker streams price movements and percentage changes. A dedicated search bar allows searching by company name or stock ticker.
4. AI Research & Explanations: The AI Assistant can explain company fundamentals, P/E ratios, dividend yields, market capitalization, and financial terms.
5. Non-Advisory Notice: AikSetra provides market analysis for informational and educational purposes only. It is not an SEBI-registered financial advisor and never provides guaranteed return promises or solicitations.`,
  },
  {
    title: 'AikSetra AI Financial Assistant Guidelines and Capabilities',
    category: 'AI Assistant',
    version: '1.0',
    content: `The AikSetra AI Financial Assistant is a secure, intelligent assistant running on self-hosted local neural models.
Core principles:
1. Transparency: Distinguishes verified ledger facts, mathematical calculations, and informational educational explanations.
2. Safety & Privacy: Never asks for or stores user MPINs, card CVVs, or full passwords.
3. Read-Only Actions: The assistant can check account balances, list recent transactions, compute financial formulas, explain features, and provide deep links to app sections. It never initiates monetary transfers autonomously without user MPIN confirmation on the secure payment screen.
4. Grounded Citations: Every explanation is referenced back to official AikSetra documentation and verified sources.`,
  },
];
