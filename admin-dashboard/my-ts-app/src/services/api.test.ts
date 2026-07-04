import { beforeEach, describe, expect, it, vi } from 'vitest';
import api, {
  adminLogin,
  createPlan,
  createStep,
  deletePlan,
  deleteStep,
  getDashboardStats,
  getDiseases,
  getPlanById,
  getPlansByDisease,
  getStepsByPlan,
  registerWithFirebase,
  registerDeviceToken,
  reorderSteps,
  sendNotificationToAll,
  sendNotificationToUser,
  setAuthToken,
  tryInitAuthFromStorage,
  updatePlan,
  updateStep
} from './api';

describe('api service wrappers', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
    localStorage.clear();
    delete api.defaults.headers.common.Authorization;
  });

  it('forwards notification and dashboard requests to the expected endpoints', async () => {
    vi.spyOn(api, 'post').mockResolvedValue({ data: { ok: true } });
    vi.spyOn(api, 'get').mockResolvedValue({ data: [{ id: '1', name: 'مرض' }] });

    await expect(registerDeviceToken({ token: 'abc', userId: 'u1' })).resolves.toEqual({ ok: true });
    await expect(sendNotificationToAll({ title: 'title', body: 'body' })).resolves.toEqual({ ok: true });
    await expect(sendNotificationToUser({ userId: 'u1', title: 'title', body: 'body' })).resolves.toEqual({ ok: true });
    await expect(getDashboardStats()).resolves.toEqual([{ id: '1', name: 'مرض' }]);
    await expect(getDiseases()).resolves.toEqual([{ id: '1', name: 'مرض' }]);

    expect(api.post).toHaveBeenNthCalledWith(1, '/Notification/register-token', { token: 'abc', userId: 'u1' });
    expect(api.post).toHaveBeenNthCalledWith(2, '/Notification/send-all', { title: 'title', body: 'body' });
    expect(api.post).toHaveBeenNthCalledWith(3, '/Notification/send-user', { userId: 'u1', title: 'title', body: 'body' });
    expect(api.get).toHaveBeenNthCalledWith(1, '/Statistics/dashboard');
    expect(api.get).toHaveBeenNthCalledWith(2, '/Disease');
  });

  it('forwards firebase registration requests', async () => {
    vi.spyOn(api, 'post').mockResolvedValue({ data: { token: 'firebase-user' } });

    await expect(
      registerWithFirebase('firebase-token', 'مستخدم', 'https://avatar.test')
    ).resolves.toEqual({ token: 'firebase-user' });

    expect(api.post).toHaveBeenCalledWith('/User/firebase-register', {
      IdToken: 'firebase-token',
      FullName: 'مستخدم',
      PhotoUrl: 'https://avatar.test'
    });
  });

  it('forwards plan and step CRUD requests', async () => {
    const getSpy = vi.spyOn(api, 'get').mockResolvedValue({ data: { ok: true } });
    const postSpy = vi.spyOn(api, 'post').mockResolvedValue({ data: { ok: true } });
    const putSpy = vi.spyOn(api, 'put').mockResolvedValue({ data: { ok: true } });
    const deleteSpy = vi.spyOn(api, 'delete').mockResolvedValue({ data: { ok: true } });

    await getPlansByDisease('d1');
    await getPlanById('p1');
    await createPlan({ diseaseId: 'd1', name: 'خطة', doseIntervalDays: 7 });
    await updatePlan({ id: 'p1', name: 'خطة', doseIntervalDays: 5 });
    await deletePlan('p1');
    await getStepsByPlan('p1');
    await createStep(new FormData());
    await updateStep(new FormData());
    await deleteStep('s1');

    expect(getSpy).toHaveBeenCalledWith('/admin/treatment-plans/by-disease/d1');
    expect(getSpy).toHaveBeenCalledWith('/admin/treatment-plans/p1');
    expect(getSpy).toHaveBeenCalledWith('/admin/treatment-plans/p1/steps');
    expect(postSpy).toHaveBeenCalledWith('/admin/treatment-plans', {
      DiseaseId: 'd1',
      Name: 'خطة',
      DoseIntervalDays: 7
    });
    expect(putSpy).toHaveBeenCalledWith('/admin/treatment-plans', {
      Id: 'p1',
      Name: 'خطة',
      DoseIntervalDays: 5
    });
    expect(deleteSpy).toHaveBeenCalledWith('/admin/treatment-plans/p1');
    expect(postSpy).toHaveBeenCalledWith(
      '/admin/treatment-plans/steps',
      expect.any(FormData),
      { headers: { 'Content-Type': 'multipart/form-data' } }
    );
    expect(putSpy).toHaveBeenCalledWith(
      '/admin/treatment-plans/steps',
      expect.any(FormData),
      { headers: { 'Content-Type': 'multipart/form-data' } }
    );
    expect(deleteSpy).toHaveBeenCalledWith('/admin/treatment-plans/steps/s1');
  });

  it('wraps reorder step API errors with a readable message', async () => {
    vi.spyOn(api, 'put').mockRejectedValue({
      response: {
        data: {
          message: 'فشل حفظ الترتيب'
        }
      }
    });

    await expect(
      reorderSteps('p1', [{ id: 's1', stepOrder: 1 }])
    ).rejects.toThrow('فشل حفظ الترتيب');
  });

  it('returns the reorder response data on success and falls back to plain Error messages', async () => {
    const putSpy = vi.spyOn(api, 'put');

    putSpy.mockResolvedValueOnce({ data: { ok: true } });
    await expect(
      reorderSteps('p1', [{ id: 's1', stepOrder: 1 }])
    ).resolves.toEqual({ ok: true });

    putSpy.mockRejectedValueOnce(new Error('network down'));
    await expect(
      reorderSteps('p1', [{ id: 's1', stepOrder: 1 }])
    ).rejects.toThrow('network down');
  });

  it('handles string and unserializable reorder errors with fallback messages', async () => {
    const putSpy = vi.spyOn(api, 'put');
    const circular: { self?: unknown } = {};
    circular.self = circular;

    putSpy.mockRejectedValueOnce('fatal string');
    await expect(
      reorderSteps('p1', [{ id: 's1', stepOrder: 1 }])
    ).rejects.toThrow('fatal string');

    putSpy.mockRejectedValueOnce(circular);
    await expect(
      reorderSteps('p1', [{ id: 's1', stepOrder: 1 }])
    ).rejects.toThrow('خطأ في الخادم أثناء إعادة ترتيب الخطوات');
  });

  it('prefers the axios error message and falls back when it is empty', async () => {
    const putSpy = vi.spyOn(api, 'put');

    putSpy.mockRejectedValueOnce({
      isAxiosError: true,
      message: 'axios fallback message'
    });
    await expect(
      reorderSteps('p1', [{ id: 's1', stepOrder: 1 }])
    ).rejects.toThrow('axios fallback message');

    putSpy.mockRejectedValueOnce({
      isAxiosError: true,
      message: ''
    });
    await expect(
      reorderSteps('p1', [{ id: 's1', stepOrder: 1 }])
    ).rejects.toThrow('خطأ في الخادم أثناء إعادة ترتيب الخطوات');
  });

  it('stores and clears the auth token through setAuthToken', () => {
    setAuthToken('token-1');

    expect(localStorage.getItem('admin_token')).toBe('token-1');
    expect(api.defaults.headers.common.Authorization).toBe('Bearer token-1');

    setAuthToken(null);

    expect(localStorage.getItem('admin_token')).toBeNull();
    expect(api.defaults.headers.common.Authorization).toBeUndefined();
  });

  it('logs in and hydrates auth state from localStorage', async () => {
    vi.spyOn(api, 'post').mockResolvedValue({
      data: {
        token: 'server-token'
      }
    });

    await expect(adminLogin('admin', 'secret')).resolves.toBe('server-token');
    expect(localStorage.getItem('admin_token')).toBe('server-token');
    expect(api.defaults.headers.common.Authorization).toBe('Bearer server-token');

    delete api.defaults.headers.common.Authorization;
    tryInitAuthFromStorage();
    expect(api.defaults.headers.common.Authorization).toBe('Bearer server-token');
  });

  it('throws when login succeeds without a token and leaves auth empty when storage is empty', async () => {
    vi.spyOn(api, 'post').mockResolvedValue({
      data: {}
    });

    await expect(adminLogin('admin', 'secret')).rejects.toThrow('No token returned from login');

    tryInitAuthFromStorage();
    expect(api.defaults.headers.common.Authorization).toBeUndefined();
  });

  it('no-ops auth helpers when window is unavailable', () => {
    vi.stubGlobal('window', undefined);

    expect(() => setAuthToken('token-1')).not.toThrow();
    expect(() => setAuthToken(null)).not.toThrow();
    expect(() => tryInitAuthFromStorage()).not.toThrow();

    vi.unstubAllGlobals();
  });
});
