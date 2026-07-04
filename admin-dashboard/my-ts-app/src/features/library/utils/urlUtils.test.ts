import { describe, expect, it } from 'vitest';
import {
  getSourceHostname,
  isTrustedSourceDomain,
  isValidSecureSourceUrl
} from './urlUtils';

describe('urlUtils', () => {
  it('validates only https urls and rejects forbidden schemes', () => {
    expect(isValidSecureSourceUrl('https://example.com')).toBe(true);
    expect(isValidSecureSourceUrl('http://example.com')).toBe(false);
    expect(isValidSecureSourceUrl('javascript:alert(1)')).toBe(false);
    expect(isValidSecureSourceUrl('data:text/plain,hello')).toBe(false);
    expect(isValidSecureSourceUrl('   ')).toBe(false);
    expect(isValidSecureSourceUrl('file:///tmp/report.pdf')).toBe(false);
  });

  it('extracts hostnames and handles invalid urls safely', () => {
    expect(getSourceHostname('https://sub.nih.gov/path')).toBe('sub.nih.gov');
    expect(getSourceHostname(' HTTPS://WHO.INT/path ')).toBe('who.int');
    expect(getSourceHostname('not-a-url')).toBe('');
  });

  it('detects trusted domains including subdomains', () => {
    expect(isTrustedSourceDomain('')).toBe(false);
    expect(isTrustedSourceDomain('who.int')).toBe(true);
    expect(isTrustedSourceDomain('sub.ncbi.nlm.nih.gov')).toBe(true);
    expect(isTrustedSourceDomain('example.com')).toBe(false);
  });
});
