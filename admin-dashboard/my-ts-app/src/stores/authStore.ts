// مخزن Zustand لإدارة مصادقة المسؤول عبر التوكن المخزن في localStorage.
import { create } from 'zustand';
import { setAuthToken } from '../services/api';

// قراءة التوكن من التخزين المحلي عند بدء التطبيق
function readStoredToken() {
  if (typeof window === 'undefined') {
    return null;
  }

  return localStorage.getItem('admin_token');
}

interface AuthState {
  token: string | null;
  isAuthenticated: boolean;
  login: (token: string) => void;
  logout: () => void;
  hydrate: () => void;
}

export const useAuthStore = create<AuthState>((set) => {
  const initialToken = readStoredToken();

  return {
    token: initialToken,
    isAuthenticated: Boolean(initialToken),

    // تسجيل الدخول: حفظ التوكن في axios و localStorage وتحديث الحالة
    login: (token) => {
      setAuthToken(token);
      set({ token, isAuthenticated: true });
    },

    // تسجيل الخروج: إزالة التوكن من axios و localStorage وتحديث الحالة
    logout: () => {
      setAuthToken(null);
      set({ token: null, isAuthenticated: false });
    },

    // إعادة تهيئة الحالة من التخزين المحلي عند تحميل التطبيق أو إعادة تحميل الصفحة
    hydrate: () => {
      const token = readStoredToken();
      if (token) {
        setAuthToken(token);
      } else {
        setAuthToken(null);
      }
      set({ token, isAuthenticated: Boolean(token) });
    }
  };
});
