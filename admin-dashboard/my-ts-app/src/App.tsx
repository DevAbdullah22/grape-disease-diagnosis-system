import { Suspense, lazy } from 'react';
import {
  Navigate,
  Route,
  Routes,
  Outlet,
} from 'react-router-dom';
import { AppLayout } from './components/AppLayout';
import { LoadingSpinner } from './components/LoadingSpinner';
import { ErrorBoundary } from './components/ErrorBoundary';
import ProtectedRoute from './components/auth/ProtectedRoute';
import { useAuthStore } from './stores/authStore';

const AdminLoginScreen = lazy(() =>
  import('./features/auth/components/AdminLoginScreen').then((module) => ({
    default: module.AdminLoginScreen
  }))
);
const AdminLibraryManagement = lazy(() =>
  import('./features/library/pages/AdminLibraryPage').then((module) => ({
    default: module.AdminLibraryManagement
  }))
);
const AddContentScreen = lazy(() =>
  import('./features/library/pages/AddContentPage').then((module) => ({
    default: module.AddContentScreen
  }))
);
const TreatmentManagement = lazy(() =>
  import('./features/treatment/components/TreatmentManagement').then((module) => ({
    default: module.TreatmentManagement
  }))
);

const AdminLayout = () => (
    <AppLayout isAdmin={true}>
        <Outlet />
    </AppLayout>
)

export default function App() {
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated);

  return (
    <ErrorBoundary>
      <Suspense fallback={<LoadingSpinner />}>
        <Routes>
          <Route
            path="/login"
            element={isAuthenticated ? <Navigate to="/admin/library" replace /> : <AdminLoginScreen />}
          />
          
          <Route element={<ProtectedRoute><AdminLayout/></ProtectedRoute>}>
              <Route path="/admin/library" element={<AdminLibraryManagement />} />
              <Route path="/admin/library/add" element={<AddContentScreen />} />
              <Route path="/admin/library/edit" element={<AddContentScreen />} />
              <Route path="/admin/treatment" element={<TreatmentManagement />} />
          </Route>
          
          <Route path="*" element={<Navigate to={isAuthenticated ? "/admin/library" : "/login"} replace />} />
        </Routes>
      </Suspense>
    </ErrorBoundary>
  );
}
