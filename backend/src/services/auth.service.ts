import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { db } from '../db/database.js';
import { config } from '../config/index.js';
import type { User, BankAccount } from '../types/index.js';

interface OtpSession {
  phone: string;
  otp: string;
  expiresAt: number;
}

const activeOtps: Map<string, OtpSession> = new Map();

export class AuthService {
  public static sendOtp(phone: string): { success: boolean; message: string; testOtp: string; expiresAt: string } {
    const cleanPhone = phone.replace(/[^0-9]/g, '').slice(-10);
    if (cleanPhone.length !== 10) {
      throw new Error('Please enter a valid 10-digit Indian mobile number.');
    }

    // Default test OTP is 123456 for testing, or realistic 6-digit
    const otp = cleanPhone === '9876543210' ? '123456' : Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 5 * 60 * 1000; // 5 mins

    activeOtps.set(cleanPhone, { phone: cleanPhone, otp, expiresAt });

    return {
      success: true,
      message: `SMS OTP from NPCI-AIKSETRA sent to +91 ${cleanPhone}`,
      testOtp: otp,
      expiresAt: new Date(expiresAt).toISOString(),
    };
  }

  public static verifyOtpAndLogin(params: {
    phone: string;
    otp: string;
    deviceId: string;
    simId: string;
    fullName?: string;
    selectedBank?: string;
  }): { user: User; token: string; isNewUser: boolean; account: BankAccount } {
    const { phone, otp, deviceId, simId, fullName, selectedBank = 'State Bank of India' } = params;
    const cleanPhone = phone.replace(/[^0-9]/g, '').slice(-10);

    const session = activeOtps.get(cleanPhone);
    // Allow '123456' as standard fallback test OTP for convenience
    if (otp !== '123456' && (!session || session.otp !== otp || session.expiresAt < Date.now())) {
      throw new Error('Invalid or expired OTP. Please enter 123456 or request a new OTP.');
    }

    activeOtps.delete(cleanPhone);

    const users = db.get('users');
    let user = users.find((u) => u.phone === cleanPhone);
    let isNewUser = false;

    if (!user) {
      isNewUser = true;
      const cleanHandle = (fullName || 'user')
        .toLowerCase()
        .replace(/[^a-z0-9]/g, '')
        .slice(0, 10);
      const primaryVpa = `${cleanHandle}${cleanPhone.slice(-4)}${config.defaultVpaHandle}`;

      user = {
        id: `usr_${uuidv4().replace(/-/g, '').slice(0, 12)}`,
        phone: cleanPhone,
        fullName: fullName || 'AikSetra Member',
        email: `${cleanHandle}@aiksetra.in`,
        panNumber: 'ABCDE' + Math.floor(1000 + Math.random() * 9000) + 'F',
        kycStatus: 'VERIFIED',
        deviceId,
        simId,
        mpinHash: crypto.createHash('sha256').update('123456').digest('hex'), // Default UPI MPIN: 123456
        primaryVpa,
        liteBalance: 500,
        lrsUsedUsd: 0,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      db.insert('users', user);

      // Create linked primary bank account
      const bankCode = selectedBank.includes('HDFC') ? 'HDFC' : selectedBank.includes('ICICI') ? 'ICIC' : 'SBIN';
      const ifsc = `${bankCode}0001234`;
      const account: BankAccount = {
        id: `acc_${uuidv4().replace(/-/g, '').slice(0, 10)}`,
        userId: user.id,
        bankName: selectedBank,
        bankCode,
        ifsc,
        maskedAccountNumber: `•••• •••• ${cleanPhone.slice(-4)}`,
        accountType: 'SAVINGS',
        isPrimary: true,
        balance: 50000.0,
        upiPinSet: true,
      };

      db.insert('accounts', account);

      // Register default VPA
      db.insert('vpas', {
        vpa: primaryVpa,
        userId: user.id,
        fullName: user.fullName,
        accountId: account.id,
        isPrimary: true,
        createdAt: new Date().toISOString(),
        trustScore: 85,
        fraudReportCount: 0,
        isMerchant: false,
      });

      // Initialize default Gullak
      db.insert('vaults', {
        id: `vlt_${uuidv4().slice(0, 8)}`,
        userId: user.id,
        name: 'AikSetra Savings Gullak',
        targetAmount: 25000,
        currentBalance: 2500,
        category: 'SAVINGS',
        autoRoundUp: true,
        roundUpMultiple: 10,
        createdAt: new Date().toISOString(),
      });
    } else {
      user.deviceId = deviceId;
      user.simId = simId;
      user.updatedAt = new Date().toISOString();
      db.save();
    }

    const accounts = db.get('accounts').filter((a) => a.userId === user!.id);
    const primaryAccount = accounts.find((a) => a.isPrimary) || accounts[0];

    const token = jwt.sign(
      { userId: user.id, phone: user.phone, vpa: user.primaryVpa },
      config.jwtSecret,
      { expiresIn: '30d' }
    );

    return { user, token, isNewUser, account: primaryAccount };
  }

  public static setMpin(userId: string, newMpin: string): { success: boolean } {
    if (!/^\d{4,6}$/.test(newMpin)) {
      throw new Error('UPI MPIN must be 4 or 6 numerical digits.');
    }

    const user = db.get('users').find((u) => u.id === userId);
    if (!user) throw new Error('User not found.');

    user.mpinHash = crypto.createHash('sha256').update(newMpin).digest('hex');
    user.updatedAt = new Date().toISOString();
    db.save();

    return { success: true };
  }

  public static verifyMpin(userId: string, mpin: string): boolean {
    const user = db.get('users').find((u) => u.id === userId);
    if (!user) return false;
    const hash = crypto.createHash('sha256').update(mpin).digest('hex');
    return user.mpinHash === hash;
  }
}
