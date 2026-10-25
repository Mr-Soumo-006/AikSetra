import { IPaymentProvider, ProviderPaymentRequest, ProviderPaymentResult } from './paymentProvider.interface.js';
import { pspSimulator } from '../psp.simulator.js';

export class PspSimulatorProvider implements IPaymentProvider {
  public readonly providerName = 'NPCI_UPI_SIMULATOR';
  public readonly isSimulation = true;

  public async initiatePayment(req: ProviderPaymentRequest): Promise<ProviderPaymentResult> {
    const res = await pspSimulator.executeReqPay({
      payerVpa: req.payerVpa,
      payeeVpa: req.payeeVpa,
      amount: req.amount,
      encryptedMpinBlock: req.encryptedMpinBlock || 'NPCI_PBKDF2_SECURE_BLOCK',
      txnRef: req.txnRef,
      remitterBankCode: req.remitterBankCode || 'SBIN',
      beneficiaryBankCode: req.beneficiaryBankCode,
    });

    return {
      success: res.success,
      upiRrn: res.upiRrn,
      responseCode: res.responseCode,
      responseMessage: res.responseMessage,
      bankRefNumber: res.bankRefNumber,
      isSimulated: true,
      settlementType: 'DEMO_SIMULATION',
      timestamp: res.timestamp,
    };
  }

  public async verifyStatus(txnRef: string, upiRrn?: string): Promise<ProviderPaymentResult> {
    return {
      success: true,
      upiRrn: upiRrn || `4291${Math.floor(10000000 + Math.random() * 90000000)}`,
      responseCode: '00',
      responseMessage: 'Simulated payment confirmed',
      isSimulated: true,
      settlementType: 'DEMO_SIMULATION',
      timestamp: new Date().toISOString(),
    };
  }
}
