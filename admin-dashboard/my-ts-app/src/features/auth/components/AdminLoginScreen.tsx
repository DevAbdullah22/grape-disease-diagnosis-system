import { useState, useRef, useEffect } from 'react';
import { Button } from '../../../components/ui/button';
import { Input } from '../../../components/ui/input';
import { Label } from '../../../components/ui/label';
import { Card, CardContent, CardHeader, CardTitle } from '../../../components/ui/card';
import { Eye, EyeOff, User, Lock, Shield } from 'lucide-react';
import { adminLogin } from '../../../services/api';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../../../stores/authStore';

export function AdminLoginScreen() {
  const [showPassword, setShowPassword] = useState(false);
  const [credentials, setCredentials] = useState({
    username: '',
    password: ''
  });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [shake, setShake] = useState(false);

  const usernameRef = useRef<HTMLInputElement>(null);
  const passwordRef = useRef<HTMLInputElement>(null);
  const navigate = useNavigate();
  const login = useAuthStore((state) => state.login);

  const getStatusFromError = (err: unknown): number | undefined => {
    if (typeof err === 'object' && err !== null) {
      const maybe = err as { response?: { status?: number } };
      return maybe.response?.status;
    }
    return undefined;
  };

  useEffect(() => {
    usernameRef.current?.focus();
  }, []);

  const handleLogin = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!credentials.username || !credentials.password) {
      setError('يرجى ملء جميع الحقول');
      setShake(true);
      return;
    }

    setIsLoading(true);
    setError('');

    try {
      const token = await adminLogin(credentials.username, credentials.password);
      login(token);
      setIsLoading(false);
      navigate('/admin/library', { replace: true });
    } catch (err: unknown) {
      setIsLoading(false);
      const status = getStatusFromError(err);
      if (status === 401) setError('بيانات الاعتماد غير صحيحة');
      else if (status === 403) setError('الحساب غير مفعل أو محظور');
      else if (err instanceof Error) setError(err.message || 'حدث خطأ أثناء تسجيل الدخول');
      else setError('حدث خطأ أثناء تسجيل الدخول');
      setShake(true);
      passwordRef.current?.focus();
    }
  };

  return (
    <div
      dir="rtl"
      lang="ar"
      className="relative min-h-screen bg-gradient-to-br from-slate-100 via-green-50 to-emerald-100 flex items-center justify-center p-4"
    >
      {/* Background Pattern */}
      <div className="absolute inset-0 opacity-5">
        <div className="absolute top-10 right-10 w-20 h-20 rounded-full bg-green-500"></div>
        <div className="absolute bottom-20 left-10 w-16 h-16 rounded-full bg-emerald-500"></div>
        <div className="absolute top-1/3 left-1/4 w-12 h-12 rounded-full bg-slate-500"></div>
        <div className="absolute bottom-1/3 right-1/4 w-14 h-14 rounded-full bg-teal-500"></div>
      </div>

      <form onSubmit={handleLogin} className="w-full max-w-md relative z-10" noValidate>
      <Card className="w-full relative shadow-2xl border-0 bg-white/95 backdrop-blur-sm text-right">
        <CardHeader className="text-center pb-8">
          <div className="flex justify-center mb-6">
            <div className="w-20 h-20 bg-gradient-to-br from-slate-700 to-green-600 rounded-full flex items-center justify-center shadow-lg">
              <Shield className="h-10 w-10 text-white" />
            </div>
          </div>
          <CardTitle className="text-2xl text-slate-800 mb-2">لوحة تحكم المشرف</CardTitle>
          <p className="text-gray-600">تسجيل دخول المشرف لإدارة النظام</p>
        </CardHeader>

        <CardContent
          className={`space-y-6 text-right ${shake ? 'animate-shake' : ''}`}
          onAnimationEnd={() => setShake(false)}
        >
          {error && (
            <div className="p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm text-right" role="alert">
              {error}
            </div>
          )}

          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="username" className="block text-right">اسم المستخدم</Label>
              <div className="relative">
                <Input
                  id="username"
                  ref={usernameRef}
                  type="text"
                  placeholder="أدخل اسم المستخدم"
                  value={credentials.username}
                  onChange={(e) => { setCredentials(prev => ({ ...prev, username: e.target.value })); setError(''); }}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault();
                      passwordRef.current?.focus();
                    }
                  }}
                  dir="rtl"
                  autoComplete="username"
                  className="pr-10 text-right placeholder:text-right focus:ring-2 focus:ring-green-500 focus:border-green-500"
                />
                <User className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="password" className="block text-right">كلمة المرور</Label>
              <div className="relative">
                <Input
                  id="password"
                  ref={passwordRef}
                  type={showPassword ? "text" : "password"}
                  placeholder="أدخل كلمة المرور"
                  value={credentials.password}
                  onChange={(e) => { setCredentials(prev => ({ ...prev, password: e.target.value })); setError(''); }}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault();
                      handleLogin();
                    }
                  }}
                  dir="rtl"
                  autoComplete="current-password"
                  className="pr-10 pl-10 text-right placeholder:text-right focus:ring-2 focus:ring-green-500 focus:border-green-500"
                />
                <Lock className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  className="absolute left-1 top-1/2 -translate-y-1/2 h-8 w-8 p-0 hover:bg-transparent"
                  onClick={() => setShowPassword(!showPassword)}
                >
                  {showPassword ? (
                    <EyeOff className="h-4 w-4 text-gray-400" />
                  ) : (
                    <Eye className="h-4 w-4 text-gray-400" />
                  )}
                </Button>
              </div>
            </div>
          </div>

          <Button
            type="submit"
            className="w-full bg-gradient-to-r from-slate-600 to-green-600 hover:from-slate-700 hover:to-green-700 text-white shadow-lg hover:shadow-xl transition-all duration-200"
            disabled={isLoading || !credentials.username || !credentials.password}
          >
            {isLoading ? (
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                جاري تسجيل الدخول...
              </div>
            ) : (
              'تسجيل الدخول'
            )}
          </Button>

          <div className="text-right">
            <p className="text-sm text-gray-500">
              لوحة التحكم مخصصة للمشرفين المعتمدين فقط
            </p>
          </div>
            </CardContent>
        </Card>
      </form>
    </div>
  );
}
