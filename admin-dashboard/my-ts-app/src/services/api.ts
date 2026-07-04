import axios from 'axios';

// يحدد رابط قاعدة API من متغير البيئة أو يستخدم localhost كافتراضي أثناء التطوير.
// هذا يسمح بتبديل الخادم بسهولة دون تغيير الكود.
// export const API_BASE = (import.meta.env.VITE_API_URL as string) || 'http://almhadabi.runasp.net';
export const API_BASE = (import.meta.env.VITE_API_URL as string) || 'http://localhost:5067';
// export const API_BASE = (import.meta.env.VITE_API_URL as string) || 'http://192.168.8.174:5067';

// إنشاء مثيل Axios مشترك مع رأس الاستجابة الافتراضي.
// جميع الطلبات ستستخدم نفس قاعدة URL، مما يبسط أية تغييرات مستقبلية.
const api = axios.create({
  baseURL: `${API_BASE}/api`,
  headers: {
    Accept: 'application/json'
  }
});

// إعادة تصدير واجهات endpoints الخاصة بمكتبة المحتوى من المجلد الخاص بها.
// هذا يسمح للتطبيق بالوصول إلى وظائف المكتبة من خلال ملف واحد مركزي.
export {
  createCategory,
  createItem,
  deleteCategory,
  deleteItem,
  getCategories,
  getCategoryById,
  getCategoryDeleteInfo,
  getItem,
  getItemsByCategory,
  resolveImageUrl,
  updateCategory,
  updateItem
} from '../features/library/api/libraryApi';
export type { LibraryItemDto } from '../features/library/api/libraryApi';

// Notifications
// دوال إرسال الإشعارات وتسجيل جهاز المستخدم.
export async function registerDeviceToken(token: { userId?: string; token: string }) {
  const res = await api.post('/Notification/register-token', token);
  return res.data;
}

export async function sendNotificationToAll(payload: { title: string; body: string; type?: string }) {
  const res = await api.post('/Notification/send-all', payload);
  return res.data;
}

export async function sendNotificationToUser(payload: { userId: string; title: string; body: string }) {
  const res = await api.post('/Notification/send-user', payload);
  return res.data;
}

// Auth (firebase register)
// دالة تسجيل مستخدم جديد باستخدام توكن Firebase.
export async function registerWithFirebase(idToken: string, fullName?: string, photoUrl?: string) {
  const res = await api.post('/User/firebase-register', { IdToken: idToken, FullName: fullName, PhotoUrl: photoUrl });
  return res.data;
}

// Dashboard statistics
// جلب إحصائيات لوحة القيادة من الخادم.
export async function getDashboardStats() {
  const res = await api.get('/Statistics/dashboard');
  return res.data;
}

// Diseases
// يسترد قائمة الأمراض المتاحة من الخادم.
export async function getDiseases() {
  const res = await api.get('/Disease');
  return res.data as Array<{ id: string; name: string }>;
}

// Treatment Plans (admin)
import type { TreatmentPlanDto, TreatmentStepDto } from '../types/treatment';

export async function getPlansByDisease(diseaseId: string): Promise<TreatmentPlanDto[]> {
  const res = await api.get(`/admin/treatment-plans/by-disease/${diseaseId}`);
  return res.data as TreatmentPlanDto[];
}

export async function getPlanById(planId: string) {
  const res = await api.get(`/admin/treatment-plans/${planId}`);
  return res.data;
}

export async function createPlan(dto: { diseaseId: string; name: string; doseIntervalDays?: number }) {
  const res = await api.post('/admin/treatment-plans', { DiseaseId: dto.diseaseId, Name: dto.name, DoseIntervalDays: dto.doseIntervalDays });
  return res.data;
}

export async function updatePlan(dto: { id: string; name: string; doseIntervalDays?: number }) {
  const res = await api.put('/admin/treatment-plans', { Id: dto.id, Name: dto.name, DoseIntervalDays: dto.doseIntervalDays });
  return res.data;
}

export async function deletePlan(planId: string) {
  const res = await api.delete(`/admin/treatment-plans/${planId}`);
  return res.data;
}

// Treatment Steps (admin)
// دوال إدارة خطوات خطة العلاج: سحب القائمة، إنشاء وتحديث وحذف وإعادة ترتيب.
export async function getStepsByPlan(planId: string): Promise<TreatmentStepDto[]> {
  const res = await api.get(`/admin/treatment-plans/${planId}/steps`);
  return res.data as TreatmentStepDto[];
}

export async function createStep(formData: FormData) {
  const res = await api.post('/admin/treatment-plans/steps', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  });
  return res.data;
}

export async function updateStep(formData: FormData) {
  const res = await api.put('/admin/treatment-plans/steps', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  });
  return res.data;
}

export async function reorderSteps(planId: string, steps: Array<{ id: string; stepOrder: number }>) {
  try {
    // الطلب إلى الخادم لإعادة ترتيب قوائم الخطوات.
    const res = await api.put(`/admin/treatment-plans/${planId}/steps/order`, steps);
    return res.data;
  } catch (err: unknown) {
    const extractMessage = (e: unknown) => {
      // استخرج رسالة الخطأ بشكل آمن من axios أو من أي نوع آخر
      if (axios.isAxiosError(e)) return e.response?.data?.message || e.message;
      if (e instanceof Error) return e.message;
      if (typeof e === 'string') return e;
      try { return JSON.stringify(e); } catch { return 'خطأ في الخادم أثناء إعادة ترتيب الخطوات'; }
    };
    const msg = extractMessage(err) || 'خطأ في الخادم أثناء إعادة ترتيب الخطوات';
    throw new Error(msg);
  }
}

export async function deleteStep(stepId: string) {
  const res = await api.delete(`/admin/treatment-plans/steps/${stepId}`);
  return res.data;
}

export default api;

// Auth helpers for admin
// دوال إعداد وإلغاء إعداد التوكين للمسؤول في Axios وتخزينه في localStorage.
export function setAuthToken(token?: string | null) {
  if (typeof window === 'undefined') return;
  if (token) {
    api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
    localStorage.setItem('admin_token', token);
  } else {
    delete api.defaults.headers.common['Authorization'];
    localStorage.removeItem('admin_token');
  }
}

export async function adminLogin(username: string, password: string) {
  const res = await api.post('/admin/auth/login', { username, password });
  const token = res.data?.token;
  if (!token) throw new Error('No token returned from login');
  setAuthToken(token);
  return token as string;
}

export function tryInitAuthFromStorage() {
  if (typeof window === 'undefined') return;
  const token = localStorage.getItem('admin_token');
  if (token) setAuthToken(token);
}
