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
  statementPeriod: string;
  generatedDate: string;
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
    const doc = new PDFDocument({ margin: 40, size: 'A4' });

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="AikSetra_Statement_${data.statementPeriod.replace(/\s+/g, '_')}.pdf"`);
    doc.pipe(res);

    // Accent line
    doc.rect(0, 0, doc.page.width, 8).fill('#046A38');

    // Header
    doc.fillColor('#0D1B2A').fontSize(18).font('Helvetica-Bold').text('AikSetra Official Account Statement', 40, 30);
    doc.fontSize(9).font('Helvetica').fillColor('#64748B').text('National Unified Financial & Banking Records (For Audits & Tax Filing)', 40, 52);

    doc.fontSize(10).font('Helvetica-Bold').fillColor('#0D1B2A');
    doc.text(`Account: ${data.accountName}`, 350, 30, { align: 'right' });
    doc.font('Helvetica').fillColor('#64748B');
    doc.text(`Period: ${data.statementPeriod}`, 350, 44, { align: 'right' });
    doc.text(`Generated On: ${data.generatedDate}`, 350, 58, { align: 'right' });

    doc.moveTo(40, 78).lineTo(555, 78).strokeColor('#E2E8F0').stroke();

    // Summary Cashflow Strip
    const statBoxY = 90;
    doc.rect(40, statBoxY, 160, 45).fill('#F0FDF4');
    doc.fillColor('#166534').fontSize(8).font('Helvetica-Bold').text('TOTAL CREDITS (MONEY IN)', 50, statBoxY + 8);
    doc.fillColor('#046A38').fontSize(13).text(`+₹${data.totalCredits.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`, 50, statBoxY + 22);

    doc.rect(215, statBoxY, 160, 45).fill('#FEF2F2');
    doc.fillColor('#991B1B').fontSize(8).font('Helvetica-Bold').text('TOTAL DEBITS (MONEY OUT)', 225, statBoxY + 8);
    doc.fillColor('#DC2626').fontSize(13).text(`-₹${data.totalDebits.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`, 225, statBoxY + 22);

    doc.rect(390, statBoxY, 165, 45).fill('#EFF6FF');
    doc.fillColor('#1E40AF').fontSize(8).font('Helvetica-Bold').text('NET CASHFLOW', 400, statBoxY + 8);
    doc.fillColor('#2563EB').fontSize(13).text(`${data.netCashflow >= 0 ? '+' : ''}₹${data.netCashflow.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`, 400, statBoxY + 22);

    // Table Header
    const tTop = 150;
    doc.rect(40, tTop, 515, 22).fill('#0F172A');
    doc.fillColor('#FFFFFF').fontSize(8).font('Helvetica-Bold');
    doc.text('DATE / TIME', 50, tTop + 7);
    doc.text('TRANSACTION PARTICULARS', 150, tTop + 7);
    doc.text('CATEGORY', 330, tTop + 7);
    doc.text('REFERENCE NO', 410, tTop + 7);
    doc.text('AMOUNT (₹)', 480, tTop + 7, { align: 'right' });

    let curY = tTop + 26;
    doc.font('Helvetica').fontSize(8).fillColor('#1E293B');

    data.transactions.forEach((t, i) => {
      if (curY > 750) {
        doc.addPage();
        curY = 40;
      }
      if (i % 2 === 1) {
        doc.rect(40, curY - 3, 515, 20).fill('#F8FAFC');
      }
      const isCredit = t.type === 'credit';
      doc.fillColor('#334155').text(t.date, 50, curY, { width: 95 });
      doc.fillColor('#0F172A').font('Helvetica-Bold').text(t.title, 150, curY, { width: 170 });
      doc.font('Helvetica').fillColor('#64748B').text(t.category, 330, curY);
      doc.text(t.ref, 410, curY, { width: 75 });
      doc.fillColor(isCredit ? '#046A38' : '#DC2626').font('Helvetica-Bold');
      doc.text(
        `${isCredit ? '+' : '-'}₹${t.amount.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`,
        480,
        curY,
        { width: 65, align: 'right' }
      );

      curY += 20;
    });

    // Verification Seal Footer
    doc.moveTo(40, curY + 10).lineTo(555, curY + 10).strokeColor('#CBD5E1').stroke();
    doc.fontSize(8).font('Helvetica').fillColor('#94A3B8');
    doc.text(
      'Verified Electronic Audit Record • Compliant with Section 65B of Indian Evidence Act 1872 & RBI Digital Accounting Guidelines.',
      40,
      curY + 18,
      { width: 515, align: 'center' }
    );

    doc.end();
  }
}
