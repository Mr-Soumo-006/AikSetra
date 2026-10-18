import { v4 as uuidv4 } from 'uuid';
import { db } from '../db/database.js';
import type { MoneyVault } from '../types/index.js';

export class VaultService {
  public static createVault(params: {
    userId: string;
    name: string;
    targetAmount: number;
    category: MoneyVault['category'];
    autoRoundUp?: boolean;
    roundUpMultiple?: number;
  }): MoneyVault {
    const vault: MoneyVault = {
      id: `vlt_${uuidv4().replace(/-/g, '').slice(0, 10)}`,
      userId: params.userId,
      name: params.name,
      targetAmount: params.targetAmount,
      currentBalance: 0,
      category: params.category,
      autoRoundUp: params.autoRoundUp || false,
      roundUpMultiple: params.roundUpMultiple || 10,
      createdAt: new Date().toISOString(),
    };

    db.insert('vaults', vault);
    return vault;
  }

  public static getVaults(userId: string): MoneyVault[] {
    return db.get('vaults').filter((v) => v.userId === userId);
  }

  public static deposit(vaultId: string, userId: string, amount: number): MoneyVault {
    const vaults = db.get('vaults');
    const vault = vaults.find((v) => v.id === vaultId && v.userId === userId);
    if (!vault) throw new Error('Vault not found.');

    vault.currentBalance += amount;
    db.save();
    return vault;
  }

  public static withdraw(vaultId: string, userId: string, amount: number): MoneyVault {
    const vaults = db.get('vaults');
    const vault = vaults.find((v) => v.id === vaultId && v.userId === userId);
    if (!vault) throw new Error('Vault not found.');
    if (vault.currentBalance < amount) throw new Error('Insufficient vault balance.');

    vault.currentBalance -= amount;
    db.save();
    return vault;
  }

  public static applyAutoRoundUp(userId: string, spentAmount: number): { roundedUpAmount: number; vaultId?: string } {
    const vaults = db.get('vaults');
    const activeVault = vaults.find((v) => v.userId === userId && v.autoRoundUp);
    if (!activeVault) return { roundedUpAmount: 0 };

    const mult = activeVault.roundUpMultiple || 10;
    const remainder = spentAmount % mult;
    if (remainder === 0) return { roundedUpAmount: 0 };

    const roundUpAmount = mult - remainder;
    activeVault.currentBalance += roundUpAmount;
    db.save();

    return { roundedUpAmount: roundUpAmount, vaultId: activeVault.id };
  }
}
