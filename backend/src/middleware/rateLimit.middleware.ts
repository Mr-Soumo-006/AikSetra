import { Request, Response, NextFunction } from 'express';
import { config } from '../config/index.js';

export interface RateLimitStore {
  increment(key: string, windowMs: number): Promise<{ count: number; oldestTimestamp: number }>;
}

class InMemoryRateLimitStore implements RateLimitStore {
  private store = new Map<string, { timestamps: number[] }>();

  constructor() {
    setInterval(() => {
      const now = Date.now();
      for (const [key, record] of this.store.entries()) {
        record.timestamps = record.timestamps.filter((ts) => now - ts < 15 * 60 * 1000);
        if (record.timestamps.length === 0) {
          this.store.delete(key);
        }
      }
    }, 5 * 60 * 1000).unref();
  }

  public async increment(key: string, windowMs: number): Promise<{ count: number; oldestTimestamp: number }> {
    const now = Date.now();
    let record = this.store.get(key);
    if (!record) {
      record = { timestamps: [] };
      this.store.set(key, record);
    }
    record.timestamps = record.timestamps.filter((ts) => now - ts < windowMs);
    record.timestamps.push(now);
    return {
      count: record.timestamps.length,
      oldestTimestamp: record.timestamps[0],
    };
  }
}

export const defaultSharedStore: RateLimitStore = new InMemoryRateLimitStore();

export function createRateLimiter(options: {
  windowMs: number;
  maxRequests: number;
  keyGenerator?: (req: Request) => string;
  message?: string;
  store?: RateLimitStore;
  failClosed?: boolean;
}) {
  const store = options.store || defaultSharedStore;
  const { windowMs, maxRequests, message = 'Too many requests. Please try again later.' } = options;

  return async (req: Request, res: Response, next: NextFunction) => {
    try {
      const key = options.keyGenerator
        ? options.keyGenerator(req)
        : req.ip || req.socket.remoteAddress || 'unknown';

      const now = Date.now();
      const { count, oldestTimestamp } = await store.increment(key, windowMs);

      if (count > maxRequests) {
        const retryAfterSec = Math.max(1, Math.ceil((windowMs - (now - oldestTimestamp)) / 1000));
        res.setHeader('Retry-After', retryAfterSec);
        return res.status(429).json({
          success: false,
          code: 'RATE_LIMIT_EXCEEDED',
          message,
          retryAfterSeconds: retryAfterSec,
        });
      }

      res.setHeader('X-RateLimit-Limit', maxRequests);
      res.setHeader('X-RateLimit-Remaining', Math.max(0, maxRequests - count));
      next();
    } catch (err) {
      // P1: Fail closed on errors to prevent rate-limit bypass during outages
      if (config.isProduction || options.failClosed !== false) {
        return res.status(503).json({
          success: false,
          code: 'RATE_LIMIT_SERVICE_UNAVAILABLE',
          message: 'Security rate limit verification service is temporarily unavailable. Request blocked for safety.',
        });
      }
      next();
    }
  };
}

// 1. OTP Generation rate limiter: 4 requests per 5 minutes per IP/Phone
export const otpRateLimiter = createRateLimiter({
  windowMs: 5 * 60 * 1000,
  maxRequests: 4,
  keyGenerator: (req) => {
    const phone = req.body?.phone ? String(req.body.phone).replace(/[^0-9]/g, '').slice(-10) : '';
    return `otp:${phone || req.ip}`;
  },
  message: 'Too many OTP requests for this number. Please wait 5 minutes before trying again.',
});

// 2. OTP Verification / Auth rate limiter: 6 attempts per 5 minutes
export const authRateLimiter = createRateLimiter({
  windowMs: 5 * 60 * 1000,
  maxRequests: 6,
  keyGenerator: (req) => {
    const phone = req.body?.phone ? String(req.body.phone).replace(/[^0-9]/g, '').slice(-10) : '';
    return `auth:${phone || req.ip}`;
  },
  message: 'Too many verification attempts. Please wait 5 minutes before retrying.',
});

// 3. Payment initiation rate limiter: max 12 payments per minute
export const paymentRateLimiter = createRateLimiter({
  windowMs: 60 * 1000,
  maxRequests: 12,
  keyGenerator: (req: any) => `pay:${req.userId || req.ip}`,
  message: 'Payment velocity limit reached. Please wait a minute before sending another transaction.',
});

// 4. Sensitive MPIN actions rate limiter: 5 attempts per 5 minutes
export const mpinRateLimiter = createRateLimiter({
  windowMs: 5 * 60 * 1000,
  maxRequests: 5,
  keyGenerator: (req: any) => `mpin:${req.userId || req.ip}`,
  message: 'Too many MPIN attempts. Account lock protection engaged.',
});

// 5. Public VPA Resolution rate limiter: 25 requests per minute (P0 Issue 10: Anti-Enumeration Protection)
export const vpaRateLimiter = createRateLimiter({
  windowMs: 60 * 1000,
  maxRequests: 25,
  keyGenerator: (req) => `vpa:${req.ip || 'client'}`,
  message: 'Too many VPA lookup requests. Public enumeration protection active.',
});

// 6. Merchant operations rate limiter: 30 requests per minute
export const merchantRateLimiter = createRateLimiter({
  windowMs: 60 * 1000,
  maxRequests: 30,
  keyGenerator: (req: any) => `merchant:${req.userId || req.ip}`,
  message: 'Too many merchant requests. Please slow down.',
});
