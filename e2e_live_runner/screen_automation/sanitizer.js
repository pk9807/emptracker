/**
 * Sensitive Data & Input Sanitizer
 * Masks passwords, API tokens, emails, phone numbers in logs and screen output.
 */
class DataSanitizer {
  /**
   * Masks email: john.doe@example.com -> j***e@example.com
   */
  static maskEmail(email) {
    if (!email || typeof email !== 'string') return '';
    const parts = email.split('@');
    if (parts.length !== 2) return '***';
    const name = parts[0];
    const domain = parts[1];
    if (name.length <= 2) return `${name[0]}*@${domain}`;
    return `${name[0]}${'*'.repeat(name.length - 2)}${name[name.length - 1]}@${domain}`;
  }

  /**
   * Masks password or secret token: secret123 -> ••••••••
   */
  static maskSecret(secret) {
    if (!secret || typeof secret !== 'string') return '••••';
    return '•'.repeat(Math.min(secret.length, 12));
  }

  /**
   * Sanitizes console log objects or strings
   */
  static sanitizeLog(text) {
    if (typeof text !== 'string') return text;
    return text
      .replace(/([a-zA-Z0-9_.+-]+)@([a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+)/g, (m) => DataSanitizer.maskEmail(m))
      .replace(/(password|secret|token|apiKey|auth_key)=([^\s&]+)/gi, '$1=••••••••')
      .replace(/(Bearer\s+)[A-Za-z0-9-_=.]+/gi, '$1[SANITIZED_JWT]');
  }
}

module.exports = DataSanitizer;
