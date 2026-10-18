import { config } from '../config/index.js';

export interface PspPayRequest {
  payerVpa: string;
  payeeVpa: string;
  amount: number;
  encryptedMpinBlock: string;
  txnRef: string;
  remitterBankCode: string;
  beneficiaryBankCode?: string;
}

export interface PspPayResponse {
  success: boolean;
  responseCode: string; // "00" = Success, "U30" = Invalid MPIN, "ZM" = Invalid Address, "U69" = Timeout, "Z9" = Insufficient Funds
  responseMessage: string;
  upiRrn: string;
  bankRefNumber: string;
  timestamp: string;
}

export class PspSimulator {
  private mode: 'SUCCESS' | 'FLAKY' | 'FAIL_MPIN' | 'TIMEOUT' | 'INSUFFICIENT_FUNDS';

  constructor() {
    this.mode = config.mockPspMode as any;
  }

  public setMode(mode: 'SUCCESS' | 'FLAKY' | 'FAIL_MPIN' | 'TIMEOUT' | 'INSUFFICIENT_FUNDS') {
    this.mode = mode;
  }

  public getMode() {
    return this.mode;
  }

  private generateRrn(): string {
    // Standard 12-digit UPI RRN: Year day + 8 random digits
    const yearCode = '4'; // 2024-2026 cycle
    const dayOfYear = String(Math.floor((Date.now() - new Date(new Date().getFullYear(), 0, 0).getTime()) / 86400000)).padStart(3, '0');
    const random = Math.floor(10000000 + Math.random() * 90000000).toString();
    return `${yearCode}${dayOfYear}${random.slice(0, 8)}`;
  }

  public async executeReqPay(req: PspPayRequest): Promise<PspPayResponse> {
    if (config.mockPspDelayMs > 0) {
      await new Promise((r) => setTimeout(r, config.mockPspDelayMs));
    }

    const upiRrn = this.generateRrn();
    const bankRefNumber = `NPCI-${req.remitterBankCode}-${Date.now().toString().slice(-6)}`;

    // Simulator mode overrides
    if (this.mode === 'FAIL_MPIN') {
      return {
        success: false,
        responseCode: 'U30',
        responseMessage: 'Wrong UPI MPIN entered. 2 attempts remaining.',
        upiRrn,
        bankRefNumber,
        timestamp: new Date().toISOString(),
      };
    }

    if (this.mode === 'INSUFFICIENT_FUNDS') {
      return {
        success: false,
        responseCode: 'Z9',
        responseMessage: 'Insufficient balance in remitter account.',
        upiRrn,
        bankRefNumber,
        timestamp: new Date().toISOString(),
      };
    }

    if (this.mode === 'TIMEOUT') {
      return {
        success: false,
        responseCode: 'U69',
        responseMessage: 'NPCI UPI switch response timed out. Bank status pending.',
        upiRrn,
        bankRefNumber,
        timestamp: new Date().toISOString(),
      };
    }

    if (this.mode === 'FLAKY' && Math.random() < 0.25) {
      return {
        success: false,
        responseCode: 'U16',
        responseMessage: 'Beneficiary bank network down. Please retry later.',
        upiRrn,
        bankRefNumber,
        timestamp: new Date().toISOString(),
      };
    }

    return {
      success: true,
      responseCode: '00',
      responseMessage: 'Transaction Successful',
      upiRrn,
      bankRefNumber,
      timestamp: new Date().toISOString(),
    };
  }

  public async executeReqBalEnq(bankCode: string, accountId: string): Promise<{ success: boolean; balance?: number }> {
    if (config.mockPspDelayMs > 0) {
      await new Promise((r) => setTimeout(r, config.mockPspDelayMs));
    }
    return { success: true };
  }

  public async executeReqValAdd(vpa: string): Promise<{ valid: boolean; verifiedName?: string }> {
    if (config.mockPspDelayMs > 0) {
      await new Promise((r) => setTimeout(r, 100));
    }
    return { valid: true };
  }
}

export const pspSimulator = new PspSimulator();
