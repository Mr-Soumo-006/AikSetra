import { db } from '../db/database.js';
import type { RewardEntry, RewardCoupon } from '../types/index.js';

export class RewardsService {
  public static getRewardsOverview(userId: string) {
    let rewards = db.get('rewards').filter((r) => r.userId === userId);
    let coupons = db.get('rewardCoupons') || [];

    // Seed default reward history and coupons if empty
    if (rewards.length === 0) {
      const seedEntries: RewardEntry[] = [
        {
          id: 'rew_welcome',
          userId,
          type: 'CASHBACK',
          points: 250,
          amountInr: 25.0,
          description: 'Welcome Bonus on UPI Registration',
          status: 'CREDITED',
          createdAt: new Date(Date.now() - 30 * 86400000).toISOString(),
        },
        {
          id: 'rew_qr_payment',
          userId,
          type: 'CASHBACK',
          points: 150,
          amountInr: 15.0,
          description: 'Cashback on First Merchant BharatQR Scan',
          status: 'CREDITED',
          createdAt: new Date(Date.now() - 15 * 86400000).toISOString(),
        },
        {
          id: 'rew_referral_1',
          userId,
          type: 'REFERRAL',
          points: 500,
          amountInr: 51.0,
          description: 'Referral Reward: Kalyani completed 1st UPI Payment',
          status: 'CREDITED',
          createdAt: new Date(Date.now() - 7 * 86400000).toISOString(),
        },
        {
          id: 'rew_bill_pay',
          userId,
          type: 'CASHBACK',
          points: 300,
          amountInr: 30.0,
          description: 'Utility Bill Payment Reward (CESC Electricity)',
          status: 'CREDITED',
          createdAt: new Date(Date.now() - 2 * 86400000).toISOString(),
        },
      ];

      for (const r of seedEntries) {
        db.insert('rewards', r);
      }
      rewards = db.get('rewards').filter((r) => r.userId === userId);
    }

    if (coupons.length === 0) {
      const seedCoupons: RewardCoupon[] = [
        {
          id: 'coup_swiggy_50',
          brand: 'Swiggy Gourmet',
          title: 'Flat ₹50 OFF on Food Orders',
          code: 'AIKSWIGGY50',
          category: 'Food & Dining',
          discount: '₹50 OFF',
          minSpend: 249,
          expiresAt: '2026-11-30',
          isClaimed: false,
        },
        {
          id: 'coup_myntra_200',
          brand: 'Myntra Fashion',
          title: 'Extra 15% OFF (Up to ₹200)',
          code: 'AIKMYNTRA15',
          category: 'Shopping',
          discount: '15% OFF',
          minSpend: 999,
          expiresAt: '2026-12-15',
          isClaimed: false,
        },
        {
          id: 'coup_makemytrip',
          brand: 'MakeMyTrip Flights',
          title: '₹600 Instant Discount on Domestic Flights',
          code: 'AIKMMT600',
          category: 'Travel',
          discount: '₹600 OFF',
          minSpend: 3500,
          expiresAt: '2026-12-31',
          isClaimed: false,
        },
        {
          id: 'coup_zomato_pro',
          brand: 'Zomato Pro',
          title: 'Flat 20% OFF on Dine-Out Bills',
          code: 'AIKZOMATO20',
          category: 'Food & Dining',
          discount: '20% OFF',
          minSpend: 500,
          expiresAt: '2026-11-25',
          isClaimed: true,
        },
      ];

      for (const c of seedCoupons) {
        db.insert('rewardCoupons', c);
      }
      coupons = db.get('rewardCoupons');
    }

    const totalCoins = rewards.reduce((sum, r) => sum + (r.status === 'CREDITED' ? r.points : -r.points), 0);
    const totalCashbackInr = rewards
      .filter((r) => r.type === 'CASHBACK' || r.type === 'REFERRAL')
      .reduce((sum, r) => sum + r.amountInr, 0);

    const user = db.get('users').find((u) => u.id === userId);
    const referralCode = `AIK${user?.phone ? user.phone.slice(-6) : 'SETRA'}26`;

    return {
      coinsBalance: Math.max(0, totalCoins),
      totalCashbackInr: Number(totalCashbackInr.toFixed(2)),
      referralCode,
      referralCount: 3,
      referralEarningsInr: 153.0,
      rewardsHistory: rewards,
      coupons,
    };
  }

  public static claimCoupon(couponId: string): { success: boolean; coupon: RewardCoupon } {
    const coupons = db.get('rewardCoupons');
    const c = coupons.find((item) => item.id === couponId);
    if (!c) throw new Error('Coupon not found.');
    c.isClaimed = true;
    db.update('rewardCoupons', (item) => item.id === couponId, { isClaimed: true });
    return { success: true, coupon: c };
  }
}
