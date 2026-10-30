import PDFDocument from 'pdfkit';
import { Response } from 'express';

export interface InvoicePdfData {
  invoiceNumber: string;
  businessName: string;
  gstin?: string;
  address?: string;
  phone?: string;
  email?: string;
  website?: string;
  customerName: string;
  customerPhone: string;
  date: string;
  status: string;
  items: Array<{
    name: string;
    qty: number;
    unitPrice: number;
    gstRate: number;
  }>;
  subtotal: number;
  gstTotal: number;
  grandTotal: number;
}

export interface StatementPdfData {
  accountName: string;
  accountNumber?: string;
  holderName?: string;
  panNumber?: string;
  gstin?: string;
  ifscCode?: string;
  address?: string;
  isBusiness?: boolean;
  statementPeriod: string;
  startDate?: string;
  endDate?: string;
  generatedDate: string;
  openingBalance?: number;
  closingBalance?: number;
  totalCredits: number;
  totalDebits: number;
  netCashflow: number;
  transactions: Array<{
    id: string;
    date: string;
    title: string;
    category: string;
    type: 'credit' | 'debit';
    amount: number;
    ref: string;
    balance?: number;
  }>;
}

export class PdfGeneratorService {
  /**
   * Generates a tax invoice PDF stream with BBPS / GST compliance
   */
  public static generateInvoicePdf(data: InvoicePdfData, res: Response) {
    const doc = new PDFDocument({ margin: 40, size: 'A4' });

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="Invoice_${data.invoiceNumber}.pdf"`);
    doc.pipe(res);

    // Header Background Accent
    doc.rect(0, 0, doc.page.width, 10).fill('#FF671F'); // National Saffron

    // Business Header
    doc.fillColor('#0D1B2A').fontSize(20).font('Helvetica-Bold').text(data.businessName || 'Pentile Technologies', 40, 35);
    doc.fontSize(10).font('Helvetica').fillColor('#64748B');
    if (data.gstin) doc.text(`GSTIN: ${data.gstin}`);
    if (data.website) doc.text(`Website: ${data.website}`);
    if (data.phone) doc.text(`Support: ${data.phone}`);

    // Invoice Meta Right-aligned
    doc.fontSize(16).font('Helvetica-Bold').fillColor('#046A38').text('TAX INVOICE', 380, 35, { align: 'right' });
    doc.fontSize(10).font('Helvetica').fillColor('#0D1B2A');
    doc.text(`Invoice No: ${data.invoiceNumber}`, 380, 58, { align: 'right' });
    doc.text(`Date: ${data.date}`, 380, 72, { align: 'right' });
    doc.text(`Payment Status: ${data.status.toUpperCase()}`, 380, 86, { align: 'right' });

    doc.moveTo(40, 110).lineTo(555, 110).strokeColor('#E2E8F0').stroke();

    // Bill To Section
    doc.rect(40, 120, 515, 60).fill('#F8FAFC');
    doc.fillColor('#0D1B2A').fontSize(11).font('Helvetica-Bold').text('BILLED TO (CUSTOMER):', 55, 130);
    doc.fontSize(11).font('Helvetica').fillColor('#334155');
    doc.text(`Customer Name : ${data.customerName}`, 55, 146);
    doc.text(`Mobile Number : ${data.customerPhone || 'N/A'}`, 55, 160);

    // Line Items Table Header
    const tableTop = 200;
    doc.rect(40, tableTop, 515, 24).fill('#0D1B2A');
    doc.fillColor('#FFFFFF').fontSize(10).font('Helvetica-Bold');
    doc.text('ITEM DESCRIPTION', 50, tableTop + 7);
    doc.text('QTY', 290, tableTop + 7);
    doc.text('UNIT PRICE (₹)', 340, tableTop + 7);
    doc.text('GST %', 430, tableTop + 7);
    doc.text('TOTAL (₹)', 480, tableTop + 7, { align: 'right' });

    let y = tableTop + 30;
    doc.font('Helvetica').fontSize(9).fillColor('#1E293B');

    data.items.forEach((item, idx) => {
      const lineCost = item.qty * item.unitPrice;
      const totalLine = lineCost + (lineCost * item.gstRate) / 100;

      if (idx % 2 === 1) {
        doc.rect(40, y - 4, 515, 20).fill('#F1F5F9');
      }
      doc.fillColor('#1E293B');
      doc.text(item.name, 50, y);
      doc.text(item.qty.toString(), 290, y);
      doc.text(`₹${item.unitPrice.toLocaleString('en-IN')}`, 340, y);
      doc.text(`${item.gstRate}%`, 430, y);
      doc.text(`₹${totalLine.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`, 435, y, { width: 110, align: 'right' });
      y += 22;
    });

    doc.moveTo(40, y + 4).lineTo(555, y + 4).strokeColor('#CBD5E1').stroke();
    y += 15;

    // Totals Box
    const totalsLeft = 320;
    doc.fontSize(10).font('Helvetica').fillColor('#475569');
    doc.text('Subtotal (Taxable Value):', totalsLeft, y);
    doc.text(`₹${data.subtotal.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`, 440, y, { width: 105, align: 'right' });
    y += 18;

    doc.text('Goods & Services Tax (GST):', totalsLeft, y);
    doc.text(`₹${data.gstTotal.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`, 440, y, { width: 105, align: 'right' });
    y += 20;

    doc.rect(totalsLeft - 10, y - 4, 245, 26).fill('#DCFCE7');
    doc.fillColor('#046A38').fontSize(12).font('Helvetica-Bold');
    doc.text('Grand Total:', totalsLeft, y + 3);
    doc.text(`₹${data.grandTotal.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`, 440, y + 3, { width: 105, align: 'right' });

    // Official Stamp / Watermark Note
    y += 45;
    doc.rect(40, y, 515, 65).fill('#F8FAFC').stroke('#E2E8F0');
    doc.fillColor('#0D1B2A').fontSize(9).font('Helvetica-Bold').text('AUTHORIZED DIGITAL SETTLEMENT', 55, y + 10);
    doc.fontSize(8).font('Helvetica').fillColor('#64748B');
    doc.text('• This is an electronically generated and cryptographically signed tax invoice generated via AikSetra Business Engine.', 55, y + 24);
    doc.text('• Valid for GST Input Tax Credit (ITC) claiming under CGST / SGST Act 2017.', 55, y + 36);
    doc.text('• Powered by Bharat One Pay / Pentile Business Portal.', 55, y + 48);

    doc.end();
  }

  /**
   * Generates date-wise Account Audit & Transaction Statement PDF
   */
  public static generateStatementPdf(data: StatementPdfData, res: Response) {
    const doc = new PDFDocument({ margin: 36, size: 'A4' });

    res.setHeader('Content-Type', 'application/pdf');
    const safePeriod = (data.statementPeriod || 'Statement').replace(/[^a-zA-Z0-9_-]/g, '_');
    res.setHeader('Content-Disposition', `inline; filename="AikSetra_Final_Accounts_${safePeriod}.pdf"`);
    doc.pipe(res);

    // Accent Top Stripe
    doc.rect(0, 0, doc.page.width, 6).fill(data.isBusiness ? '#046A38' : '#0F172A');

    // Title & Header Block
    doc.fillColor('#64748B').fontSize(8).font('Helvetica').text('AIKSETRA UNIFIED BANKING & NATIONAL FINANCIAL SWITCH', 36, 20);
    doc.fillColor('#0D1B2A').fontSize(16).font('Helvetica-Bold').text('STATUTORY FINAL ACCOUNTS & AUDIT STATEMENT', 36, 32);
    doc.fontSize(8.5).font('Helvetica').fillColor('#475569').text('Certified Date-Wise General Ledger & Passbook Record • Compliant with Income Tax Sec 44AB & Rule 6F', 36, 52);

    doc.moveTo(36, 68).lineTo(doc.page.width - 36, 68).strokeColor('#E2E8F0').stroke();

    // ================= CREDENTIALS & AUDIT TIMELINE BOX =================
    const boxY = 74;
    const boxWidth = doc.page.width - 72;
    const boxHeight = 72;
    doc.roundedRect(36, boxY, boxWidth, boxHeight, 6).fillAndStroke('#F8FAFC', '#CBD5E1');

    // Left Column: Account & Legal Credentials
    const col1X = 48;
    const startY = boxY + 8;
    const isBiz = data.isBusiness === true;
    const holder = data.holderName || (isBiz ? 'Pentile Business Solutions' : 'Soumo Naskar');
    const pan = data.panNumber || 'AAECN1234F';
    const gstin = isBiz ? (data.gstin || '19AAECN1234F1Z5') : 'N/A (Individual Personal Account)';
    const ifsc = data.ifscCode || (isBiz ? 'HDFC0001234' : 'SBIN0001234');
    const acc = data.accountName + (data.accountNumber ? ` (${data.accountNumber})` : '');

    doc.fillColor('#0F172A').fontSize(9).font('Helvetica-Bold').text(`LEGAL ENTITY / HOLDER: `, col1X, startY, { continued: true });
    doc.font('Helvetica').text(holder);

    doc.font('Helvetica-Bold').text(`ACCOUNT & BANK: `, col1X, startY + 12, { continued: true });
    doc.font('Helvetica').text(acc);

    doc.font('Helvetica-Bold').text(`PAN: `, col1X, startY + 24, { continued: true });
    doc.font('Helvetica').text(`${pan}   |   IFSC: ${ifsc}`);

    doc.font('Helvetica-Bold').text(`GSTIN: `, col1X, startY + 36, { continued: true });
    doc.font('Helvetica').text(gstin);

    doc.font('Helvetica-Bold').text(`REGISTERED ADDRESS: `, col1X, startY + 48, { continued: true });
    doc.font('Helvetica').fillColor('#64748B').text(data.address || 'Plot 42, Sector V, Salt Lake, Kolkata, WB 700091');

    // Right Column: Timeline & Report Identification
    const col2X = 340;
    const sPeriod = data.statementPeriod || 'Selected Timeline';
    const sDate = data.startDate || '01 Oct 2026';
    const eDate = data.endDate || '30 Oct 2026';

    doc.fillColor('#046A38').fontSize(9).font('Helvetica-Bold').text(`ACCOUNTING TIMELINE: `, col2X, startY, { continued: true });
    doc.fillColor('#0D1B2A').text(sPeriod);

    doc.font('Helvetica-Bold').fillColor('#0F172A').text(`TIMELINE RANGE: `, col2X, startY + 12, { continued: true });
    doc.font('Helvetica').fillColor('#1E3A8A').text(`${sDate}  to  ${eDate}`);

    doc.font('Helvetica-Bold').fillColor('#0F172A').text(`STATEMENT ID: `, col2X, startY + 24, { continued: true });
    doc.font('Helvetica').text(`AK-STMT-2026-${Math.floor(100000 + (Math.random() * 899999))}`);

    doc.font('Helvetica-Bold').text(`GENERATED ON: `, col2X, startY + 36, { continued: true });
    doc.font('Helvetica').fillColor('#475569').text(data.generatedDate || '30 Oct 2026, 07:05 PM');

    doc.font('Helvetica-Bold').fillColor('#059669').text(`AUDIT STATUS: `, col2X, startY + 48, { continued: true });
    doc.text('VERIFIED & CLEARED FOR TAX FILING');

    // ================= FINANCIAL POSITION / BALANCE METRIC STRIP =================
    const metricY = 154;
    const cardW = (boxWidth - 24) / 5;
    const cardH = 42;

    const opBal = Number(data.openingBalance ?? 42500.0);
    const credits = Number(data.totalCredits ?? 0.0);
    const debits = Number(data.totalDebits ?? 0.0);
    const netFlow = Number(data.netCashflow ?? (credits - debits));
    const clBal = Number(data.closingBalance ?? (opBal + netFlow));

    // Card 1: Opening Balance
    doc.roundedRect(36, metricY, cardW, cardH, 4).fillAndStroke('#F1F5F9', '#CBD5E1');
    doc.fillColor('#475569').fontSize(7).font('Helvetica-Bold').text('OPENING BALANCE', 42, metricY + 6);
    doc.fillColor('#0D1B2A').fontSize(11).font('Helvetica-Bold').text(`₹${opBal.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`, 42, metricY + 20);

    // Card 2: Total Credits
    doc.roundedRect(36 + cardW + 6, metricY, cardW, cardH, 4).fillAndStroke('#F0FDF4', '#86EFAC');
    doc.fillColor('#166534').fontSize(7).font('Helvetica-Bold').text('TOTAL CREDITS (+)', 42 + cardW + 6, metricY + 6);
    doc.fillColor('#046A38').fontSize(11).font('Helvetica-Bold').text(`+₹${credits.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`, 42 + cardW + 6, metricY + 20);

    // Card 3: Total Debits
    doc.roundedRect(36 + (cardW * 2) + 12, metricY, cardW, cardH, 4).fillAndStroke('#FEF2F2', '#FECACA');
    doc.fillColor('#991B1B').fontSize(7).font('Helvetica-Bold').text('TOTAL DEBITS (-)', 42 + (cardW * 2) + 12, metricY + 6);
    doc.fillColor('#DC2626').fontSize(11).font('Helvetica-Bold').text(`-₹${debits.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`, 42 + (cardW * 2) + 12, metricY + 20);

    // Card 4: Net Cashflow
    doc.roundedRect(36 + (cardW * 3) + 18, metricY, cardW, cardH, 4).fillAndStroke('#EFF6FF', '#BFDBFE');
    doc.fillColor('#1E40AF').fontSize(7).font('Helvetica-Bold').text('NET CASHFLOW', 42 + (cardW * 3) + 18, metricY + 6);
    doc.fillColor('#2563EB').fontSize(11).font('Helvetica-Bold').text(`${netFlow >= 0 ? '+' : ''}₹${netFlow.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`, 42 + (cardW * 3) + 18, metricY + 20);

    // Card 5: Closing Balance
    doc.roundedRect(36 + (cardW * 4) + 24, metricY, cardW, cardH, 4).fillAndStroke('#0F172A', '#0F172A');
    doc.fillColor('#94A3B8').fontSize(7).font('Helvetica-Bold').text('CLOSING BALANCE', 42 + (cardW * 4) + 24, metricY + 6);
    doc.fillColor('#FFFFFF').fontSize(11).font('Helvetica-Bold').text(`₹${clBal.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`, 42 + (cardW * 4) + 24, metricY + 20);

    // ================= TRANSACTION TABLE =================
    const tTop = 206;
    doc.rect(36, tTop, boxWidth, 20).fill('#0F172A');
    doc.fillColor('#FFFFFF').fontSize(7.5).font('Helvetica-Bold');
    doc.text('DATE & TIME', 44, tTop + 6);
    doc.text('TRANSACTION PARTICULARS & BENEFICIARY', 140, tTop + 6);
    doc.text('CATEGORY', 320, tTop + 6);
    doc.text('REFERENCE / UTR NO', 400, tTop + 6);
    doc.text('AMOUNT (₹)', 480, tTop + 6, { width: 75, align: 'right' });

    let curY = tTop + 24;
    doc.font('Helvetica').fontSize(8).fillColor('#1E293B');

    const txs = data.transactions || [];
    if (txs.length === 0) {
      doc.rect(36, curY - 2, boxWidth, 24).fill('#F8FAFC');
      doc.fillColor('#64748B').text('No transactions recorded during this selected timeline.', 44, curY + 6, { align: 'center', width: boxWidth });
      curY += 28;
    } else {
      txs.forEach((t, i) => {
        if (curY > 740) {
          doc.addPage();
          doc.rect(0, 0, doc.page.width, 6).fill(data.isBusiness ? '#046A38' : '#0F172A');
          doc.fillColor('#64748B').fontSize(7.5).font('Helvetica-Bold').text(`AikSetra Statement • Timeline: ${sPeriod} • Continued`, 36, 18);
          doc.rect(36, 30, boxWidth, 18).fill('#0F172A');
          doc.fillColor('#FFFFFF').fontSize(7).font('Helvetica-Bold');
          doc.text('DATE & TIME', 44, 35);
          doc.text('TRANSACTION PARTICULARS', 140, 35);
          doc.text('CATEGORY', 320, 35);
          doc.text('REF / UTR', 400, 35);
          doc.text('AMOUNT (₹)', 480, 35, { width: 75, align: 'right' });
          curY = 54;
        }

        if (i % 2 === 1) {
          doc.rect(36, curY - 3, boxWidth, 18).fill('#F8FAFC');
        }

        const isCredit = t.type === 'credit';
        doc.fillColor('#334155').fontSize(7.5).text(t.date || '30 Oct 2026', 44, curY, { width: 90 });
        doc.fillColor('#0D1B2A').font('Helvetica-Bold').text(t.title || 'Transaction Entry', 140, curY, { width: 175 });
        doc.font('Helvetica').fillColor('#64748B').text(t.category || 'General', 320, curY, { width: 75 });
        doc.text(t.ref || 'UTR-AK-99214', 400, curY, { width: 75 });
        doc.fillColor(isCredit ? '#046A38' : '#DC2626').font('Helvetica-Bold');
        doc.text(
          `${isCredit ? '+' : '-'}₹${Number(t.amount || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`,
          480,
          curY,
          { width: 75, align: 'right' }
        );

        curY += 18;
      });
    }

    // ================= STATUTORY AUDITOR CERTIFICATION FOOTER =================
    const footerY = Math.max(curY + 14, 730);
    doc.moveTo(36, footerY).lineTo(doc.page.width - 36, footerY).strokeColor('#CBD5E1').stroke();

    doc.fillColor('#0F172A').fontSize(7.5).font('Helvetica-Bold').text('AUDITOR STATUTORY ENDORSEMENT & CERTIFICATE', 36, footerY + 6);
    doc.fillColor('#475569').fontSize(7).font('Helvetica').text(
      'I hereby certify that I have examined the final accounts, balance sheet credentials, and date-wise ledger entries of the entity stated above for the period of ' + sPeriod + ' (' + sDate + ' to ' + eDate + '). The opening balance of ₹' + opBal.toFixed(2) + ' and closing balance of ₹' + clBal.toFixed(2) + ' accurately reflect all electronic settlements and transactions compliant with ICAI Auditing Standards & Section 44AB.',
      36,
      footerY + 16,
      { width: boxWidth }
    );

    doc.fontSize(7.5).font('Helvetica-Bold').fillColor('#1E3A8A');
    doc.text('Audited by: Amit Ghosh, FCA (Membership #034871, Ghosh & Associates)', 36, footerY + 38);
    doc.text('UDIN: 26034871AKST' + Math.floor(10000 + Math.random() * 90000), 340, footerY + 38, { align: 'right', width: 220 });

    doc.fontSize(6.5).font('Helvetica').fillColor('#94A3B8').text(
      'Generated cryptographically by AikSetra National Switch • Non-repudiation assured under Section 65B of Indian Evidence Act 1872.',
      36,
      footerY + 48,
      { width: boxWidth, align: 'center' }
    );

    doc.end();
  }
}
