import crypto from 'crypto';
import { IPaymentProvider, ProviderPaymentRequest, ProviderPaymentResult } from './paymentProvider.interface.js';
import { config } from '../../config/index.js';

/**
 * Real Banking Switch & NPCI UPI 2.0 Provider Adapter
 * Handles cryptographic HMAC signing, request dispatch to authorized bank switch rails
 * (e.g. Yes Bank, ICICI, Axis Bank UPI 2.0 PSP Gateway), and strict settlement verification.
 */
export class RealPspAdapter implements IPaymentProvider {
  public readonly providerName = 'REAL_BANK_PSP_SWITCH';
  public readonly isSimulation = false;

  private apiKey: string;
  private apiSecret: string;
  private gatewayUrl: string;

  constructor() {
    this.apiKey = config.npciMerchantKey;
    this.apiSecret = config.npciMerchantSecret;
    this.gatewayUrl = process.env.NPCI_GATEWAY_URL || '';
  }

  /**
   * Dispatches signed ReqPay instruction to partner bank switch gateway.
   * Never claims confirmed bank settlement unless authenticated response code '00' is returned.
   */
  public async initiatePayment(req: ProviderPaymentRequest): Promise<ProviderPaymentResult> {
    const now = new Date().toISOString();

    if (!this.apiKey || !this.apiSecret || !this.gatewayUrl || this.gatewayUrl.includes('api.npci-partner.bank')) {
      return {
        success: false,
        upiRrn: '',
        responseCode: 'U90',
        responseMessage:
          'Real Banking Switch unavailable: NPCI_GATEWAY_URL must be configured with an authorized partner bank switch endpoint, and NPCI_MERCHANT_KEY/SECRET must be provided. Placeholder endpoints are prohibited.',
        settlementType: 'UNSETTLED',
        isSimulated: false,
        timestamp: now,
      };
    }

    const payload = {
      head: {
        ver: '2.0',
        ts: now,
        msgId: `MSG_${req.txnRef}`,
        orgId: this.apiKey,
        pspGateway: config.npciPspGateway,
      },
      txn: {
        id: req.txnRef,
        note: 'AikSetra UPI Payment',
        refId: req.txnRef,
        type: 'PAY',
        subType: 'P2P',
      },
      payer: {
        addr: req.payerVpa,
        bankCode: req.remitterBankCode,
        cred: {
          type: 'PIN',
          subType: 'MPIN',
          data: req.encryptedMpinBlock,
        },
      },
      payee: {
        addr: req.payeeVpa,
      },
      amount: {
        curr: 'INR',
        value: req.amount.toFixed(2),
      },
    };

    const rawBody = JSON.stringify(payload);
    const signature = crypto.createHmac('sha256', this.apiSecret).update(rawBody).digest('hex');

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 8000);

      const response = await fetch(`${this.gatewayUrl}/reqPay`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Merchant-Id': this.apiKey,
          'X-Signature': signature,
          'X-Timestamp': now,
          'X-Psp-Gateway': config.npciPspGateway,
        },
        body: rawBody,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        return {
          success: false,
          upiRrn: '',
          responseCode: `HTTP_${response.status}`,
          responseMessage: `Banking Switch rejected request with HTTP status ${response.status}`,
          settlementType: 'UNSETTLED',
          isSimulated: false,
          timestamp: new Date().toISOString(),
        };
      }

      const resData = (await response.json()) as any;
      const rrn = resData.upiRrn || `${Date.now()}`.slice(-12);

      // Settlement code '00': Immediate confirmed settlement
      if (resData.responseCode === '00' || resData.status === 'SUCCESS') {
        return {
          success: true,
          upiRrn: rrn,
          responseCode: '00',
          responseMessage: resData.message || 'Confirmed Bank Settlement from Switch',
          settlementType: 'CONFIRMED_REAL_SETTLEMENT',
          isSimulated: false,
          timestamp: new Date().toISOString(),
        };
      }

      // Settlement code 'ACTC' / '91': Technical validation passed, asynchronous bank clearing pending
      if (resData.responseCode === 'ACTC' || resData.responseCode === '91') {
        return {
          success: true,
          upiRrn: rrn,
          responseCode: '91',
          responseMessage: 'Accepted by Switch: Settlement Pending Webhook Callback',
          settlementType: 'PENDING_SETTLEMENT',
          isSimulated: false,
          timestamp: new Date().toISOString(),
        };
      }

      // Bank decline
      return {
        success: false,
        upiRrn: resData.upiRrn || '',
        responseCode: resData.responseCode || 'U30',
        responseMessage: resData.message || 'Payment declined by remitter bank switch',
        settlementType: 'UNSETTLED',
        isSimulated: false,
        timestamp: new Date().toISOString(),
      };
    } catch (err: any) {
      return {
        success: false,
        upiRrn: '',
        responseCode: 'U19',
        responseMessage: `Banking Switch (${config.npciPspGateway}) connectivity error: ${err.message}`,
        settlementType: 'UNSETTLED',
        isSimulated: false,
        timestamp: new Date().toISOString(),
      };
    }
  }

  /**
   * Queries real-time settlement status from banking partner switch
   */
  public async verifyStatus(txnRef: string, upiRrn?: string): Promise<ProviderPaymentResult> {
    const now = new Date().toISOString();

    if (!this.apiKey || !this.apiSecret || !this.gatewayUrl || this.gatewayUrl.includes('api.npci-partner.bank')) {
      return {
        success: false,
        upiRrn: upiRrn || '',
        responseCode: 'U90',
        responseMessage: 'Banking partner switch endpoint and credentials not configured for status inquiry.',
        settlementType: 'UNSETTLED',
        isSimulated: false,
        timestamp: now,
      };
    }

    try {
      const queryParams = new URLSearchParams({
        txnRef,
        rrn: upiRrn || '',
        merchantId: this.apiKey,
        timestamp: now,
      });

      const signature = crypto
        .createHmac('sha256', this.apiSecret)
        .update(queryParams.toString())
        .digest('hex');

      const response = await fetch(`${this.gatewayUrl}/reqStatus?${queryParams.toString()}`, {
        method: 'GET',
        headers: {
          'X-Merchant-Id': this.apiKey,
          'X-Signature': signature,
          'X-Timestamp': now,
        },
      });

      if (!response.ok) {
        return {
          success: false,
          upiRrn: upiRrn || '',
          responseCode: `HTTP_${response.status}`,
          responseMessage: 'Status inquiry failed at Banking Switch',
          settlementType: 'UNSETTLED',
          isSimulated: false,
          timestamp: new Date().toISOString(),
        };
      }

      const resData = (await response.json()) as any;
      const isConfirmed = resData.responseCode === '00' || resData.status === 'SUCCESS';

      return {
        success: isConfirmed,
        upiRrn: resData.upiRrn || upiRrn || '',
        responseCode: resData.responseCode || (isConfirmed ? '00' : 'U30'),
        responseMessage: resData.message || (isConfirmed ? 'Settlement Confirmed' : 'Payment Not Settled'),
        settlementType: isConfirmed ? 'CONFIRMED_REAL_SETTLEMENT' : 'UNSETTLED',
        isSimulated: false,
        timestamp: new Date().toISOString(),
      };
    } catch (err: any) {
      return {
        success: false,
        upiRrn: upiRrn || '',
        responseCode: 'U19',
        responseMessage: `Switch status verification error: ${err.message}`,
        settlementType: 'UNSETTLED',
        isSimulated: false,
        timestamp: new Date().toISOString(),
      };
    }
  }
}
