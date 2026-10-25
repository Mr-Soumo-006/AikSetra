import crypto from 'crypto';
import { v4 as uuidv4 } from 'uuid';
import { db } from '../db/database.js';
import type { AuditLog } from '../types/index.js';

export class AuditService {
  /**
   * Log an auditable security or financial action
   */
  public static log(params: {
    actorId?: string;
    action: string;
    resource: string;
    resourceId?: string;
    ipAddress?: string;
    userAgent?: string;
    metadata?: Record<string, any>;
  }): AuditLog {
    const { actorId, action, resource, resourceId, ipAddress, userAgent, metadata } = params;

    const payloadString = JSON.stringify({ actorId, action, resource, resourceId, metadata });
    const payloadHash = crypto.createHash('sha256').update(payloadString).digest('hex');

    const entry: AuditLog = {
      id: `aud_${uuidv4().replace(/-/g, '').slice(0, 14)}`,
      actorId,
      action,
      resource,
      resourceId,
      ipAddress,
      userAgent,
      payloadHash,
      metadata,
      timestamp: new Date().toISOString(),
    };

    db.get('auditLogs').push(entry);
    db.save();

    return entry;
  }

  public static getLogsForResource(resource: string, resourceId?: string): AuditLog[] {
    return db.get('auditLogs').filter(
      (log) => log.resource === resource && (!resourceId || log.resourceId === resourceId)
    );
  }
}
