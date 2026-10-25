import { IPaymentProvider } from './paymentProvider.interface.js';
import { PspSimulatorProvider } from './pspSimulator.provider.js';
import { RealPspAdapter } from './realPsp.adapter.js';
import { config } from '../../config/index.js';

let cachedProvider: IPaymentProvider | null = null;

export function getPaymentProvider(): IPaymentProvider {
  if (cachedProvider) {
    return cachedProvider;
  }

  // Selected strictly by server configuration, never by client input
  const forceReal = process.env.PAYMENT_PROVIDER === 'REAL';
  
  if (config.isProduction || forceReal) {
    cachedProvider = new RealPspAdapter();
  } else {
    cachedProvider = new PspSimulatorProvider();
  }

  return cachedProvider;
}

export function resetPaymentProvider(): void {
  cachedProvider = null;
}
