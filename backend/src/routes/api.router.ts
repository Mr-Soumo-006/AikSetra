import { Router } from 'express';
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import { db } from '../db/database.js';
import { config } from '../config/index.js';
import { authMiddleware, adminAuthMiddleware, AuthenticatedRequest } from '../middleware/auth.middleware.js';
import {
  otpRateLimiter,
  authRateLimiter,
  paymentRateLimiter,
  mpinRateLimiter,
  vpaRateLimiter,
  merchantRateLimiter,
} from '../middleware/rateLimit.middleware.js';
import { AuthService } from '../services/auth.service.js';
import { AccountService } from '../services/account.service.js';
import { PaymentService } from '../services/payment.service.js';
import { ScamShieldService } from '../services/scamShield.service.js';
import { ProtectedPayService } from '../services/protectedPay.service.js';
import { CrossBorderService } from '../services/crossBorder.service.js';
import { MerchantService } from '../services/merchant.service.js';
import { soundboxService } from '../services/soundbox.service.js';
import { VaultService } from '../services/vault.service.js';
import { SplitService } from '../services/split.service.js';
import { DisputeService } from '../services/dispute.service.js';
import { BillPayService } from '../services/billPay.service.js';
import { SipService } from '../services/sip.service.js';
import { SmsService } from '../services/sms.service.js';
import { pspSimulator } from '../services/psp.simulator.js';
import { LedgerService } from '../services/ledger.service.js';
import { AuditService } from '../services/audit.service.js';
import { AutoPayService } from '../services/autopay.service.js';
import { RewardsService } from '../services/rewards.service.js';
import { BusinessService } from '../services/business.service.js';
import { FinancialToolsService } from '../services/financialTools.service.js';
import { validatePaymentAmount, validateVpa, validateIfsc, sanitizeRemark } from '../utils/validation.js';

export const apiRouter = Router();

const uploadsDir = path.resolve(process.cwd(), 'public/uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}
apiRouter.use('/uploads', (await import('express')).default.static(uploadsDir));


// ==========================================
// 1. AUTH, OTP & DEVICE BINDING
// ==========================================

// Issue 3, 7 & 35: Rate-limited OTP dispatch with no OTP disclosure
apiRouter.post('/auth/send-otp', otpRateLimiter, async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) {
      return res.status(400).json({ success: false, message: 'Please provide a 10-digit Indian mobile number.' });
    }
    const result = await AuthService.sendOtp(phone, req.ip);
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

// Issue 4, 7 & 33: Rate-limited interactive OTP verification & login
apiRouter.post('/auth/verify-otp', authRateLimiter, (req, res) => {
  try {
    const { phone, otp, deviceId, simId, fullName, selectedBank } = req.body;
    if (!phone || !otp) {
      return res.status(400).json({ success: false, message: 'Phone number and 6-digit OTP are required.' });
    }
    const result = AuthService.verifyOtpAndLogin({
      phone,
      otp,
      deviceId: deviceId || 'device_android_verified',
      simId: simId || 'sim_slot_1_jio',
      fullName,
      selectedBank,
      clientIp: req.ip,
    });
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

// Issue 4: Disallow fixed OTP registration bypass
apiRouter.post('/auth/register-device', (req, res) => {
  return res.status(400).json({
    success: false,
    code: 'INTERACTIVE_OTP_REQUIRED',
    message: 'Fixed-OTP registration is disabled for security compliance. Please authenticate via /auth/send-otp and /auth/verify-otp.',
  });
});

// Issue 5 & 7: Rate-limited MPIN configuration with validation
apiRouter.post('/auth/set-mpin', authMiddleware, mpinRateLimiter, (req: AuthenticatedRequest, res) => {
  try {
    const { mpin } = req.body;
    if (!mpin) {
      return res.status(400).json({ success: false, message: 'Please provide a 4 or 6 digit numerical MPIN.' });
    }
    AuthService.setMpin(req.userId!, mpin);
    return res.json({ success: true, message: 'UPI MPIN configured successfully using PBKDF2.' });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.get('/auth/me', authMiddleware, (req: AuthenticatedRequest, res) => {
  const user = db.get('users').find((u) => u.id === req.userId);
  if (!user) return res.status(404).json({ success: false, message: 'User not found.' });

  // Sanitize user object (never expose mpinHash or salt)
  const sanitizedUser = {
    ...user,
    mpinHash: undefined,
    mpinSalt: undefined,
  };

  const accounts = db.get('accounts').filter((a) => a.userId === req.userId);
  return res.json({ success: true, user: sanitizedUser, accounts });
});

apiRouter.put('/auth/profile', authMiddleware, (req: AuthenticatedRequest, res) => {
  const user = db.get('users').find((u) => u.id === req.userId);
  if (!user) return res.status(404).json({ success: false, message: 'User not found.' });

  const { fullName, email, dateOfBirth, profilePicture } = req.body;
  if (fullName && typeof fullName === 'string' && fullName.trim().length > 0) {
    user.fullName = fullName.trim();
  }
  if (email && typeof email === 'string') {
    user.email = email.trim();
  }
  if (dateOfBirth !== undefined) {
    user.dateOfBirth = dateOfBirth;
  }
  if (profilePicture !== undefined) {
    user.profilePicture = profilePicture;
  }
  user.updatedAt = new Date().toISOString();

  const sanitizedUser = {
    ...user,
    mpinHash: undefined,
    mpinSalt: undefined,
  };

  return res.json({ success: true, message: 'Profile updated successfully.', user: sanitizedUser });
});

apiRouter.post('/auth/profile', authMiddleware, (req: AuthenticatedRequest, res) => {
  const user = db.get('users').find((u) => u.id === req.userId);
  if (!user) return res.status(404).json({ success: false, message: 'User not found.' });

  const { fullName, email, dateOfBirth, profilePicture } = req.body;
  if (fullName && typeof fullName === 'string' && fullName.trim().length > 0) {
    user.fullName = fullName.trim();
  }
  if (email && typeof email === 'string') {
    user.email = email.trim();
  }
  if (dateOfBirth !== undefined) {
    user.dateOfBirth = dateOfBirth;
  }
  if (profilePicture !== undefined) {
    user.profilePicture = profilePicture;
  }
  user.updatedAt = new Date().toISOString();

  const sanitizedUser = {
    ...user,
    mpinHash: undefined,
    mpinSalt: undefined,
  };

  return res.json({ success: true, message: 'Profile updated successfully.', user: sanitizedUser });
});

apiRouter.post('/auth/upload-avatar', authMiddleware, async (req: AuthenticatedRequest, res) => {
  try {
    const { imageBase64, extension } = req.body;
    if (!imageBase64 || typeof imageBase64 !== 'string') {
      return res.status(400).json({ success: false, message: 'Please provide valid image data' });
    }

    const cleanBase64 = imageBase64.replace(/^data:image\/[a-zA-Z0-9+.-]+;base64,/, '');
    const buffer = Buffer.from(cleanBase64, 'base64');

    if (buffer.length > 10 * 1024 * 1024) {
      return res.status(400).json({ success: false, message: 'Image size exceeds maximum limit of 10MB' });
    }

    const ext = extension && /^[a-zA-Z0-9]+$/.test(extension) ? extension : 'jpg';
    const filename = `avatar_${req.userId}_${Date.now()}.${ext}`;
    const uploadsDir = path.resolve(process.cwd(), 'public/uploads');
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }

    const filePath = path.join(uploadsDir, filename);
    await fs.promises.writeFile(filePath, buffer);

    const avatarUrl = `/uploads/${filename}`;

    const user = db.get('users').find((u) => u.id === req.userId);
    if (user) {
      user.profilePicture = avatarUrl;
      user.updatedAt = new Date().toISOString();
    }

    try {
      const pg = (await import('../db/postgres.js')).PostgresDatabase.getInstance();
      if (pg.isConnected()) {
        await pg.getPool().query(
          'UPDATE users SET profile_picture = $1, updated_at = NOW() WHERE id = $2',
          [avatarUrl, req.userId]
        );
      }
    } catch (_) {}

    return res.json({
      success: true,
      message: 'Profile photo uploaded and saved to database successfully',
      avatarUrl,
      fileName: filename,
    });
  } catch (err: any) {
    return res.status(500).json({ success: false, message: 'Failed to upload photo: ' + err.message });
  }
});

// ==========================================
// 2. ACCOUNTS & VPA MANAGEMENT (Issue 6: Ownership Authorization)
// ==========================================

apiRouter.get('/accounts/discover', authMiddleware, (req: AuthenticatedRequest, res) => {
  const user = db.get('users').find((u) => u.id === req.userId);
  const accounts = AccountService.discoverBankAccounts(user?.phone || '9876543210');
  return res.json({ success: true, eligibleAccounts: accounts });
});

apiRouter.post('/accounts/link', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { bankName, bankCode, ifsc, accountNumber, accountType, setAsPrimary, replaceOnboardingAccount } = req.body;
    if (!bankName || !ifsc) {
      return res.status(400).json({ success: false, message: 'bankName and ifsc are required.' });
    }

    const valIfsc = validateIfsc(ifsc);
    if (!valIfsc.valid) {
      return res.status(400).json({ success: false, message: valIfsc.error });
    }

    const account = AccountService.linkAccount({
      userId: req.userId!,
      bankName: String(bankName).trim(),
      bankCode: bankCode ? String(bankCode).trim() : undefined,
      ifsc: String(ifsc).trim().toUpperCase(),
      accountNumber: accountNumber ? String(accountNumber).trim() : undefined,
      accountType: accountType === 'CURRENT' ? 'CURRENT' : 'SAVINGS',
      setAsPrimary: !!setAsPrimary,
      replaceOnboardingAccount: !!replaceOnboardingAccount,
      // P0: Initial balance is strictly 0.00 (fabricated balances eliminated)
      initialBalance: 0.00,
    });

    AuditService.log({
      actorId: req.userId,
      action: 'ACCOUNT_LINKED',
      resource: 'ACCOUNT',
      resourceId: account.id,
      metadata: { bankName: account.bankName },
    });
    return res.json({ success: true, account });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.get('/accounts', authMiddleware, (req: AuthenticatedRequest, res) => {
  const accounts = AccountService.getAccounts(req.userId!);
  return res.json({ success: true, accounts });
});

apiRouter.post('/accounts/:id/set-primary', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const account = db.get('accounts').find((a) => a.id === req.params.id);
    if (!account) return res.status(404).json({ success: false, message: 'Account not found.' });
    if (account.userId !== req.userId && !req.isAdmin) {
      return res.status(403).json({ success: false, message: 'Unauthorized: You do not own this account.' });
    }

    const updated = AccountService.setPrimaryAccount(req.userId!, req.params.id as string);
    return res.json({ success: true, account: updated });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/accounts/add-money', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { accountId, amount, sourceNote } = req.body;
    const numAmount = parseFloat(amount);
    if (!numAmount || numAmount <= 0) {
      return res.status(400).json({ success: false, message: 'Amount must be greater than zero.' });
    }

    // P0: Block arbitrary balance creation in live production mode with active NPCI switch keys.
    // In local development, testing, or presentation mode (ENABLE_DEMO_FAUCET=true or when running without partner keys),
    // sandbox faucet deposits are permitted to allow teachers/demonstrators to fund accounts.
    const isLiveProductionWithBankKeys = config.isProduction && !!config.npciMerchantKey && !config.npciMerchantKey.includes('replace_');
    const allowDemoDeposit = !isLiveProductionWithBankKeys || process.env.ENABLE_DEMO_FAUCET === 'true';

    if (!allowDemoDeposit) {
      return res.status(403).json({
        success: false,
        code: 'DIRECT_DEPOSIT_PROHIBITED',
        message: 'Direct balance creation is prohibited in live production mode with active NPCI credentials. In demo mode, set ENABLE_DEMO_FAUCET=true or run in development mode.',
      });
    }

    const account = db.get('accounts').find((a) => a.id === accountId);
    if (account && account.userId !== req.userId && !req.isAdmin) {
      return res.status(403).json({ success: false, message: 'Unauthorized account credit attempt.' });
    }

    const result = AccountService.addMoneyToAccount({
      userId: req.userId!,
      accountId,
      amount: numAmount,
      sourceNote,
    });
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.get('/accounts/:id/balance', authMiddleware, (req: AuthenticatedRequest, res) => {
  const account = db.get('accounts').find((a) => a.id === req.params.id);
  if (!account) return res.status(404).json({ success: false, message: 'Account not found.' });
  if (account.userId !== req.userId && !req.isAdmin) {
    return res.status(403).json({ success: false, message: 'Forbidden: Cannot view another user’s balance.' });
  }
  return res.json({ success: true, balance: account.balance, isPrimary: account.isPrimary });
});

apiRouter.get('/vpa/resolve', vpaRateLimiter, (req, res) => {
  const vpa = req.query.vpa as string;
  if (!vpa || typeof vpa !== 'string') return res.status(400).json({ success: false, message: 'vpa query param required.' });
  const result = AccountService.resolveVpa(vpa.trim().toLowerCase());
  return res.json(result);
});

// ==========================================
// 3. CORE PAYMENTS & TRANSACTIONS (Issues 6, 7, 14, 15, 16, 17)
// ==========================================

apiRouter.post('/payments/pay', authMiddleware, paymentRateLimiter, async (req: AuthenticatedRequest, res) => {
  try {
    const { receiverVpa, amount, mpin, remark, senderAccountId, idempotencyKey, bypassScamShieldWarning } = req.body;

    const valAmount = validatePaymentAmount(amount, 100000);
    if (!valAmount.valid) {
      return res.status(400).json({ success: false, message: valAmount.error });
    }

    const valVpa = validateVpa(receiverVpa);
    if (!valVpa.valid) {
      return res.status(400).json({ success: false, message: valVpa.error });
    }

    if (!mpin || String(mpin).trim().length < 4) {
      return res.status(400).json({ success: false, message: 'Valid 4 or 6 digit UPI MPIN is required.' });
    }

    // Verify account ownership
    if (senderAccountId) {
      const senderAcc = db.get('accounts').find((a) => a.id === senderAccountId);
      if (!senderAcc || senderAcc.userId !== req.userId) {
        return res.status(403).json({ success: false, message: 'Selected sender account does not belong to you.' });
      }
    }

    const numAmount = parseFloat(amount);
    const cleanRemark = sanitizeRemark(remark);

    const result = await PaymentService.executePayment({
      senderUserId: req.userId!,
      senderAccountId,
      receiverVpa: receiverVpa.trim().toLowerCase(),
      amount: numAmount,
      mpin: String(mpin).trim(),
      remark: cleanRemark,
      idempotencyKey: idempotencyKey || (req.headers['idempotency-key'] as string),
      bypassScamShieldWarning: !!bypassScamShieldWarning,
    });

    res.setHeader('X-Simulation-Mode', String(config.isSimulationMode));
    return res.json({ ...result, isSimulated: config.isSimulationMode });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/payments/lite-pay', authMiddleware, paymentRateLimiter, async (req: AuthenticatedRequest, res) => {
  try {
    const { receiverVpa, amount, remark } = req.body;
    const valAmount = validatePaymentAmount(amount, 500);
    if (!valAmount.valid) {
      return res.status(400).json({ success: false, message: valAmount.error });
    }

    const valVpa = validateVpa(receiverVpa);
    if (!valVpa.valid) {
      return res.status(400).json({ success: false, message: valVpa.error });
    }

    const numAmount = parseFloat(amount);
    const cleanRemark = sanitizeRemark(remark);

    const transaction = await PaymentService.executeLitePayment({
      senderUserId: req.userId!,
      receiverVpa: receiverVpa.trim().toLowerCase(),
      amount: numAmount,
      remark: cleanRemark,
    });
    return res.json({ success: true, transaction });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.get('/payments/history', authMiddleware, (req: AuthenticatedRequest, res) => {
  const history = PaymentService.getTransactionHistory(req.userId!);
  return res.json({ success: true, transactions: history });
});

apiRouter.post('/payments/collect', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { payerVpa, amount, remark } = req.body;
    const valVpa = validateVpa(payerVpa);
    if (!valVpa.valid) {
      return res.status(400).json({ success: false, message: valVpa.error });
    }

    const valAmount = validatePaymentAmount(amount, 100000);
    if (!valAmount.valid) {
      return res.status(400).json({ success: false, message: valAmount.error });
    }

    const numAmount = parseFloat(amount);
    const cleanRemark = sanitizeRemark(remark);

    const collect = PaymentService.createCollectRequest({
      payeeUserId: req.userId!,
      payerVpa: payerVpa.trim().toLowerCase(),
      amount: numAmount,
      remark: cleanRemark,
    });
    return res.json({ success: true, collectRequest: collect });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/payments/collect/:id/approve', authMiddleware, paymentRateLimiter, async (req: AuthenticatedRequest, res) => {
  try {
    const { mpin } = req.body;
    if (!mpin) {
      return res.status(400).json({ success: false, message: 'UPI MPIN required to approve collect request.' });
    }

    const transaction = await PaymentService.approveCollectRequest(
      req.params.id as string,
      req.userId!,
      String(mpin).trim()
    );
    return res.json({ success: true, transaction });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

// P1 Issue 12: Payment Provider Webhook Signatures & Callback Verification (Raw Body & Strict State Machine)
apiRouter.post('/payments/webhook', async (req, res) => {
  try {
    const signature = (req.headers['x-webhook-signature'] || req.headers['x-razorpay-signature'] || '') as string;
    const rawPayload: Buffer | string = (req as any).rawBody || Buffer.from(JSON.stringify(req.body));

    const expectedSignature = crypto
      .createHmac('sha256', config.webhookSecret)
      .update(rawPayload)
      .digest('hex');

    if (
      !signature ||
      signature.length !== expectedSignature.length ||
      !crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expectedSignature))
    ) {
      AuditService.log({
        actorId: 'EXTERNAL_WEBHOOK',
        action: 'WEBHOOK_SIGNATURE_INVALID',
        resource: 'WEBHOOK',
        resourceId: req.body?.transactionId || 'unknown',
        metadata: { ip: req.ip },
      });
      return res.status(401).json({ success: false, message: 'Invalid webhook signature.' });
    }

    // P2: Webhook Replay Attack Protection (5-minute window)
    const timestampHeader = (req.headers['x-webhook-timestamp'] || req.body?.timestamp) as string;
    if (timestampHeader) {
      const parsedTime = new Date(timestampHeader).getTime();
      if (!isNaN(parsedTime)) {
        const deltaSeconds = Math.abs(Date.now() - parsedTime) / 1000;
        if (deltaSeconds > 300) {
          return res.status(401).json({
            success: false,
            message: 'Webhook request timestamp is expired (replay attack protection).',
          });
        }
      }
    }

    const { event, transactionId, status, upiRrn, reason } = req.body;
    if (!transactionId || !status) {
      return res.status(400).json({ success: false, message: 'Missing transactionId or status in webhook payload.' });
    }

    // P0: Validate allowed event types
    const ALLOWED_EVENTS = ['PAYMENT_SUCCESS', 'PAYMENT_FAILED', 'PAYMENT_REVERSED', 'REFUND_PROCESSED', 'CROSS_BORDER_SETTLED'];
    if (event && !ALLOWED_EVENTS.includes(event)) {
      return res.status(400).json({ success: false, message: `Unsupported webhook event type: ${event}` });
    }

    const transaction = db.get('transactions').find((t) => t.id === transactionId || t.txnRef === transactionId);
    if (!transaction) {
      return res.status(404).json({ success: false, message: 'Transaction not found for webhook callback.' });
    }

    // P0: Strict State Machine Transitions
    const currentStatus = transaction.status;

    // Idempotent duplicate check
    if (currentStatus === status) {
      return res.json({ success: true, message: `Duplicate webhook event ignored (already ${status}).` });
    }

    if (currentStatus === 'PENDING_PARTNER_SETTLEMENT' || transaction.txnType === 'CROSS_BORDER') {
      await CrossBorderService.confirmPartnerSettlement({
        transferId: transaction.id,
        partnerRrn: upiRrn || `PARTNER_${Date.now()}`,
        status: status === 'SUCCESS' ? 'SUCCESS' : 'FAILED',
        failureReason: reason,
      });
    } else if (currentStatus === 'PENDING' && (status === 'SUCCESS' || status === 'FAILED')) {
      transaction.status = status;
      if (upiRrn) transaction.upiRrn = upiRrn;
      if (status === 'FAILED' && reason) transaction.failureReason = reason;
      transaction.completedAt = new Date().toISOString();
      db.save();
    } else if (currentStatus === 'SUCCESS' && status === 'REVERSED') {
      await LedgerService.executeReversal({
        originalTransaction: transaction,
        reason: reason || 'Reversal requested via provider webhook',
      });
    } else {
      return res.status(400).json({
        success: false,
        message: `Illegal state transition from ${currentStatus} to ${status}.`,
      });
    }

    AuditService.log({
      actorId: 'EXTERNAL_WEBHOOK',
      action: `WEBHOOK_PAYMENT_${status}`,
      resource: 'TRANSACTION',
      resourceId: transaction.id,
      metadata: { event, status, upiRrn },
    });

    return res.json({ success: true, message: 'Webhook callback processed successfully.' });
  } catch (err: any) {
    return res.status(500).json({ success: false, message: 'Webhook processing failed.' });
  }
});

// ==========================================
// 4. SCAM SHIELD
// ==========================================

apiRouter.post('/scam-shield/analyze', authMiddleware, (req: AuthenticatedRequest, res) => {
  const { receiverVpa, amount, remark } = req.body;
  const analysis = ScamShieldService.analyzePaymentRisk({
    senderUserId: req.userId!,
    senderVpa: req.userVpa!,
    receiverVpa,
    amount: parseFloat(amount || '0'),
    remark,
  });
  return res.json({ success: true, analysis });
});

apiRouter.post('/scam-shield/report', authMiddleware, (req: AuthenticatedRequest, res) => {
  const { vpa, phone, reason } = req.body;
  if (!vpa || !reason) {
    return res.status(400).json({ success: false, message: 'vpa and reason are required.' });
  }
  const result = ScamShieldService.reportFraud({
    reportedByUserId: req.userId!,
    vpa,
    phone,
    reason,
  });
  return res.json(result);
});

// ==========================================
// 5. PROTECTED PAY (BUYER ESCROW)
// ==========================================

apiRouter.post('/protected-pay/initiate', authMiddleware, paymentRateLimiter, (req: AuthenticatedRequest, res) => {
  try {
    const { sellerVpa, sellerName, amount, itemDescription, autoReleaseDays } = req.body;
    const escrow = ProtectedPayService.createEscrow({
      buyerUserId: req.userId!,
      buyerVpa: req.userVpa!,
      sellerVpa,
      sellerName: sellerName || 'Verified Seller',
      amount: parseFloat(amount),
      itemDescription,
      autoReleaseDays: autoReleaseDays ? parseInt(autoReleaseDays, 10) : 7,
    });
    return res.json({ success: true, escrow });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/protected-pay/:id/confirm-delivery', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const escrow = ProtectedPayService.confirmDelivery(req.params.id as string, req.userId!);
    return res.json({ success: true, escrow });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/protected-pay/:id/dispute', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { reason, evidenceUrl } = req.body;
    const escrow = ProtectedPayService.raiseDispute({
      escrowId: req.params.id as string,
      buyerUserId: req.userId!,
      disputeReason: reason,
      disputeEvidenceUrl: evidenceUrl,
    });
    return res.json({ success: true, escrow });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.get('/protected-pay/my-escrows', authMiddleware, (req: AuthenticatedRequest, res) => {
  const escrows = ProtectedPayService.getEscrowsForUser(req.userId!);
  return res.json({ success: true, escrows });
});

// ==========================================
// 6. CROSS-BORDER RUPEE-REMIT
// ==========================================

apiRouter.get('/cross-border/currencies', (req, res) => {
  const corridors = CrossBorderService.getSupportedCurrencies();
  return res.json({ success: true, corridors });
});

apiRouter.post('/cross-border/quote', authMiddleware, async (req: AuthenticatedRequest, res) => {
  try {
    const { targetCurrency, targetAmount, sourceAmountInr } = req.body;
    const quote = await CrossBorderService.generateQuote({
      userId: req.userId!,
      targetCurrency,
      targetAmount: targetAmount ? parseFloat(targetAmount) : undefined,
      sourceAmountInr: sourceAmountInr ? parseFloat(sourceAmountInr) : undefined,
    });
    return res.json({ success: true, quote });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/cross-border/execute', authMiddleware, paymentRateLimiter, async (req: AuthenticatedRequest, res) => {
  try {
    const { quoteId, beneficiaryName, beneficiaryIbanOrAccount, purposeCode, mpin } = req.body;
    if (!mpin) {
      return res.status(400).json({ success: false, message: 'UPI MPIN required to authorize remittance.' });
    }
    const result = await CrossBorderService.executeTransfer({
      userId: req.userId!,
      quoteId,
      beneficiaryName,
      beneficiaryAccountOrIban: beneficiaryIbanOrAccount,
      purposeCode,
      mpin: String(mpin).trim(),
    });
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.get('/cross-border/lrs-status', authMiddleware, (req: AuthenticatedRequest, res) => {
  const user = db.get('users').find((u) => u.id === req.userId);
  const used = user?.lrsUsedUsd || 0;
  const limit = 250000;
  return res.json({
    success: true,
    lrsUsedUsd: used,
    lrsLimitUsd: limit,
    remainingUsd: Math.max(0, limit - used),
  });
});

// ==========================================
// 7. MERCHANTS & SOUNDBOX (P0 Issue 9 & P2: Auth & Ownership Checks)
// ==========================================

apiRouter.post('/merchants/qr', authMiddleware, merchantRateLimiter, async (req: AuthenticatedRequest, res) => {
  try {
    const { merchantVpa, merchantName, amount, description } = req.body;
    const qrData = await MerchantService.generateUpiQr({
      vpa: merchantVpa || req.userVpa!,
      payeeName: merchantName || 'AikSetra Merchant',
      amount: amount ? parseFloat(amount) : undefined,
      transactionNote: description,
    });
    return res.json({ success: true, ...qrData });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/merchants/paylinks', authMiddleware, merchantRateLimiter, async (req: AuthenticatedRequest, res) => {
  try {
    const { merchantId, amount, description } = req.body;
    if (!merchantId || !amount) {
      return res.status(400).json({ success: false, message: 'merchantId and amount are required.' });
    }
    const numAmount = parseFloat(amount);
    if (isNaN(numAmount) || numAmount <= 0) {
      return res.status(400).json({ success: false, message: 'Amount must be greater than zero.' });
    }

    // Verify merchant ownership
    const merchant = db.get('merchants').find((m) => m.id === merchantId);
    if (!merchant) return res.status(404).json({ success: false, message: 'Merchant not found.' });
    if (merchant.userId !== req.userId && !req.isAdmin) {
      return res.status(403).json({ success: false, message: 'Unauthorized: You do not own this merchant profile.' });
    }

    const payLink = await MerchantService.createPayLink({
      merchantId,
      amount: numAmount,
      description,
    });
    return res.json({ success: true, payLink });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.get('/merchants/paylinks/:id', (req, res) => {
  const payLink = MerchantService.getPayLink(req.params.id as string);
  if (!payLink) return res.status(404).json({ success: false, message: 'Pay link not found.' });
  return res.json({ success: true, payLink });
});

apiRouter.get('/merchants/dashboard/:id', authMiddleware, (req: AuthenticatedRequest, res) => {
  const merchant = db.get('merchants').find((m) => m.id === req.params.id);
  if (!merchant) return res.status(404).json({ success: false, message: 'Merchant not found.' });
  if (merchant.userId !== req.userId && !req.isAdmin) {
    return res.status(403).json({ success: false, message: 'Unauthorized: Access to merchant dashboard denied.' });
  }

  const dashboard = MerchantService.getMerchantDashboard(req.params.id as string);
  return res.json({ success: true, dashboard });
});

apiRouter.get('/merchants/soundbox/stream', authMiddleware, (req: AuthenticatedRequest, res) => {
  soundboxService.registerSseClient(res);
});

apiRouter.get('/merchants/soundbox/recent', authMiddleware, (req: AuthenticatedRequest, res) => {
  return res.json({ success: true, events: soundboxService.getRecentEvents() });
});

// ==========================================
// 8. MONEY VAULTS (DIGITAL GULLAK)
// ==========================================

apiRouter.get('/vaults', authMiddleware, (req: AuthenticatedRequest, res) => {
  const vaults = VaultService.getVaults(req.userId!);
  return res.json({ success: true, vaults });
});

apiRouter.post('/vaults', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { name, targetAmount, category, autoRoundUp, roundUpMultiple } = req.body;
    const vault = VaultService.createVault({
      userId: req.userId!,
      name,
      targetAmount: parseFloat(targetAmount || '5000'),
      category,
      autoRoundUp: autoRoundUp !== undefined ? !!autoRoundUp : true,
      roundUpMultiple: roundUpMultiple ? parseInt(roundUpMultiple, 10) : 10,
    });
    return res.json({ success: true, vault });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/vaults/:id/deposit', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const vault = db.get('vaults').find((v) => v.id === req.params.id);
    if (!vault) return res.status(404).json({ success: false, message: 'Vault not found.' });
    if (vault.userId !== req.userId && !req.isAdmin) {
      return res.status(403).json({ success: false, message: 'Unauthorized vault deposit attempt.' });
    }

    const { amount } = req.body;
    const updated = VaultService.deposit(req.params.id as string, req.userId!, parseFloat(amount));
    return res.json({ success: true, vault: updated });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/vaults/:id/withdraw', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const vault = db.get('vaults').find((v) => v.id === req.params.id);
    if (!vault) return res.status(404).json({ success: false, message: 'Vault not found.' });
    if (vault.userId !== req.userId && !req.isAdmin) {
      return res.status(403).json({ success: false, message: 'Unauthorized vault withdrawal attempt.' });
    }

    const { amount } = req.body;
    const updated = VaultService.withdraw(req.params.id as string, req.userId!, parseFloat(amount));
    return res.json({ success: true, vault: updated });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

// ==========================================
// 9. SPLIT BILLS
// ==========================================

apiRouter.get('/split', authMiddleware, (req: AuthenticatedRequest, res) => {
  const splits = SplitService.getSplitsForUser(req.userId!);
  return res.json({ success: true, splitBills: splits });
});

apiRouter.post('/split', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { title, totalAmount, participants } = req.body;
    const splitBill = SplitService.createSplitBill({
      createdByUserId: req.userId!,
      title,
      totalAmount: parseFloat(totalAmount),
      participants,
    });
    return res.json({ success: true, splitBill });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/split/:id/pay/:participantId', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const splitBill = SplitService.markParticipantPaid(
      req.params.id as string,
      req.params.participantId as string
    );
    return res.json({ success: true, splitBill });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

// ==========================================
// 10. DISPUTES & CHARGEBACKS
// ==========================================

apiRouter.get('/disputes', authMiddleware, (req: AuthenticatedRequest, res) => {
  const disputes = DisputeService.getDisputesForUser(req.userId!);
  return res.json({ success: true, disputes });
});

apiRouter.post('/disputes', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { txnId, amount, category, description } = req.body;
    const txn = db.get('transactions').find((t) => t.id === txnId);
    const dispute = DisputeService.createDispute({
      userId: req.userId!,
      txnId,
      upiRrn: txn?.upiRrn || `RRN-${Date.now()}`,
      amount: parseFloat(amount),
      category,
      description,
    });
    return res.json({ success: true, dispute });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

// ==========================================
// 11. BANKING SWITCH SIMULATOR & CONTROL (Admin Protected - Issue 10 & 38)
// ==========================================

apiRouter.get('/psp-simulator/status', adminAuthMiddleware, (req, res) => {
  return res.json({
    success: true,
    currentMode: pspSimulator.getMode(),
    availableModes: ['SUCCESS', 'FLAKY', 'FAIL_MPIN', 'TIMEOUT', 'INSUFFICIENT_FUNDS'],
  });
});

apiRouter.post('/psp-simulator/mode', adminAuthMiddleware, (req, res) => {
  const { mode } = req.body;
  if (!['SUCCESS', 'FLAKY', 'FAIL_MPIN', 'TIMEOUT', 'INSUFFICIENT_FUNDS'].includes(mode)) {
    return res.status(400).json({ success: false, message: 'Invalid simulator mode.' });
  }
  pspSimulator.setMode(mode);
  return res.json({ success: true, mode });
});

// ==========================================
// 12. BBPS UTILITY BILL PAYMENTS & RECHARGES
// ==========================================

apiRouter.get('/bills/billers', (req, res) => {
  const category = req.query.category as string | undefined;
  return res.json({ success: true, billers: BillPayService.getBillers(category) });
});

apiRouter.post('/bills/fetch', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { billerId, consumerNumber } = req.body;
    const bill = BillPayService.fetchBillDetails({
      userId: req.userId!,
      billerId,
      consumerNumber,
    });
    return res.json({ success: true, bill });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/bills/pay', authMiddleware, paymentRateLimiter, (req: AuthenticatedRequest, res) => {
  try {
    const { billerId, consumerNumber, amount, mpin, billNumber, planOrUsage } = req.body;
    if (!mpin || String(mpin).trim().length < 4) {
      return res.status(400).json({ success: false, message: 'Valid UPI MPIN is required to pay utility bills.' });
    }
    const result = BillPayService.payBill({
      userId: req.userId!,
      billerId,
      consumerNumber,
      amount: parseFloat(amount),
      mpin: String(mpin).trim(),
      billNumber,
      planOrUsage,
    });
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.get('/bills/history', authMiddleware, (req: AuthenticatedRequest, res) => {
  return res.json({ success: true, bills: BillPayService.getUserBillHistory(req.userId!) });
});

// ==========================================
// 13. BANK AUTO-SIP & WEALTH PLANS
// ==========================================

apiRouter.get('/sip/plans', authMiddleware, (req: AuthenticatedRequest, res) => {
  const data = SipService.getPlansAndPortfolio(req.userId!);
  return res.json({ success: true, ...data });
});

apiRouter.post('/sip/create', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { planId, monthlyAmount, debitDay, mpin } = req.body;
    if (!mpin || String(mpin).trim().length < 4) {
      return res.status(400).json({ success: false, message: 'UPI MPIN is required to establish auto-debit mandate.' });
    }
    const result = SipService.createSipMandate({
      userId: req.userId!,
      planId,
      monthlyAmount: parseFloat(monthlyAmount),
      debitDay: parseInt(debitDay || '5', 10),
      mpin: String(mpin).trim(),
    });
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/sip/:id/installment', authMiddleware, paymentRateLimiter, (req: AuthenticatedRequest, res) => {
  try {
    const { amount, mpin } = req.body;
    if (!mpin || String(mpin).trim().length < 4) {
      return res.status(400).json({ success: false, message: 'UPI MPIN required to authorize installment debit.' });
    }
    const result = SipService.payAdditionalInstallment({
      userId: req.userId!,
      sipId: req.params.id as string,
      amount: amount ? parseFloat(amount) : undefined,
      mpin: String(mpin).trim(),
    });
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/sip/:id/redeem', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { mpin } = req.body;
    if (!mpin || String(mpin).trim().length < 4) {
      return res.status(400).json({ success: false, message: 'UPI MPIN required to authorize redemption.' });
    }
    const result = SipService.redeemSipToBank({
      userId: req.userId!,
      sipId: req.params.id as string,
      mpin: String(mpin).trim(),
    });
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.get('/merchants/local', (req, res) => {
  const merchants = db.get('merchants');
  return res.json({ success: true, merchants });
});

// ==========================================
// 14. DOUBLE-ENTRY LEDGER & RECONCILIATION AUDIT (Issue 26 & 29)
// ==========================================

apiRouter.get('/ledger/my-entries', authMiddleware, (req: AuthenticatedRequest, res) => {
  const userAccounts = db.get('accounts').filter((a) => a.userId === req.userId);
  const userAccountIds = new Set(userAccounts.map((a) => a.id));

  const entries = db
    .get('ledger')
    .filter((e) => userAccountIds.has(e.accountId))
    .slice(-100);

  return res.json({ success: true, ledgerEntries: entries });
});

apiRouter.get('/ledger/reconcile/:accountId', authMiddleware, (req: AuthenticatedRequest, res) => {
  const account = db.get('accounts').find((a) => a.id === req.params.accountId);
  if (!account) return res.status(404).json({ success: false, message: 'Account not found.' });
  if (account.userId !== req.userId && !req.isAdmin) {
    return res.status(403).json({ success: false, message: 'Unauthorized reconciliation query.' });
  }

  const result = LedgerService.reconcileAccount(account.id);
  return res.json({ success: true, accountId: account.id, ...result });
});

// ==========================================
// 15. LIVE GATEWAY & SMS API KEY CONFIGURATION (Admin Protected - Issue 38)
// ==========================================

apiRouter.get('/config/gateway', adminAuthMiddleware, (req, res) => {
  const status = SmsService.getGatewayStatus();
  return res.json({
    success: true,
    gateway: {
      ...status,
      // Mask credentials
      apiKeyMasked: (status.fast2smsConfigured || status.msg91Configured || status.twilioConfigured) ? '••••••••' : 'None',
    },
  });
});

apiRouter.post('/config/gateway', adminAuthMiddleware, (req, res) => {
  SmsService.updateGatewayConfig(req.body || {});
  AuditService.log({
    actorId: (req as any).userId || 'ADMIN',
    action: 'GATEWAY_CREDENTIALS_UPDATED',
    resource: 'SMS_GATEWAY',
  });
  return res.json({
    success: true,
    message: 'Live Gateway & SMS credentials updated.',
    gateway: SmsService.getGatewayStatus(),
  });
});

// ==========================================
// 16. AUTOPAY & RECURRING MANDATES (Section 3)
// ==========================================

apiRouter.get('/autopay/mandates', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const data = AutoPayService.getMandates(req.userId!);
    return res.json({ success: true, ...data });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/autopay/create', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { billerOrPayeeName, vpa, category, frequency, maxAmount, scheduledDay, mpin } = req.body;
    if (!billerOrPayeeName || !vpa || !maxAmount || !mpin) {
      return res.status(400).json({ success: false, message: 'Mandate details and UPI MPIN are required.' });
    }
    const result = AutoPayService.createMandate({
      userId: req.userId!,
      billerOrPayeeName,
      vpa,
      category: category || 'BILLS',
      frequency: frequency || 'MONTHLY',
      maxAmount: Number(maxAmount),
      scheduledDay: Number(scheduledDay) || 5,
      mpin: String(mpin).trim(),
    });
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.patch('/autopay/:id/status', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { status } = req.body;
    if (!['ACTIVE', 'PAUSED', 'CANCELLED'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid mandate status.' });
    }
    const result = AutoPayService.updateMandateStatus(req.params.id as string, req.userId!, status);
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/autopay/:id/debit', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const result = AutoPayService.executeMandateDebit(req.params.id as string, req.userId!, req.body.amount ? Number(req.body.amount) : undefined);
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

// ==========================================
// 17. REWARDS & REFERRALS (Section 10)
// ==========================================

apiRouter.get('/rewards/overview', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const data = RewardsService.getRewardsOverview(req.userId!);
    return res.json({ success: true, ...data });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/rewards/coupons/:id/claim', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const result = RewardsService.claimCoupon(req.params.id as string);
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

// ==========================================
// 18. AIKSETRA BUSINESS MODE (Section 11)
// ==========================================

apiRouter.get('/business/profile', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const data = BusinessService.getBusinessProfile(req.userId!);
    return res.json({ success: true, ...data });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.get('/business/invoices', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const invoices = BusinessService.getInvoices(req.userId!);
    return res.json({ success: true, invoices });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/business/invoices/create', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { customerName, customerPhone, items, dueDate } = req.body;
    if (!customerName || !items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ success: false, message: 'Customer name and line items are required.' });
    }
    const invoice = BusinessService.createInvoice({
      userId: req.userId!,
      customerName,
      customerPhone: customerPhone || '',
      items,
      dueDate,
    });
    return res.json({ success: true, invoice });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

// ==========================================
// 19. FINANCIAL TOOLS & CALCULATORS (Section 5)
// ==========================================

apiRouter.get('/tools/fx-rates', (req, res) => {
  const data = FinancialToolsService.getLiveRates();
  return res.json(data);
});

apiRouter.post('/tools/calculate-emi', (req, res) => {
  const { principal, annualRatePct, tenureMonths } = req.body;
  const result = FinancialToolsService.calculateEmi(Number(principal) || 500000, Number(annualRatePct) || 8.5, Number(tenureMonths) || 60);
  return res.json({ success: true, ...result });
});

apiRouter.post('/tools/calculate-sip', (req, res) => {
  const { monthlyInvestment, annualRatePct, years } = req.body;
  const result = FinancialToolsService.calculateSip(Number(monthlyInvestment) || 5000, Number(annualRatePct) || 15.0, Number(years) || 10);
  return res.json({ success: true, ...result });
});

apiRouter.post('/tools/calculate-fd', (req, res) => {
  const { principal, annualRatePct, years, compoundFreq } = req.body;
  const result = FinancialToolsService.calculateFd(Number(principal) || 100000, Number(annualRatePct) || 7.1, Number(years) || 3, Number(compoundFreq) || 4);
  return res.json({ success: true, ...result });
});

apiRouter.post('/tools/calculate-gst', (req, res) => {
  const { amount, gstRatePct, isExclusive } = req.body;
  const result = FinancialToolsService.calculateGst(Number(amount) || 1000, Number(gstRatePct) || 18, isExclusive !== false);
  return res.json({ success: true, ...result });
});

apiRouter.post('/tools/estimate-tax', (req, res) => {
  const { annualGrossIncome } = req.body;
  const result = FinancialToolsService.estimateIncomeTax(Number(annualGrossIncome) || 1200000);
  return res.json({ success: true, ...result });
});
