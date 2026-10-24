import { Router } from 'express';
import { db } from '../db/database.js';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth.middleware.js';
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

export const apiRouter = Router();

// ==========================================
// 1. AUTH, OTP & DEVICE BINDING
// ==========================================
apiRouter.post('/auth/send-otp', async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) {
      return res.status(400).json({ success: false, message: 'Please provide a 10-digit mobile number.' });
    }
    const result = await AuthService.sendOtp(phone);
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/auth/verify-otp', (req, res) => {
  try {
    const { phone, otp, deviceId, simId, fullName, selectedBank } = req.body;
    if (!phone || !otp) {
      return res.status(400).json({ success: false, message: 'Phone number and OTP are required.' });
    }
    const result = AuthService.verifyOtpAndLogin({
      phone,
      otp,
      deviceId: deviceId || 'device_android_verified',
      simId: simId || 'sim_slot_1_jio',
      fullName,
      selectedBank,
    });
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/auth/register-device', (req, res) => {
  try {
    const { phone, deviceId, simId, fullName } = req.body;
    if (!phone || !deviceId || !simId) {
      return res.status(400).json({ success: false, message: 'phone, deviceId and simId are required.' });
    }
    const result = AuthService.verifyOtpAndLogin({
      phone,
      otp: '123456',
      deviceId,
      simId,
      fullName,
    });
    return res.json(result);
  } catch (err: any) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

apiRouter.post('/auth/set-mpin', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { mpin } = req.body;
    AuthService.setMpin(req.userId!, mpin);
    return res.json({ success: true, message: 'UPI MPIN configured successfully.' });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.get('/auth/me', authMiddleware, (req: AuthenticatedRequest, res) => {
  const user = db.get('users').find((u) => u.id === req.userId);
  if (!user) return res.status(404).json({ success: false, message: 'User not found.' });
  const accounts = db.get('accounts').filter((a) => a.userId === req.userId);
  return res.json({ success: true, user, accounts });
});

// ==========================================
// 2. ACCOUNTS & VPA MANAGEMENT
// ==========================================
apiRouter.get('/accounts/discover', authMiddleware, (req: AuthenticatedRequest, res) => {
  const user = db.get('users').find((u) => u.id === req.userId);
  const accounts = AccountService.discoverBankAccounts(user?.phone || '9876543210');
  return res.json({ success: true, eligibleAccounts: accounts });
});

apiRouter.post('/accounts/link', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const account = AccountService.linkAccount({ userId: req.userId!, ...req.body });
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
    const account = AccountService.setPrimaryAccount(req.userId!, req.params.id as string);
    return res.json({ success: true, account });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/accounts/add-money', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { accountId, amount, sourceNote } = req.body;
    const result = AccountService.addMoneyToAccount({
      userId: req.userId!,
      accountId,
      amount: parseFloat(amount),
      sourceNote,
    });
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.get('/accounts/:id/balance', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const balance = AccountService.getBalance(req.params.id as string, req.userId!);
    return res.json({ success: true, accountId: req.params.id as string, balance });
  } catch (err: any) {
    return res.status(404).json({ success: false, message: err.message });
  }
});

apiRouter.get('/vpa/resolve', (req, res) => {
  const vpa = req.query.vpa as string;
  if (!vpa) return res.status(400).json({ success: false, message: 'vpa query parameter is required.' });
  const result = AccountService.resolveVpa(vpa);
  return res.json(result);
});

// ==========================================
// 3. CORE PAYMENTS & TRANSACTIONS
// ==========================================
apiRouter.post('/payments/pay', authMiddleware, async (req: AuthenticatedRequest, res) => {
  try {
    const { receiverVpa, amount, mpin, remark, senderAccountId, idempotencyKey, bypassScamShieldWarning } = req.body;
    if (!receiverVpa || !amount) {
      return res.status(400).json({ success: false, message: 'receiverVpa and amount are required.' });
    }

    const result = await PaymentService.executePayment({
      senderUserId: req.userId!,
      senderAccountId,
      receiverVpa,
      amount: parseFloat(amount),
      mpin,
      remark,
      idempotencyKey,
      bypassScamShieldWarning,
    });

    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/payments/lite-pay', authMiddleware, async (req: AuthenticatedRequest, res) => {
  try {
    const { receiverVpa, amount, remark } = req.body;
    const transaction = await PaymentService.executeLitePayment({
      senderUserId: req.userId!,
      receiverVpa,
      amount: parseFloat(amount),
      remark,
    });
    return res.json({ success: true, transaction });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.get('/payments/history', authMiddleware, (req: AuthenticatedRequest, res) => {
  const transactions = PaymentService.getTransactionHistory(req.userId!);
  return res.json({ success: true, transactions });
});

apiRouter.post('/payments/collect', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { payerVpa, amount, remark } = req.body;
    const collect = PaymentService.createCollectRequest({
      payerVpa,
      payeeUserId: req.userId!,
      amount: parseFloat(amount),
      remark,
    });
    return res.json({ success: true, collectRequest: collect });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/payments/collect/:id/approve', authMiddleware, async (req: AuthenticatedRequest, res) => {
  try {
    const { mpin } = req.body;
    const transaction = await PaymentService.approveCollectRequest(req.params.id as string, req.userId!, mpin);
    return res.json({ success: true, transaction });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

// ==========================================
// 4. SCAM SHIELD (ORIGINAL DIFFERENTIATOR)
// ==========================================
apiRouter.post('/scam-shield/analyze', authMiddleware, (req: AuthenticatedRequest, res) => {
  const { receiverVpa, amount, remark, expectedPayeeName } = req.body;
  const analysis = ScamShieldService.analyzePaymentRisk({
    senderUserId: req.userId,
    senderVpa: req.userVpa || '',
    receiverVpa,
    amount: parseFloat(amount || '0'),
    remark,
    expectedPayeeName,
  });
  return res.json({ success: true, analysis });
});

apiRouter.post('/scam-shield/report', authMiddleware, (req: AuthenticatedRequest, res) => {
  const { vpa, phone, reason } = req.body;
  const result = ScamShieldService.reportFraud({
    vpa,
    phone,
    reason,
    reportedByUserId: req.userId!,
  });
  return res.json(result);
});

// ==========================================
// 5. PROTECTED PAY (ESCROW FOR STRANGERS)
// ==========================================
apiRouter.post('/protected-pay/initiate', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { sellerVpa, sellerName, amount, itemDescription, autoReleaseDays } = req.body;
    const escrow = ProtectedPayService.createEscrow({
      buyerUserId: req.userId!,
      buyerVpa: req.userVpa!,
      sellerVpa,
      sellerName,
      amount: parseFloat(amount),
      itemDescription,
      autoReleaseDays,
    });
    return res.json({ success: true, escrow });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/protected-pay/:id/confirm-delivery', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const escrow = ProtectedPayService.confirmDelivery(req.params.id as string, req.userId!);
    return res.json({ success: true, escrow, message: 'Delivery confirmed. Escrow funds released to seller.' });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/protected-pay/:id/dispute', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { disputeReason, disputeEvidenceUrl } = req.body;
    const escrow = ProtectedPayService.raiseDispute({
      escrowId: req.params.id as string,
      buyerUserId: req.userId!,
      disputeReason,
      disputeEvidenceUrl,
    });
    return res.json({ success: true, escrow, message: 'Dispute registered. Escrow payout paused.' });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.get('/protected-pay/my-escrows', authMiddleware, (req: AuthenticatedRequest, res) => {
  const escrows = ProtectedPayService.getEscrowsForUser(req.userId!);
  return res.json({ success: true, escrows });
});

// ==========================================
// 6. CROSS-BORDER & RUPEE BRIDGE
// ==========================================
apiRouter.get('/cross-border/currencies', async (req, res) => {
  await CrossBorderService.refreshLiveRates();
  const currencies = CrossBorderService.getSupportedCurrencies();
  return res.json({ success: true, currencies });
});

apiRouter.post('/cross-border/quote', authMiddleware, async (req: AuthenticatedRequest, res) => {
  await CrossBorderService.refreshLiveRates();
  try {
    const { targetCurrency, targetAmount, sourceAmountInr } = req.body;
    const quote = CrossBorderService.generateQuote({
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

apiRouter.post('/cross-border/execute', authMiddleware, async (req: AuthenticatedRequest, res) => {
  try {
    const { quoteId, beneficiaryName, beneficiaryAccountOrIban, purposeCode, mpin } = req.body;
    if (!quoteId || !beneficiaryName || !beneficiaryAccountOrIban) {
      return res.status(400).json({ success: false, message: 'quoteId, beneficiaryName, and beneficiaryAccountOrIban are required.' });
    }
    const result = await CrossBorderService.executeTransfer({
      userId: req.userId!,
      quoteId,
      beneficiaryName,
      beneficiaryAccountOrIban,
      purposeCode,
      mpin: mpin || '1234',
    });
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.get('/cross-border/lrs-status', authMiddleware, (req: AuthenticatedRequest, res) => {
  const status = CrossBorderService.getLrsStatus(req.userId!);
  return res.json({ success: true, lrsStatus: status });
});

// ==========================================
// 7. MERCHANT SERVICES & SOUNDBOX
// ==========================================
apiRouter.post('/merchants/qr', async (req, res) => {
  try {
    const { vpa, payeeName, amount, transactionNote } = req.body;
    const qrResult = await MerchantService.generateUpiQr({ vpa, payeeName, amount, transactionNote });
    return res.json({ success: true, ...qrResult });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/merchants/paylinks', async (req, res) => {
  try {
    const { merchantId, amount, description } = req.body;
    const payLink = await MerchantService.createPayLink({
      merchantId,
      amount: parseFloat(amount),
      description,
    });
    return res.json({ success: true, payLink });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.get('/merchants/paylinks/:id', (req, res) => {
  const payLink = MerchantService.getPayLink(req.params.id);
  if (!payLink) return res.status(404).json({ success: false, message: 'Pay link not found.' });
  return res.json({ success: true, payLink });
});

apiRouter.get('/merchants/dashboard/:id', (req, res) => {
  try {
    const data = MerchantService.getMerchantDashboard(req.params.id);
    return res.json({ success: true, ...data });
  } catch (err: any) {
    return res.status(404).json({ success: false, message: err.message });
  }
});

// SSE Stream for Real-time Merchant Soundbox alerts
apiRouter.get('/merchants/soundbox/stream', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  soundboxService.registerSseClient(res);

  req.on('close', () => {
    soundboxService.removeSseClient(res);
  });
});

apiRouter.get('/merchants/soundbox/recent', (req, res) => {
  return res.json({ success: true, events: soundboxService.getRecentEvents() });
});

// ==========================================
// 8. MONEY VAULTS & SMART SPLIT
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
      targetAmount: parseFloat(targetAmount),
      category,
      autoRoundUp,
      roundUpMultiple,
    });
    return res.json({ success: true, vault });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/vaults/:id/deposit', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { amount } = req.body;
    const vault = VaultService.deposit(req.params.id as string, req.userId!, parseFloat(amount));
    return res.json({ success: true, vault });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/vaults/:id/withdraw', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { amount } = req.body;
    const vault = VaultService.withdraw(req.params.id as string, req.userId!, parseFloat(amount));
    return res.json({ success: true, vault });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.get('/split', authMiddleware, (req: AuthenticatedRequest, res) => {
  const splits = SplitService.getSplitsForUser(req.userId!);
  return res.json({ success: true, splitBills: splits });
});

apiRouter.post('/split', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { title, totalAmount, participants } = req.body;
    const bill = SplitService.createSplitBill({
      createdByUserId: req.userId!,
      title,
      totalAmount: parseFloat(totalAmount),
      participants,
    });
    return res.json({ success: true, splitBill: bill });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/split/:id/pay/:participantId', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const bill = SplitService.markParticipantPaid(req.params.id as string, req.params.participantId as string);
    return res.json({ success: true, splitBill: bill });
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

// ==========================================
// 9. DISPUTES
// ==========================================
apiRouter.get('/disputes', authMiddleware, (req: AuthenticatedRequest, res) => {
  const disputes = DisputeService.getDisputesForUser(req.userId!);
  return res.json({ success: true, disputes });
});

apiRouter.post('/disputes', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { txnId, upiRrn, amount, category, description } = req.body;
    const dispute = DisputeService.createDispute({
      userId: req.userId!,
      txnId,
      upiRrn,
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
// 10. PSP / NPCI SIMULATOR TOGGLES
// ==========================================
apiRouter.get('/psp-simulator/status', (req, res) => {
  return res.json({
    success: true,
    currentMode: pspSimulator.getMode(),
    availableModes: ['SUCCESS', 'FLAKY', 'FAIL_MPIN', 'TIMEOUT', 'INSUFFICIENT_FUNDS'],
  });
});

apiRouter.post('/psp-simulator/mode', (req, res) => {
  const { mode } = req.body;
  if (!['SUCCESS', 'FLAKY', 'FAIL_MPIN', 'TIMEOUT', 'INSUFFICIENT_FUNDS'].includes(mode)) {
    return res.status(400).json({ success: false, message: 'Invalid simulator mode.' });
  }
  pspSimulator.setMode(mode);
  return res.json({ success: true, mode });
});

// ==========================================
// 11. BBPS UTILITY BILL PAYMENTS & RECHARGES
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

apiRouter.post('/bills/pay', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { billerId, consumerNumber, amount, mpin, billNumber, planOrUsage } = req.body;
    const result = BillPayService.payBill({
      userId: req.userId!,
      billerId,
      consumerNumber,
      amount: parseFloat(amount),
      mpin: mpin || '1234',
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
// 12. BANK AUTO-SIP & WEALTH PLANS
// ==========================================
apiRouter.get('/sip/plans', authMiddleware, (req: AuthenticatedRequest, res) => {
  const data = SipService.getPlansAndPortfolio(req.userId!);
  return res.json({ success: true, ...data });
});

apiRouter.post('/sip/create', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { planId, monthlyAmount, debitDay, mpin } = req.body;
    const result = SipService.createSipMandate({
      userId: req.userId!,
      planId,
      monthlyAmount: parseFloat(monthlyAmount),
      debitDay: parseInt(debitDay || '5', 10),
      mpin: mpin || '1234',
    });
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/sip/:id/installment', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { amount, mpin } = req.body;
    const result = SipService.payAdditionalInstallment({
      userId: req.userId!,
      sipId: req.params.id as string,
      amount: amount ? parseFloat(amount) : undefined,
      mpin: mpin || '1234',
    });
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ success: false, message: err.message });
  }
});

apiRouter.post('/sip/:id/redeem', authMiddleware, (req: AuthenticatedRequest, res) => {
  try {
    const { mpin } = req.body;
    const result = SipService.redeemSipToBank({
      userId: req.userId!,
      sipId: req.params.id as string,
      mpin: mpin || '1234',
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
// 13. LIVE GATEWAY & SMS API KEY CONFIGURATION
// ==========================================
apiRouter.get('/config/gateway', (req, res) => {
  return res.json({ success: true, gateway: SmsService.getGatewayStatus() });
});

apiRouter.post('/config/gateway', (req, res) => {
  SmsService.updateGatewayConfig(req.body || {});
  return res.json({
    success: true,
    message: 'Live Gateway & SMS credentials updated.',
    gateway: SmsService.getGatewayStatus(),
  });
});
