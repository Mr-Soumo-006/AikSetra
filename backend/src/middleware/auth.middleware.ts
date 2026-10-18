import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config/index.js';
import { db } from '../db/database.js';

export interface AuthenticatedRequest extends Request {
  userId?: string;
  userVpa?: string;
}

export function authMiddleware(req: AuthenticatedRequest, res: Response, next: NextFunction) {
  // Support quick dev header or bearer token
  const devUserId = req.headers['x-user-id'] as string;
  if (devUserId) {
    const user = db.get('users').find((u) => u.id === devUserId);
    if (user) {
      req.userId = user.id;
      req.userVpa = user.primaryVpa;
      return next();
    }
  }

  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    // If running in development without auth token, default to Simo
    if (config.nodeEnv === 'development') {
      const defaultUser = db.get('users')[0];
      if (defaultUser) {
        req.userId = defaultUser.id;
        req.userVpa = defaultUser.primaryVpa;
        return next();
      }
    }
    return res.status(401).json({ success: false, message: 'Authentication required. Provide Bearer token or x-user-id header.' });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, config.jwtSecret) as any;
    req.userId = decoded.userId;
    req.userVpa = decoded.vpa;
    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Invalid or expired session token.' });
  }
}
