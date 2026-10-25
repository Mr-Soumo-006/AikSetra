import { Request, Response, NextFunction } from 'express';

interface RateLimitRecord {
  timestamps: number[];
}

export function createRateLimiter(options: {
  windowMs: number;
  maxRequests: number;
  keyGenerator?: (req: Request) => string;
  message?: string;
}) {
  const store = new Map<string, RateLimitRecord>();
  const { windowMs, maxRequests, message = 'Too many requests. Please try again later.' } = options;

  // Periodic cleanup every 5 minutes
  setInterval(() => {
    const now = Date.now();
    for (const [key, record] of store.entries()) {
      record.timestamps = record.timestamps.filter((ts) => now - ts < windowMs);
      if (record.timestamps.length === 0) {
        store.delete(key);
      }
    }
  }, 5 * 60 * 1000).unref();

  return (req: Request, res: Response, next: NextFunction) => {
    const key = options.keyGenerator
      ? options.keyGenerator(req)
      : req.ip || req.socket.remoteAddress || 'unknown';

    const now = Date.now();
    let record = store.get(key);

    if (!record) {
      record = { timestamps: [] };
      store.set(key, record);
    }

    // Filter out timestamps outside current window
    record.timestamps = record.timestamps.filter((ts) => now - ts < windowMs);

    if (record.timestamps.length >= maxRequests) {
      const oldest = record.timestamps[0];
      const retryAfterSec = Math.ceil((windowMs - (now - oldest)) / 1000);
      res.setHeader('Retry-After', retryAfterSec);
      return res.status(429).json({
        success: false,
        code: 'RATE_LIMIT_EXCEEDED',
        message,
        retryAfterSeconds: retryAfterSec,
      });
    }

    record.timestamps.push(now);
    res.setHeader('X-RateLimit-Limit', maxRequests);
    res.setHeader('X-RateLimit-Remaining', maxRequests - record.timestamps.length);
    next();
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
