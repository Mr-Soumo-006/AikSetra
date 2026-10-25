import { IPaymentProvider, ProviderPaymentRequest, ProviderPaymentResult } from './paymentProvider.interface.js';
import { config } from '../../config/index.js';

export class RealPspAdapter implements IPaymentProvider {
  public readonly providerName = 'REAL_BANK_PSP_SWITCH';
  public readonly isSimulation = false;

  private apiKey: string;
  private apiSecret: string;
  private gatewayUrl: string;

  constructor() {
    this.apiKey = config.npciMerchantKey;
    this.apiSecret = config.npciMerchantSecret;
    this.gatewayUrl = process.env.NPCI_GATEWAY_URL || 'https://api.npci-partner.bank/upi/v2';

    if (!this.apiKey || !this.apiSecret) {
      if (config.isProduction) {
        throw new Error(
          'FATAL: Real Banking PSP Adapter requires NPCI_MERCHANT_KEY and NPCI_MERCHANT_SECRET in production.'
        );
      }
    }
  }

  public async initiatePayment(req: ProviderPaymentRequest): Promise<ProviderPaymentResult> {
    if (!this.apiKey || !this.apiSecret) {
      throw new Error(
        'Real payment provider adapter is not configured. Partner bank API credentials missing.'
      );
    }

    // In production with live partner credentials, make signed HTTPS request to banking switch
    // E.g. POST to NPCI / Partner CBS API with HMAC-SHA256 signature
    throw new Error(
      `Real Banking PSP Switch partner API (${config.npciPspGateway}) pending bank certificate onboarding.`
    );
  }

  public async verifyStatus(txnRef: string, upiRrn?: string): Promise<ProviderPaymentResult> {
    if (!this.apiKey || !this.apiSecret) {
      throw new Error(
        'Real payment provider adapter is not configured. Partner bank API credentials missing.'
      );
    }

    throw new Error('Real payment status verification requires bank partner connectivity.');
  }
}
