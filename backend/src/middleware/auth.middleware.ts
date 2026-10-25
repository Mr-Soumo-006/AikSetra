import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config/index.js';
import { db } from '../db/database.js';

export interface AuthenticatedRequest extends Request {
  userId?: string;
  userVpa?: string;
  isAdmin?: boolean;
}

/**
 * Issue 1: Authentication enforcement
 * Disallows bypasses via x-user-id headers or unauthenticated default-user fallback.
 * Every request MUST present an active cryptographically verified Bearer JWT.
 */
export function authMiddleware(req: AuthenticatedRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      code: 'AUTH_REQUIRED',
      message: 'Access denied. Valid Bearer authentication token required.',
    });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, config.jwtSecret) as any;
    if (!decoded || !decoded.userId) {
      return res.status(401).json({ success: false, code: 'INVALID_TOKEN', message: 'Malformed authentication token.' });
    }

    const user = db.get('users').find((u) => u.id === decoded.userId);
    if (!user) {
      return res.status(401).json({ success: false, code: 'USER_NOT_FOUND', message: 'User session has expired or user account not found.' });
    }

    req.userId = user.id;
    req.userVpa = user.primaryVpa;
    req.isAdmin = user.isAdmin === true;
    next();
  } catch (err: any) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, code: 'TOKEN_EXPIRED', message: 'Session expired. Please log in again.' });
    }
    return res.status(401).json({ success: false, code: 'INVALID_TOKEN', message: 'Invalid or forged authentication signature.' });
  }
}

/**
 * Issue 38: Admin authorization middleware
 * Protects administrative and configuration endpoints.
 */
export function adminAuthMiddleware(req: AuthenticatedRequest, res: Response, next: NextFunction) {
  const adminKey = req.headers['x-admin-key'] as string;
  if (adminKey && adminKey === config.adminApiKey) {
    req.isAdmin = true;
    return next();
  }

  // Fallback to checking authenticated user's isAdmin claim
  authMiddleware(req, res, () => {
    if (req.isAdmin === true) {
      return next();
    }
    return res.status(403).json({
      success: false,
      code: 'FORBIDDEN',
      message: 'Administrator privileges required to access this resource.',
    });
  });
}
