import type { ReactNode } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Button } from './ui/button';
import { 
  BookOpen, 
  FileText, 
  LogOut,
} from 'lucide-react';
import { cn } from './ui/utils';
import { useAuthStore } from '../stores/authStore';

interface AppLayoutProps {
  children: ReactNode;
  isAdmin?: boolean;
}

export function AppLayout({ 
  children, 
  isAdmin,
}: AppLayoutProps) {
  void isAdmin;

  const navigate = useNavigate();
  const location = useLocation();
  const logout = useAuthStore((state) => state.logout);

  const adminNavItems = [
    { path: '/admin/treatment', icon: FileText, label: 'إدارة التوصيات' },
    { path: '/admin/library', icon: BookOpen, label: 'إدارة المكتبة' },
  ];

  // Admin Web Layout
  return (
    <div className="h-screen flex bg-gray-50" dir="rtl">
      {/* Sidebar */}
      <div className="w-64 bg-white shadow-lg border-l flex flex-col">
        <div className="p-6 border-b">
          <h1 className="text-xl font-semibold text-green-800">لوحة تحكم المشرف</h1>
        </div>
        
        <nav className="p-4 space-y-2 flex-1">
          {adminNavItems.map((item) => (
            <Button
              key={item.path}
              variant={location.pathname.startsWith(item.path) ? "default" : "ghost"}
              className={cn(
                "w-full justify-start text-right",
                location.pathname.startsWith(item.path) && "bg-green-100 text-green-700"
              )}
              onClick={() => navigate(item.path)}
            >
              <item.icon className="h-5 w-5 mr-3" />
              {item.label}
            </Button>
          ))}
        </nav>

        <div className="p-4 border-t">
          <Button
            variant="outline"
            className="w-full justify-start text-red-600 hover:bg-red-50 hover:text-red-700"
            onClick={() => {
              logout();
              navigate('/login', { replace: true });
            }}
          >
            <LogOut className="h-5 w-5 mr-3" />
            تسجيل الخروج
          </Button>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 overflow-auto">
        {children}
      </div>
    </div>
  );
}
