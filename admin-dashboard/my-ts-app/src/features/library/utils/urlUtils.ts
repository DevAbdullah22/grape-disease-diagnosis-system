// أدوات مساعدة للتحقق من روابط المصادر المستخدمة في المحتوى.
// هذه الوظائف تستخدم عند إدخال مصادر خارجية لضمان أمان الروابط وجودتها.

// قائمة النطاقات الموثوقة التي يمكن تمييزها عند عرض قائمة المصادر.
export const TRUSTED_SOURCE_DOMAINS = [
  'who.int',
  'fao.org',
  'usda.gov',
  'cdc.gov',
  'nih.gov',
  'epa.gov',
  'nature.com',
  'springer.com',
  'sciencedirect.com',
  'ncbi.nlm.nih.gov',
  'mdpi.com'
];

// نمنع أنواع URI غير الآمنة مثل javascript: و data: و file:.
export const FORBIDDEN_SCHEMES_REGEX = /^(javascript|data|file):/i;

// يتحقق من أن الرابط صالح وآمن.
// يسمح فقط برابط https:// صالح.
export const isValidSecureSourceUrl = (value: string): boolean => {
  const normalized = value.trim();
  if (!normalized || FORBIDDEN_SCHEMES_REGEX.test(normalized)) return false;

  try {
    const parsed = new URL(normalized);
    return parsed.protocol === 'https:';
  } catch {
    return false;
  }
};

// يستخرج اسم المضيف من رابط المصدر.
// يُستخدم لعرض اسم الموقع أو التحقق من الثقة.
export const getSourceHostname = (value: string): string => {
  try {
    return new URL(value.trim()).hostname.toLowerCase();
  } catch {
    return '';
  }
};

// يتحقق مما إذا كان النطاق ضمن قائمة المجالات الموثوقة أو أحد النطاقات الفرعية لها.
// يساعد في عرض العلامات أو شارات الثقة للمستخدم.
export const isTrustedSourceDomain = (hostname: string): boolean => {
  if (!hostname) return false;
  return TRUSTED_SOURCE_DOMAINS.some(
    domain => hostname === domain || hostname.endsWith(`.${domain}`)
  );
};
  