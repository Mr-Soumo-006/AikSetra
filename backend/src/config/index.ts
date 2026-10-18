import dotenv from 'dotenv';
dotenv.config();

export const config = {
  appName: 'AikSetra',
  appMeaning: 'A shared financial space; inspired by ek (one) and kshetra (domain or field)',
  port: parseInt(process.env.PORT || '4000', 10),
  host: process.env.HOST || '0.0.0.0',
  nodeEnv: process.env.NODE_ENV || 'development',
  jwtSecret: process.env.JWT_SECRET || 'aiksetra-unified-financial-space-secret-2026',
  dataDir: process.env.DATA_DIR || './data',
  defaultVpaHandle: process.env.DEFAULT_VPA_HANDLE || '@aiksetra',
  mockPspDelayMs: parseInt(process.env.MOCK_PSP_DELAY_MS || '250', 10),
  mockPspMode: (process.env.MOCK_PSP_MODE || 'SUCCESS') as 'SUCCESS' | 'FLAKY' | 'FAIL_MPIN' | 'TIMEOUT',
  escrowAutoReleaseDays: parseInt(process.env.ESCROW_AUTO_RELEASE_DAYS || '7', 10),
  lrsAnnualLimitUsd: parseInt(process.env.LRS_ANNUAL_LIMIT_USD || '250000', 10),

  // Real SMS Gateway configuration (Fast2SMS / MSG91 / Twilio)
  smsGatewayProvider: (process.env.SMS_GATEWAY_PROVIDER || 'CONSOLE') as 'FAST2SMS' | 'MSG91' | 'TWILIO' | 'CONSOLE',
  fast2smsApiKey: process.env.FAST2SMS_API_KEY || '',
  msg91AuthKey: process.env.MSG91_AUTH_KEY || '',
  msg91SenderId: process.env.MSG91_SENDER_ID || 'AIKSET',
  twilioAccountSid: process.env.TWILIO_ACCOUNT_SID || '',
  twilioAuthToken: process.env.TWILIO_AUTH_TOKEN || '',
  twilioPhoneNumber: process.env.TWILIO_PHONE_NUMBER || '',

  // Banking PSP Switch Gateway
  npciPspGateway: process.env.NPCI_PSP_GATEWAY || 'YESBANK_UPI20',
  npciMerchantKey: process.env.NPCI_MERCHANT_KEY || '',
  npciMerchantSecret: process.env.NPCI_MERCHANT_SECRET || '',
};
