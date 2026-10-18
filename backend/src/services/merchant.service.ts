import { v4 as uuidv4 } from 'uuid';
import QRCode from 'qrcode';
import { db } from '../db/database.js';
import type { Merchant, PayLink } from '../types/index.js';

export class MerchantService {
  public static async generateUpiQr(params: {
    vpa: string;
    payeeName: string;
    amount?: number;
    transactionNote?: string;
  }): Promise<{ upiUri: string; qrCodeDataUrl: string }> {
    const { vpa, payeeName, amount, transactionNote = 'Payment via AikSetra' } = params;

    let upiUri = `upi://pay?pa=${encodeURIComponent(vpa)}&pn=${encodeURIComponent(payeeName)}&cu=INR&tn=${encodeURIComponent(transactionNote)}`;
    if (amount && amount > 0) {
      upiUri += `&am=${amount.toFixed(2)}`;
    }

    const qrCodeDataUrl = await QRCode.toDataURL(upiUri, {
      errorCorrectionLevel: 'H',
      margin: 2,
      width: 400,
      color: {
        dark: '#0f172a',
        light: '#ffffff',
      },
    });

    return { upiUri, qrCodeDataUrl };
  }

  public static async createPayLink(params: {
    merchantId: string;
    amount: number;
    description: string;
  }): Promise<PayLink> {
    const merchants = db.get('merchants');
    const merchant = merchants.find((m) => m.id === params.merchantId);
    if (!merchant) {
      throw new Error('Merchant not found.');
    }

    const linkId = `plink_${uuidv4().replace(/-/g, '').slice(0, 10)}`;
    const linkUrl = `http://localhost:4000/pay/${linkId}`;
    const qrInfo = await this.generateUpiQr({
      vpa: merchant.merchantVpa,
      payeeName: merchant.businessName,
      amount: params.amount,
      transactionNote: params.description,
    });

    const payLink: PayLink = {
      id: linkId,
      merchantId: merchant.id,
      merchantName: merchant.businessName,
      amount: params.amount,
      description: params.description,
      linkUrl,
      upiIntentUrl: qrInfo.upiUri,
      qrCodeDataUrl: qrInfo.qrCodeDataUrl,
      status: 'ACTIVE',
      createdAt: new Date().toISOString(),
    };

    db.insert('payLinks', payLink);
    return payLink;
  }

  public static getPayLink(linkId: string): PayLink | null {
    const links = db.get('payLinks');
    return links.find((l) => l.id === linkId) || null;
  }

  public static getMerchantDashboard(merchantId: string) {
    const merchants = db.get('merchants');
    const merchant = merchants.find((m) => m.id === merchantId);
    if (!merchant) throw new Error('Merchant not found.');

    const txns = db.get('transactions').filter(
      (t) => t.receiverVpa.toLowerCase() === merchant.merchantVpa.toLowerCase() && t.status === 'SUCCESS'
    );

    const totalCollected = txns.reduce((sum, t) => sum + t.amount, 0);
    const today = new Date().toISOString().slice(0, 10);
    const todayTxns = txns.filter((t) => t.createdAt.startsWith(today));
    const todayVolume = todayTxns.reduce((sum, t) => sum + t.amount, 0);

    const payLinks = db.get('payLinks').filter((l) => l.merchantId === merchantId);

    return {
      merchant,
      metrics: {
        totalCollected,
        allTimeTransactions: txns.length,
        todayVolume,
        todayTransactions: todayTxns.length,
        activePayLinksCount: payLinks.filter((l) => l.status === 'ACTIVE').length,
      },
      recentTransactions: txns.slice(-10).reverse(),
      payLinks: payLinks.slice(-10).reverse(),
    };
  }
}
