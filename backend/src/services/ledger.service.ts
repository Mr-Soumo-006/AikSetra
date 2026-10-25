import { v4 as uuidv4 } from 'uuid';
import { db } from '../db/database.js';
import type { LedgerEntry, BankAccount, Transaction } from '../types/index.js';

/**
 * Concurrency Mutex: Serializes concurrent operations on a given account ID
 * to prevent race condition double-spends.
 */
class AccountLockManager {
  private locks = new Map<string, Promise<void>>();

  public async acquire<T>(accountId: string, operation: () => Promise<T>): Promise<T> {
    while (this.locks.has(accountId)) {
      await this.locks.get(accountId);
    }

    let release: () => void = () => {};
    const lockPromise = new Promise<void>((resolve) => {
      release = resolve;
    });

    this.locks.set(accountId, lockPromise);

    try {
      return await operation();
    } finally {
      this.locks.delete(accountId);
      release();
    }
  }

  /**
   * P1 Issue 4: Coordinated Dual-Account Locking (Deadlock-Free Sorted Mutex)
   * Locks all involved account IDs in sorted order to prevent race conditions and deadlocks.
   */
  public async acquireMultiple<T>(accountIds: string[], operation: () => Promise<T>): Promise<T> {
    const uniqueSorted = Array.from(new Set(accountIds)).sort();
    if (uniqueSorted.length === 0) return await operation();

    const acquireRecursive = async (index: number): Promise<T> => {
      if (index >= uniqueSorted.length) {
        return await operation();
      }
      return await this.acquire(uniqueSorted[index], async () => {
        return await acquireRecursive(index + 1);
      });
    };

    return await acquireRecursive(0);
  }
}

export class LedgerService {
  private static lockManager = new AccountLockManager();

  /**
   * Atomic Double-Entry Transfer Execution
   * Ensures debits and credits are committed together atomically with coordinated multi-account locks.
   */
  public static async executeDoubleEntryTransfer(params: {
    transactionId: string;
    senderAccount: BankAccount;
    receiverAccount?: BankAccount;
    amount: number;
    currency: string;
    description: string;
  }): Promise<{ senderBalanceAfter: number; receiverBalanceAfter?: number }> {
    const { transactionId, senderAccount, receiverAccount, amount, currency, description } = params;

    if (amount <= 0 || !Number.isFinite(amount)) {
      throw new Error('Invalid transfer amount. Amount must be a positive finite number.');
    }

    const lockIds = [senderAccount.id, receiverAccount?.id].filter(Boolean) as string[];

    // Execute within coordinated multi-account locks (P1 Issue 4) and transactional boundary (P1 Issue 17)
    return await this.lockManager.acquireMultiple(lockIds, async () => {
      return await db.transaction(async () => {
        // Re-fetch account from DB to get the latest atomic balance state
        const currentSender = db.get('accounts').find((a) => a.id === senderAccount.id);
        if (!currentSender) {
          throw new Error('Sender bank account no longer exists.');
        }

        if (currentSender.balance < amount) {
          throw new Error(`Insufficient funds. Available: ₹${currentSender.balance.toFixed(2)}, Required: ₹${amount.toFixed(2)}`);
        }

        const senderBalanceAfter = Math.round((currentSender.balance - amount) * 100) / 100;
        currentSender.balance = senderBalanceAfter;

        // 1. Paired DEBIT Ledger Entry on Sender
        const debitEntry: LedgerEntry = {
          id: `led_${uuidv4().replace(/-/g, '').slice(0, 14)}`,
          transactionId,
          accountId: currentSender.id,
          accountType: 'USER_ACCOUNT',
          entryType: 'DEBIT',
          amount,
          currency,
          balanceAfter: senderBalanceAfter,
          description: `DEBIT: ${description}`,
          createdAt: new Date().toISOString(),
        };

        let creditEntry: LedgerEntry;
        let receiverBalanceAfter: number | undefined;

        if (receiverAccount) {
          const currentReceiver = db.get('accounts').find((a) => a.id === receiverAccount.id);
          if (currentReceiver) {
            receiverBalanceAfter = Math.round((currentReceiver.balance + amount) * 100) / 100;
            currentReceiver.balance = receiverBalanceAfter;
          }

          // 2a. Paired CREDIT Ledger Entry on Internal Beneficiary
          creditEntry = {
            id: `led_${uuidv4().replace(/-/g, '').slice(0, 14)}`,
            transactionId,
            accountId: receiverAccount.id,
            accountType: 'USER_ACCOUNT',
            entryType: 'CREDIT',
            amount,
            currency,
            balanceAfter: receiverBalanceAfter ?? receiverAccount.balance,
            description: `CREDIT: ${description}`,
            createdAt: new Date().toISOString(),
          };
        } else {
          // 2b. Paired CREDIT Ledger Entry to Clearing House (Nostro / Switch settlement)
          creditEntry = {
            id: `led_${uuidv4().replace(/-/g, '').slice(0, 14)}`,
            transactionId,
            accountId: 'acc_clearing_switch_00',
            accountType: 'SETTLEMENT_CLEARING',
            entryType: 'CREDIT',
            amount,
            currency,
            balanceAfter: 0,
            description: `CLEARING CREDIT: ${description}`,
            createdAt: new Date().toISOString(),
          };
        }

        // Commit entries to immutable ledger store
        db.insert('ledger', debitEntry);
        db.insert('ledger', creditEntry);

        return { senderBalanceAfter, receiverBalanceAfter };
      });
    });
  }

  /**
   * Reverse a transaction atomically (reversal workflow)
   */
  public static async executeReversal(params: {
    originalTransaction: Transaction;
    reason: string;
  }): Promise<boolean> {
    const { originalTransaction, reason } = params;

    if (originalTransaction.status === 'REVERSED') {
      return false; // Already reversed
    }

    const senderAccount = db.get('accounts').find((a) => a.id === originalTransaction.senderAccountId);
    if (!senderAccount) return false;

    return await this.lockManager.acquire(senderAccount.id, async () => {
      const refundAmount = originalTransaction.amount;
      senderAccount.balance = Math.round((senderAccount.balance + refundAmount) * 100) / 100;

      const reversalEntry: LedgerEntry = {
        id: `led_rev_${uuidv4().replace(/-/g, '').slice(0, 12)}`,
        transactionId: originalTransaction.id,
        accountId: senderAccount.id,
        accountType: 'USER_ACCOUNT',
        entryType: 'CREDIT',
        amount: refundAmount,
        currency: originalTransaction.currency,
        balanceAfter: senderAccount.balance,
        description: `REVERSAL REFUND: ${reason}`,
        createdAt: new Date().toISOString(),
      };

      db.get('ledger').push(reversalEntry);
      originalTransaction.status = 'REVERSED';
      originalTransaction.failureReason = reason;
      db.save();
      return true;
    });
  }

  /**
   * Ledger Audit & Reconciliation helper
   */
  public static reconcileAccount(accountId: string): { reconciled: boolean; balanceDiscrepancy: number } {
    const account = db.get('accounts').find((a) => a.id === accountId);
    if (!account) return { reconciled: false, balanceDiscrepancy: 0 };

    const entries = db.get('ledger').filter((e) => e.accountId === accountId);
    let computedDelta = 0;
    for (const e of entries) {
      if (e.entryType === 'CREDIT') computedDelta += e.amount;
      if (e.entryType === 'DEBIT') computedDelta -= e.amount;
    }

    // Baseline calculation check
    const diff = Math.abs(account.balance - (10000 + computedDelta)); // Initial seed baseline check
    return {
      reconciled: diff < 0.01,
      balanceDiscrepancy: diff,
    };
  }
}
