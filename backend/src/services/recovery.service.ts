import { db } from '../db/database.js';
import { LedgerService } from './ledger.service.js';
import { AuditService } from './audit.service.js';

export class RecoveryService {
  /**
   * Scans for dangling/orphaned PENDING transactions older than timeoutMs (default 5 mins)
   * and marks them as TIMED_OUT / FAILED, executing compensating refunds if required.
   */
  public static async recoverPendingTransactions(timeoutMs: number = 5 * 60 * 1000): Promise<{
    recoveredCount: number;
    transactionIds: string[];
  }> {
    const now = Date.now();
    const transactions = db.get('transactions');
    const pending = transactions.filter(
      (t) =>
        (t.status === 'PENDING' || t.status === 'PENDING_PARTNER_SETTLEMENT') &&
        now - new Date(t.createdAt).getTime() > timeoutMs
    );

    const recoveredIds: string[] = [];

    for (const txn of pending) {
      try {
        await db.transaction(async () => {
          if (txn.status === 'PENDING_PARTNER_SETTLEMENT') {
            // Outward remittance timed out without partner confirmation: release escrow hold back to user
            const senderAccount = db.get('accounts').find((a) => a.id === txn.senderAccountId);
            if (senderAccount) {
              senderAccount.balance = Math.round((senderAccount.balance + txn.amount) * 100) / 100;
              db.insert('ledger', {
                id: `led_recov_${Date.now()}_${txn.id.slice(-6)}`,
                transactionId: txn.id,
                accountId: senderAccount.id,
                accountType: 'USER_ACCOUNT',
                entryType: 'CREDIT',
                amount: txn.amount,
                currency: txn.currency,
                balanceAfter: senderAccount.balance,
                description: `RECOVERY REFUND: Remittance timed out without bank partner settlement`,
                createdAt: new Date().toISOString(),
              });
            }
          }

          txn.status = 'FAILED';
          txn.failureReason = 'Transaction timed out without payment rail confirmation (Crash-Safe Auto Recovery)';
          txn.completedAt = new Date().toISOString();

          AuditService.log({
            actorId: 'SYSTEM_RECOVERY_WORKER',
            action: 'TRANSACTION_AUTO_RECOVERED',
            resource: 'TRANSACTION',
            resourceId: txn.id,
            metadata: { timeoutMs, previousStatus: txn.status },
          });

          recoveredIds.push(txn.id);
        });
      } catch (err) {
        console.error(`Failed to recover orphaned transaction ${txn.id}:`, err);
      }
    }

    return {
      recoveredCount: recoveredIds.length,
      transactionIds: recoveredIds,
    };
  }
}
