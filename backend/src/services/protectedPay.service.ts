import { v4 as uuidv4 } from 'uuid';
import { db } from '../db/database.js';
import { config } from '../config/index.js';
import type { ProtectedPayEscrow } from '../types/index.js';

export class ProtectedPayService {
  public static createEscrow(params: {
    buyerUserId: string;
    buyerVpa: string;
    sellerVpa: string;
    sellerName: string;
    amount: number;
    itemDescription: string;
    autoReleaseDays?: number;
  }): ProtectedPayEscrow {
    const days = params.autoReleaseDays || config.escrowAutoReleaseDays;
    const expiresAt = new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString();

    const escrow: ProtectedPayEscrow = {
      id: `esc_${uuidv4().replace(/-/g, '').slice(0, 12)}`,
      buyerUserId: params.buyerUserId,
      buyerVpa: params.buyerVpa,
      sellerVpa: params.sellerVpa,
      sellerName: params.sellerName,
      amount: params.amount,
      itemDescription: params.itemDescription,
      status: 'HELD_IN_ESCROW',
      autoReleaseDays: days,
      expiresAt,
      createdAt: new Date().toISOString(),
    };

    db.insert('protectedEscrows', escrow);
    return escrow;
  }

  public static confirmDelivery(escrowId: string, buyerUserId: string): ProtectedPayEscrow {
    const escrows = db.get('protectedEscrows');
    const escrow = escrows.find((e) => e.id === escrowId);

    if (!escrow) {
      throw new Error('Escrow transaction not found.');
    }
    if (escrow.buyerUserId !== buyerUserId) {
      throw new Error('Unauthorized: Only the buyer can confirm item delivery.');
    }
    if (escrow.status !== 'HELD_IN_ESCROW') {
      throw new Error(`Cannot release escrow in status: ${escrow.status}`);
    }

    escrow.status = 'RELEASED_TO_SELLER';
    escrow.releasedAt = new Date().toISOString();
    escrow.resolvedAt = new Date().toISOString();
    db.save();

    return escrow;
  }

  public static raiseDispute(params: {
    escrowId: string;
    buyerUserId: string;
    disputeReason: string;
    disputeEvidenceUrl?: string;
  }): ProtectedPayEscrow {
    const { escrowId, buyerUserId, disputeReason, disputeEvidenceUrl } = params;
    const escrows = db.get('protectedEscrows');
    const escrow = escrows.find((e) => e.id === escrowId);

    if (!escrow) {
      throw new Error('Escrow transaction not found.');
    }
    if (escrow.buyerUserId !== buyerUserId) {
      throw new Error('Unauthorized: Only the buyer can raise a dispute on this transaction.');
    }
    if (escrow.status !== 'HELD_IN_ESCROW') {
      throw new Error(`Cannot dispute escrow in status: ${escrow.status}`);
    }

    escrow.status = 'DISPUTED';
    escrow.disputeReason = disputeReason;
    escrow.disputeEvidenceUrl = disputeEvidenceUrl;
    db.save();

    // Log in DisputeTracker
    db.insert('disputes', {
      id: `dsp_esc_${Date.now()}`,
      txnId: escrow.id,
      upiRrn: `ESCROW-${escrow.id.slice(4, 12)}`,
      userId: buyerUserId,
      amount: escrow.amount,
      category: 'PROTECTED_PAY_DISPUTE',
      status: 'INVESTIGATING',
      description: `Buyer dispute: ${disputeReason}`,
      slaResolveBy: new Date(Date.now() + 48 * 3600000).toISOString(),
      bankRefNumber: `ESCROW-BANK-HOLD-${Date.now()}`,
      createdAt: new Date().toISOString(),
    });

    return escrow;
  }

  public static addTracking(escrowId: string, trackingNumber: string): ProtectedPayEscrow {
    const escrows = db.get('protectedEscrows');
    const escrow = escrows.find((e) => e.id === escrowId);
    if (!escrow) {
      throw new Error('Escrow transaction not found.');
    }
    escrow.trackingNumber = trackingNumber;
    db.save();
    return escrow;
  }

  public static refundBuyer(escrowId: string): ProtectedPayEscrow {
    const escrows = db.get('protectedEscrows');
    const escrow = escrows.find((e) => e.id === escrowId);
    if (!escrow) {
      throw new Error('Escrow transaction not found.');
    }
    escrow.status = 'REFUNDED_TO_BUYER';
    escrow.resolvedAt = new Date().toISOString();
    db.save();
    return escrow;
  }

  public static decorateEscrow(e: ProtectedPayEscrow) {
    let simpleStatusText = 'Money Held Safely by Bank';
    let simpleActionHint = 'Inspect your parcel before tapping "Confirm Delivery"';
    let statusBadgeColor = 'amber';

    if (e.status === 'RELEASED_TO_SELLER') {
      simpleStatusText = 'Payment Complete • Item Received';
      simpleActionHint = 'Seller has received the funds';
      statusBadgeColor = 'green';
    } else if (e.status === 'DISPUTED') {
      simpleStatusText = 'Dispute Raised • Money Frozen Safely';
      simpleActionHint = 'Our support team is reviewing your complaint';
      statusBadgeColor = 'red';
    } else if (e.status === 'REFUNDED_TO_BUYER') {
      simpleStatusText = 'Refunded to your Bank Account';
      simpleActionHint = 'Amount credited back to your account';
      statusBadgeColor = 'blue';
    }

    return {
      ...e,
      simpleStatusText,
      simpleActionHint,
      statusBadgeColor,
    };
  }

  public static getEscrowsForUser(userId: string) {
    const all = db.get('protectedEscrows');
    return all.filter((e) => e.buyerUserId === userId).map(this.decorateEscrow);
  }
}
