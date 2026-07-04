import { beforeEach, describe, expect, it, vi } from 'vitest';
import api from '../services/api';
import { useAuthStore } from './authStore';

function resetAuthStore() {
  useAuthStore.setState({
    token: null,
    isAuthenticated: false
  });
  delete api.defaults.headers.common.Authorization;
  localStorage.clear();
}

describe('useAuthStore', () => {
  beforeEach(() => {
    resetAuthStore();
  });

  it('hydrates authenticated state from localStorage', () => {
    localStorage.setItem('admin_token', 'stored-token');

    useAuthStore.getState().hydrate();

    expect(useAuthStore.getState().token).toBe('stored-token');
    expect(useAuthStore.getState().isAuthenticated).toBe(true);
    expect(api.defaults.headers.common.Authorization).toBe('Bearer stored-token');
  });

  it('hydrate clears auth state when no stored token exists', () => {
    useAuthStore.setState({
      token: 'stale-token',
      isAuthenticated: true
    });
    api.defaults.headers.common.Authorization = 'Bearer stale-token';

    useAuthStore.getState().hydrate();

    expect(useAuthStore.getState().token).toBeNull();
    expect(useAuthStore.getState().isAuthenticated).toBe(false);
    expect(api.defaults.headers.common.Authorization).toBeUndefined();
  });

  it('login persists token and auth header', () => {
    useAuthStore.getState().login('fresh-token');

    expect(useAuthStore.getState().token).toBe('fresh-token');
    expect(useAuthStore.getState().isAuthenticated).toBe(true);
    expect(localStorage.getItem('admin_token')).toBe('fresh-token');
    expect(api.defaults.headers.common.Authorization).toBe('Bearer fresh-token');
  });

  it('logout clears token, storage, and auth header', () => {
    useAuthStore.getState().login('fresh-token');

    useAuthStore.getState().logout();

    expect(useAuthStore.getState().token).toBeNull();
    expect(useAuthStore.getState().isAuthenticated).toBe(false);
    expect(localStorage.getItem('admin_token')).toBeNull();
    expect(api.defaults.headers.common.Authorization).toBeUndefined();
  });

  it('initializes safely when window is unavailable', async () => {
    vi.resetModules();
    vi.stubGlobal('window', undefined);

    const { useAuthStore: isolatedStore } = await import('./authStore');

    expect(isolatedStore.getState().token).toBeNull();
    expect(isolatedStore.getState().isAuthenticated).toBe(false);

    vi.unstubAllGlobals();
  });
});
