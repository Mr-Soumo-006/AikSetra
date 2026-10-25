/**
 * HTML and URL Escaping Helpers (P0 Issue 8: Prevents XSS / HTML injection in payment link templates)
 */
export function escapeHtml(str: string | undefined | null): string {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

export function sanitizeUrl(url: string | undefined | null): string {
  if (!url) return '#';
  const clean = String(url).trim();
  if (clean.startsWith('upi://') || clean.startsWith('http://') || clean.startsWith('https://')) {
    return clean.replace(/"/g, '&quot;').replace(/'/g, '&#39;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }
  return '#';
}
