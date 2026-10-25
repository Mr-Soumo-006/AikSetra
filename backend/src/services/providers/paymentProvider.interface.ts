/**
 * Payment Provider Interface
 * Separates demo/simulation payment mechanisms from real bank settlement adapters.
 * Ensures simulated transactions can never be mislabeled as confirmed bank settlements.
 */

export interface ProviderPaymentRequest {
  payerVpa: string;
  payeeVpa: string;
  amount: number;
  encryptedMpinBlock?: string;
  txnRef: string;
  remitterBankCode?: string;
  beneficiaryBankCode?: string;
}

export type SettlementType =
  | 'DEMO_SIMULATION'
  | 'CONFIRMED_REAL_SETTLEMENT'
  | 'PENDING_SETTLEMENT'
  | 'UNSETTLED';

export interface ProviderPaymentResult {
  success: boolean;
  upiRrn: string;
  responseCode: string;
  responseMessage: string;
  bankRefNumber?: string;
  isSimulated: boolean;
  settlementType: SettlementType;
  timestamp: string;
}

export interface IPaymentProvider {
  readonly providerName: string;
  readonly isSimulation: boolean;

  initiatePayment(req: ProviderPaymentRequest): Promise<ProviderPaymentResult>;
  verifyStatus(txnRef: string, upiRrn?: string): Promise<ProviderPaymentResult>;
}
