import { v4 as uuidv4 } from 'uuid';
import { db } from '../db/database.js';
import type { SplitBill, SplitParticipant, CollectRequest } from '../types/index.js';

export class SplitService {
  public static createSplitBill(params: {
    createdByUserId: string;
    title: string;
    totalAmount: number;
    participants: Array<{ name: string; vpa: string; shareAmount?: number }>;
  }): SplitBill {
    const creatorUser = db.get('users').find((u) => u.id === params.createdByUserId);
    const creatorVpa = creatorUser?.primaryVpa || 'user@aiksetra';

    const count = params.participants.length;
    if (count === 0) throw new Error('At least one participant required.');

    const defaultShare = Number((params.totalAmount / count).toFixed(2));

    const finalParticipants: SplitParticipant[] = params.participants.map((p) => {
      const share = p.shareAmount || defaultShare;
      const partId = `sp_${uuidv4().slice(0, 8)}`;
      let collectId: string | undefined;

      // Create UPI collect request if it's not the creator themselves
      if (p.vpa.toLowerCase() !== creatorVpa.toLowerCase()) {
        collectId = `col_${uuidv4().slice(0, 8)}`;
        const collectReq: CollectRequest = {
          id: collectId,
          payerVpa: p.vpa,
          payeeVpa: creatorVpa,
          payeeName: creatorUser?.fullName || 'AikSetra Member',
          amount: share,
          remark: `Split share for: ${params.title}`,
          expiryMinutes: 1440, // 24 hours
          status: 'PENDING',
          createdAt: new Date().toISOString(),
          expiresAt: new Date(Date.now() + 24 * 3600000).toISOString(),
        };
        db.insert('collectRequests', collectReq);
      }

      return {
        id: partId,
        name: p.name,
        vpa: p.vpa,
        shareAmount: share,
        status: p.vpa.toLowerCase() === creatorVpa.toLowerCase() ? 'PAID' : 'PENDING',
        collectRequestId: collectId,
        paidAt: p.vpa.toLowerCase() === creatorVpa.toLowerCase() ? new Date().toISOString() : undefined,
      };
    });

    const splitBill: SplitBill = {
      id: `splt_${uuidv4().replace(/-/g, '').slice(0, 10)}`,
      title: params.title,
      totalAmount: params.totalAmount,
      createdByUserId: params.createdByUserId,
      participants: finalParticipants,
      status: 'OPEN',
      createdAt: new Date().toISOString(),
    };

    db.insert('splitBills', splitBill);
    return splitBill;
  }

  public static markParticipantPaid(splitBillId: string, participantId: string): SplitBill {
    const bills = db.get('splitBills');
    const bill = bills.find((b) => b.id === splitBillId);
    if (!bill) throw new Error('Split bill not found.');

    const participant = bill.participants.find((p) => p.id === participantId);
    if (!participant) throw new Error('Participant not found.');

    participant.status = 'PAID';
    participant.paidAt = new Date().toISOString();

    const allPaid = bill.participants.every((p) => p.status === 'PAID');
    if (allPaid) {
      bill.status = 'SETTLED';
    }

    db.save();
    return bill;
  }

  public static getSplitsForUser(userId: string): SplitBill[] {
    return db.get('splitBills').filter((b) => b.createdByUserId === userId);
  }
}
