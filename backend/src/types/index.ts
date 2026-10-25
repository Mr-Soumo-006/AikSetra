export type KycStatus = 'PENDING' | 'VERIFIED' | 'REJECTED';
export type AccountType = 'SAVINGS' | 'CURRENT';
export type PaymentStatus = 'INITIATED' | 'PENDING' | 'SUCCESS' | 'FAILED' | 'REVERSED';
export type PaymentType = 'P2P' | 'P2M' | 'COLLECT' | 'LITE' | 'CROSS_BORDER' | 'PROTECTED_PAY' | 'SPLIT';
export type CollectStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'EXPIRED';
export type RiskLevel = 'SAFE' | 'LOW' | 'MODERATE' | 'HIGH';
export type EscrowStatus = 'HELD_IN_ESCROW' | 'RELEASED_TO_SELLER' | 'DISPUTED' | 'REFUNDED_TO_BUYER';
export type CorridorType = 'TIER_1_NIPL' | 'TIER_2_AD_BANK' | 'RUPEE_FIRST_BILATERAL';

export interface User {
  id: string;
  phone: string;
  fullName: string;
  email: string;
  panNumber: string;
  kycStatus: KycStatus;
  deviceId: string;
  simId: string;
  mpinHash: string; // bcrypt or sha256 simulated hash
  primaryVpa: string;
  liteBalance: number;
  lrsUsedUsd: number;
  createdAt: string;
  updatedAt: string;
}

export interface BankAccount {
  id: string;
  userId: string;
  bankName: string;
  bankCode: string;
  ifsc: string;
  maskedAccountNumber: string;
  accountType: AccountType;
  isPrimary: boolean;
  balance: number;
  upiPinSet: boolean;
}

export interface VpaRecord {
  vpa: string; // e.g. rohit@bharatpay
  userId: string;
  fullName: string;
  accountId: string;
  isPrimary: boolean;
  createdAt: string;
  trustScore: number; // 0 to 100
  fraudReportCount: number;
  isMerchant: boolean;
}

export interface Transaction {
  id: string;
  txnRef: string;
  upiRrn: string; // 12-digit Retrieval Reference Number
  senderUserId?: string;
  senderVpa: string;
  senderAccountId?: string;
  receiverUserId?: string;
  receiverVpa: string;
  receiverName: string;
  amount: number;
  currency: string;
  txnType: PaymentType;
  status: PaymentStatus;
  remark: string;
  failureReason?: string;
  scamShieldScore?: number;
  idempotencyKey?: string;
  metadata?: Record<string, any>;
  createdAt: string;
  completedAt?: string;
}

export interface CollectRequest {
  id: string;
  payerVpa: string;
  payeeVpa: string;
  payeeName: string;
  amount: number;
  remark: string;
  expiryMinutes: number;
  status: CollectStatus;
  txnId?: string;
  createdAt: string;
  expiresAt: string;
}

export interface ScamShieldAnalysis {
  riskScore: number; // 0 - 100
  riskLevel: RiskLevel;
  warnings: string[];
  signals: {
    newPayee: boolean;
    unusualAmount: boolean;
    urgencyKeywordsDetected: string[];
    nameMismatch: {
      detected: boolean;
      enteredName?: string;
      verifiedLegalName?: string;
    };
    blacklisted: boolean;
    coolingOffRequired: boolean;
    coolingOffSeconds: number;
  };
  recommendation: 'PROCEED' | 'WARN_USER' | 'REQUIRE_COOLING_OFF' | 'BLOCK';
  verifiedLegalName: string;
}

export interface ProtectedPayEscrow {
  id: string;
  buyerUserId: string;
  buyerVpa: string;
  sellerVpa: string;
  sellerName: string;
  amount: number;
  itemDescription: string;
  status: EscrowStatus;
  expiresAt: string;
  autoReleaseDays: number;
  trackingNumber?: string;
  disputeReason?: string;
  disputeEvidenceUrl?: string;
  createdAt: string;
  releasedAt?: string;
  resolvedAt?: string;
}

export interface CrossBorderQuote {
  quoteId: string;
  sourceCurrency: 'INR';
  targetCurrency: string;
  targetAmount: number;
  sourceAmountInr: number;
  exchangeRate: number; // e.g. 1 AED = 22.85 INR
  marketReferenceRate: number;
  adBankFeeInr: number;
  gstInr: number;
  totalCostInr: number;
  corridorType: CorridorType;
  partnerRail: string; // e.g. "NIPL - UAE AANI / Jaywan" or "AD-Bank Swift/SEPA"
  rateLockExpiresAt: string;
  lrsLimitRemainingUsd: number;
}

export interface Merchant {
  id: string;
  userId: string;
  businessName: string;
  merchantVpa: string;
  category: string;
  panOrGst: string;
  apiKey: string;
  webhookUrl?: string;
  soundboxLanguage: 'en' | 'hi' | 'bn' | 'ta' | 'te';
  totalVolumeInr: number;
  createdAt: string;
}

export interface PayLink {
  id: string;
  merchantId: string;
  merchantName: string;
  amount: number;
  description: string;
  linkUrl: string;
  upiIntentUrl: string;
  qrCodeDataUrl?: string;
  status: 'ACTIVE' | 'PAID' | 'EXPIRED';
  paidAt?: string;
  paidByVpa?: string;
  createdAt: string;
}

export interface MoneyVault {
  id: string;
  userId: string;
  name: string;
  targetAmount: number;
  currentBalance: number;
  category: 'SAVINGS' | 'RENT' | 'TRAVEL' | 'EMERGENCY' | 'FESTIVAL';
  autoRoundUp: boolean;
  roundUpMultiple: number; // 10 | 50 | 100
  createdAt: string;
}

export interface SplitParticipant {
  id: string;
  name: string;
  vpa: string;
  shareAmount: number;
  status: 'PENDING' | 'PAID';
  collectRequestId?: string;
  paidAt?: string;
}

export interface SplitBill {
  id: string;
  title: string;
  totalAmount: number;
  createdByUserId: string;
  participants: SplitParticipant[];
  status: 'OPEN' | 'SETTLED';
  createdAt: string;
}

export interface DisputeTicket {
  id: string;
  txnId: string;
  upiRrn: string;
  userId: string;
  amount: number;
  category: 'DEBITED_NOT_CREDITED' | 'FRAUD_REPORT' | 'PROTECTED_PAY_DISPUTE' | 'WRONG_VPA_TRANSFER';
  status: 'LOGGED' | 'INVESTIGATING' | 'REFUNDED' | 'REJECTED';
  description: string;
  slaResolveBy: string;
  bankRefNumber: string;
  createdAt: string;
  resolvedAt?: string;
}

export interface SoundboxEvent {
  id: string;
  merchantId: string;
  merchantName: string;
  amount: number;
  currency: string;
  payerName: string;
  payerVpa: string;
  language: 'en' | 'hi' | 'bn' | 'ta' | 'te';
  spokenText: string;
  timestamp: string;
}
