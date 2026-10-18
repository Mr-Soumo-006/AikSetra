import { v4 as uuidv4 } from 'uuid';
import { db } from '../db/database.js';
import type { DisputeTicket } from '../types/index.js';

export class DisputeService {
  public static createDispute(params: {
    userId: string;
    txnId: string;
    upiRrn: string;
    amount: number;
    category: DisputeTicket['category'];
    description: string;
  }): DisputeTicket {
    const ticket: DisputeTicket = {
      id: `dsp_${uuidv4().replace(/-/g, '').slice(0, 10)}`,
      txnId: params.txnId,
      upiRrn: params.upiRrn,
      userId: params.userId,
      amount: params.amount,
      category: params.category,
      status: 'LOGGED',
      description: params.description,
      slaResolveBy: new Date(Date.now() + 24 * 3600000).toISOString(), // T+1 day NPCI SLA
      bankRefNumber: `NPCI-CRM-${Date.now().toString().slice(-6)}`,
      createdAt: new Date().toISOString(),
    };

    db.insert('disputes', ticket);
    return ticket;
  }

  public static getDisputesForUser(userId: string): DisputeTicket[] {
    return db.get('disputes').filter((d) => d.userId === userId);
  }

  public static resolveDispute(disputeId: string, resolution: 'REFUNDED' | 'REJECTED'): DisputeTicket {
    const disputes = db.get('disputes');
    const dispute = disputes.find((d) => d.id === disputeId);
    if (!dispute) throw new Error('Dispute ticket not found.');

    dispute.status = resolution;
    dispute.resolvedAt = new Date().toISOString();
    db.save();
    return dispute;
  }
}
