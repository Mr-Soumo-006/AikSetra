/**
 * Financial Input Validation & Sanitization Helpers
 * Enforces RBI & NPCI bounds, format regexes, and character limits.
 */

export const VPA_REGEX = /^[a-zA-Z0-9.\-_]{2,64}@[a-zA-Z0-9.\-_]{2,32}$/;
export const INDIAN_PHONE_REGEX = /^[6-9]\d{9}$/;
export const IFSC_REGEX = /^[A-Z]{4}0[A-Z0-9]{6}$/;

export interface ValidationResult {
  valid: boolean;
  error?: string;
}

export function validatePaymentAmount(amount: any, maxLimit: number = 100000): ValidationResult {
  const num = typeof amount === 'number' ? amount : parseFloat(String(amount));
  if (!Number.isFinite(num) || isNaN(num)) {
    return { valid: false, error: 'Payment amount must be a valid number.' };
  }
  if (num <= 0) {
    return { valid: false, error: 'Payment amount must be greater than zero.' };
  }
  // Check maximum 2 decimal places
  const parts = num.toString().split('.');
  if (parts.length > 1 && parts[1].length > 2) {
    return { valid: false, error: 'Payment amount cannot have more than 2 decimal places (paise).' };
  }
  if (num > maxLimit) {
    return { valid: false, error: `Payment amount exceeds maximum transaction limit of ₹${maxLimit.toLocaleString('en-IN')}.` };
  }
  return { valid: true };
}

export function validateVpa(vpa: any): ValidationResult {
  if (typeof vpa !== 'string' || !vpa.trim()) {
    return { valid: false, error: 'VPA (UPI ID) is required.' };
  }
  const clean = vpa.trim().toLowerCase();
  if (clean.length < 5 || clean.length > 100) {
    return { valid: false, error: 'VPA length must be between 5 and 100 characters.' };
  }
  if (!VPA_REGEX.test(clean)) {
    return { valid: false, error: 'Invalid VPA format. Must match username@bank (e.g. user@aiksetra).' };
  }
  return { valid: true };
}

export function validatePhone(phone: any): ValidationResult {
  if (typeof phone !== 'string' && typeof phone !== 'number') {
    return { valid: false, error: 'Phone number is required.' };
  }
  const clean = String(phone).replace(/\D/g, '').slice(-10);
  if (!INDIAN_PHONE_REGEX.test(clean)) {
    return { valid: false, error: 'Please enter a valid 10-digit Indian mobile number.' };
  }
  return { valid: true };
}

export function validateIfsc(ifsc: any): ValidationResult {
  if (typeof ifsc !== 'string' || !ifsc.trim()) {
    return { valid: false, error: 'Bank IFSC is required.' };
  }
  const clean = ifsc.trim().toUpperCase();
  if (!IFSC_REGEX.test(clean)) {
    return { valid: false, error: 'Invalid IFSC format. Must be 11 characters (e.g. SBIN0001234).' };
  }
  return { valid: true };
}

export function sanitizeRemark(remark: any): string {
  if (typeof remark !== 'string') return 'UPI Payment';
  const clean = remark.replace(/[\r\n\t]/g, ' ').replace(/[<>]/g, '').trim();
  return clean.slice(0, 100) || 'UPI Payment';
}
