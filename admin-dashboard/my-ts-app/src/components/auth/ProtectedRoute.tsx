// هذا المكون يضمن أن صفحات الإدارة أو المسارات المحمية لا يمكن الوصول إليها إلا بعد تسجيل الدخول.
// إذا لم يكن المستخدم مصادقًا، فإنه يعيد توجيهه إلى صفحة تسجيل الدخول ويحفظ المسار الأصلي للعودة إليه بعد النجاح.
import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuthStore } from '../../stores/authStore';

interface ProtectedRouteProps {
  children: React.ReactNode;
}

const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ children }) => {
  // قراءة حالة المصادقة من متجر Zustand
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated);

  // حفظ الموقع الحالي لتمريره إلى صفحة تسجيل الدخول
  // بحيث يمكن العودة إلى الصفحة السابقة بعد المصادقة.
  const location = useLocation();

  // إذا لم يكن المستخدم مصادقًا، استخدم <Navigate> لإعادة التوجيه إلى /login.
  // replace يمنع إضافة مسار الدخول إلى سجل التاريخ لكي لا يعود المستخدم إليه بالرجوع.
  if (!isAuthenticated) {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  // إذا كان المستخدم مسجل دخول، عرض المحتوى المحمي.
  return <>{children}</>;
};

export default ProtectedRoute;
