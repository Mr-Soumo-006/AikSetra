import { db } from '../db/database.js';
import type { BusinessProfile, BusinessInvoice, InvoiceItem } from '../types/index.js';

export class BusinessService {
  public static getBusinessProfile(userId: string): {
    profile: BusinessProfile;
    todayStats: { volume: number; txnCount: number; avgTicket: number };
    monthlyStats: { volume: number; txnCount: number; mdrFees: number; netSettled: number };
    staff: Array<{ id: string; name: string; role: string; phone: string }>;
  } {
    let profiles = db.get('businessProfiles') || [];
    let profile = profiles.find((p) => p.userId === userId);

    if (!profile) {
      const user = db.get('users').find((u) => u.id === userId);
      const accounts = db.get('accounts').filter((a) => a.userId === userId);
      const accId = accounts.length > 0 ? accounts[0].id : 'acc_business_primary';

      profile = {
        id: `biz_${userId.replace('usr_', '')}`,
        userId,
        businessName: user ? `${user.fullName} Digital Enterprise` : 'AikSetra Business Store',
        gstin: '19AAECN1234F1Z5',
        pan: 'AAECN1234F',
        category: 'Retail & Electronics',
        merchantVpa: user?.primaryVpa ? user.primaryVpa.replace('@', '.biz@') : 'merchant.store@aiksetra',
        qrCodeUrl: `upi://pay?pa=${user?.primaryVpa || 'merchant@aiksetra'}&pn=${encodeURIComponent(user?.fullName || 'Merchant')}&mc=5411&cu=INR`,
        verified: true,
        todayVolume: 18450.0,
        todayTxnCount: 24,
        monthlyVolume: 485200.0,
        settlementAccountId: accId,
        memberSince: '2025-04-12',
      };
      db.insert('businessProfiles', profile);
    }

    const todayStats = {
      volume: 18450.0,
      txnCount: 24,
      avgTicket: Number((18450.0 / 24).toFixed(2)),
    };

    const monthlyStats = {
      volume: 485200.0,
      txnCount: 412,
      mdrFees: 0.0, // UPI is 0% MDR for merchants
      netSettled: 485200.0,
    };

    const staff = [
      { id: 'stf_01', name: 'Soumo Naskar (Owner)', role: 'OWNER', phone: '+91 9830113038' },
      { id: 'stf_02', name: 'Rahul Sen (Store Cashier)', role: 'CASHIER', phone: '+91 9830998877' },
      { id: 'stf_03', name: 'Amit Ghosh, CA', role: 'ACCOUNTANT', phone: '+91 9831223344' },
    ];

    return { profile, todayStats, monthlyStats, staff };
  }

  public static getInvoices(userId: string): BusinessInvoice[] {
    let invoices = db.get('businessInvoices').filter((inv) => inv.userId === userId);
    if (invoices.length === 0) {
      // Seed default demo invoice
      const demoInvoice: BusinessInvoice = {
        id: 'inv_demo_001',
        businessId: `biz_${userId.replace('usr_', '')}`,
        userId,
        invoiceNumber: 'INV-2026-0891',
        customerName: 'Kalyani Naskar',
        customerPhone: '+91 8910649311',
        items: [
          { name: 'Samsung 65" Crystal 4K Smart TV', qty: 1, unitPrice: 42000, gstRate: 18 },
          { name: 'Wall Mount & High Speed HDMI Cable', qty: 1, unitPrice: 1500, gstRate: 18 },
        ],
        subtotal: 43500.0,
        gstTotal: 7830.0,
        grandTotal: 51330.0,
        status: 'PAID',
        dueDate: '2026-10-25',
        createdAt: new Date(Date.now() - 24 * 3600000).toISOString(),
        paidAt: new Date(Date.now() - 20 * 3600000).toISOString(),
      };
      db.insert('businessInvoices', demoInvoice);
      invoices = [demoInvoice];
    }
    return invoices;
  }

  public static createInvoice(params: {
    userId: string;
    customerName: string;
    customerPhone: string;
    items: InvoiceItem[];
    dueDate?: string;
  }): BusinessInvoice {
    const { userId, customerName, customerPhone, items, dueDate } = params;

    let subtotal = 0;
    let gstTotal = 0;

    for (const item of items) {
      const lineCost = item.qty * item.unitPrice;
      const lineGst = (lineCost * item.gstRate) / 100;
      subtotal += lineCost;
      gstTotal += lineGst;
    }

    const grandTotal = Number((subtotal + gstTotal).toFixed(2));
    const invNumber = `INV-${new Date().getFullYear()}-${Math.floor(1000 + Math.random() * 9000)}`;

    const invoice: BusinessInvoice = {
      id: `inv_${Date.now().toString(36)}`,
      businessId: `biz_${userId.replace('usr_', '')}`,
      userId,
      invoiceNumber: invNumber,
      customerName,
      customerPhone,
      items,
      subtotal: Number(subtotal.toFixed(2)),
      gstTotal: Number(gstTotal.toFixed(2)),
      grandTotal,
      status: 'UNPAID',
      dueDate: dueDate || new Date(Date.now() + 7 * 86400000).toISOString().split('T')[0],
      createdAt: new Date().toISOString(),
    };

    db.insert('businessInvoices', invoice);
    return invoice;
  }
}
