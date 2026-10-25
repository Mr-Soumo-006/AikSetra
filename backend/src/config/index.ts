import dotenv from 'dotenv';
import crypto from 'crypto';

dotenv.config();

const isTest =
  process.env.NODE_ENV === 'test' ||
  Boolean(process.env.NODE_TEST_CONTEXT) ||
  process.argv.some((a) => a.toLowerCase().includes('test'));
const nodeEnv = isTest ? 'test' : process.env.NODE_ENV || 'development';
const isProduction = !isTest && nodeEnv === 'production';

// Issue 1 & 2: Enforce secure JWT Secret and Admin API Key validation
let resolvedJwtSecret = process.env.JWT_SECRET || '';
let resolvedAdminApiKey = process.env.ADMIN_API_KEY || '';
let resolvedWebhookSecret = process.env.WEBHOOK_SECRET || '';

if (isProduction) {
  if (!resolvedJwtSecret || resolvedJwtSecret.length < 32) {
    console.error('❌ FATAL SECURITY ERROR: JWT_SECRET environment variable is required and must be at least 32 characters in production.');
    process.exit(1);
  }
  if (!resolvedAdminApiKey || resolvedAdminApiKey.length < 32) {
    console.error('❌ FATAL SECURITY ERROR: ADMIN_API_KEY environment variable is required and must be at least 32 characters in production.');
    process.exit(1);
  }
  if (!resolvedWebhookSecret || resolvedWebhookSecret.length < 32) {
    console.error('❌ FATAL SECURITY ERROR: WEBHOOK_SECRET environment variable is required and must be at least 32 characters in production.');
    process.exit(1);
  }
} else {
  if (!resolvedJwtSecret) {
    resolvedJwtSecret = crypto.randomBytes(32).toString('hex');
    console.warn('⚠️ WARNING [SECURITY]: No JWT_SECRET set in environment. Generated an ephemeral runtime key.');
  }
  if (!resolvedAdminApiKey) {
    resolvedAdminApiKey = crypto.randomBytes(32).toString('hex');
    console.warn('⚠️ WARNING [SECURITY]: No ADMIN_API_KEY set in environment. Generated an ephemeral runtime key.');
  }
  if (!resolvedWebhookSecret) {
    resolvedWebhookSecret = crypto.randomBytes(32).toString('hex');
    console.warn('⚠️ WARNING [SECURITY]: No WEBHOOK_SECRET set in environment. Generated an ephemeral runtime key.');
  }
}

export const config = {
  appName: 'AikSetra',
  appMeaning: 'A shared financial space; inspired by ek (one) and kshetra (domain or field)',
  port: parseInt(process.env.PORT || '4000', 10),
  host: process.env.HOST || '0.0.0.0',
  nodeEnv,
  isProduction,
  isSimulationMode: !isProduction,
  jwtSecret: resolvedJwtSecret,
  adminApiKey: resolvedAdminApiKey,
  webhookSecret: resolvedWebhookSecret,
  allowedOrigins: (process.env.ALLOWED_ORIGINS || '').split(',').map((o) => o.trim()).filter(Boolean),
  dataDir: process.env.DATA_DIR || './data',
  defaultVpaHandle: process.env.DEFAULT_VPA_HANDLE || '@aiksetra',
  mockPspDelayMs: parseInt(process.env.MOCK_PSP_DELAY_MS || '250', 10),
  mockPspMode: (process.env.MOCK_PSP_MODE || 'SUCCESS') as 'SUCCESS' | 'FLAKY' | 'FAIL_MPIN' | 'TIMEOUT',
  escrowAutoReleaseDays: parseInt(process.env.ESCROW_AUTO_RELEASE_DAYS || '7', 10),
  lrsAnnualLimitUsd: parseInt(process.env.LRS_ANNUAL_LIMIT_USD || '250000', 10),

  // Real SMS Gateway configuration (Fast2SMS / MSG91 / Twilio)
  smsGatewayProvider: (
    process.env.SMS_GATEWAY_PROVIDER === 'FAST2SMS' && !process.env.FAST2SMS_API_KEY
      ? 'CONSOLE'
      : process.env.SMS_GATEWAY_PROVIDER || (isProduction ? 'FAST2SMS' : 'CONSOLE')
  ) as 'FAST2SMS' | 'MSG91' | 'TWILIO' | 'CONSOLE',
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
  databaseUrl: process.env.DATABASE_URL || '',
};

export function validateConfig(): void {
  if (config.isProduction) {
    if (config.isSimulationMode) {
      console.warn('⚠️ Alert: Simulation mode is enabled in production configuration.');
    }
    if (config.allowedOrigins.length === 0 || config.allowedOrigins.includes('*')) {
      console.error('❌ FATAL SECURITY ERROR: In production, ALLOWED_ORIGINS must be explicitly configured without wildcards.');
      process.exit(1);
    }
    if (!config.fast2smsApiKey && !config.msg91AuthKey && !config.twilioAccountSid) {
      console.warn('⚠️ Warning: No production SMS gateway provider keys configured in environment.');
    }
  }
}
