import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import App from './App';
import { useAuthStore } from './stores/authStore';

vi.mock('./features/library/pages/AdminLibraryPage', () => ({
  AdminLibraryManagement: () => <div>Library Route Content</div>
}));

vi.mock('./features/library/pages/AddContentPage', () => ({
  AddContentScreen: () => <div>Add Content Route</div>
}));

vi.mock('./features/treatment/components/TreatmentManagement', () => ({
  TreatmentManagement: () => <div>Treatment Route Content</div>
}));

describe('App navigation', () => {
  const routeTimeout = { timeout: 5000 };

  beforeEach(() => {
    localStorage.clear();
    useAuthStore.setState({
      token: null,
      isAuthenticated: false
    });
  });

  it('redirects unauthenticated users from admin routes to login', async () => {
    render(
      <MemoryRouter initialEntries={['/admin/library']}>
        <App />
      </MemoryRouter>
    );

    expect(await screen.findByText('لوحة تحكم المشرف')).toBeInTheDocument();
    expect(screen.queryByText('Library Route Content')).not.toBeInTheDocument();
  });

  it('redirects authenticated users away from login to the library route', async () => {
    useAuthStore.setState({
      token: 'token-1',
      isAuthenticated: true
    });

    render(
      <MemoryRouter initialEntries={['/login']}>
        <App />
      </MemoryRouter>
    );

    expect(await screen.findByText('Library Route Content', {}, routeTimeout)).toBeInTheDocument();
  });

  it('navigates between admin sections using the sidebar', async () => {
    useAuthStore.setState({
      token: 'token-1',
      isAuthenticated: true
    });

    render(
      <MemoryRouter initialEntries={['/admin/library']}>
        <App />
      </MemoryRouter>
    );

    expect(await screen.findByText('Library Route Content', {}, routeTimeout)).toBeInTheDocument();

    fireEvent.click(screen.getByRole('button', { name: 'إدارة التوصيات' }));

    await waitFor(() => {
      expect(screen.queryByText('جاري التحميل...')).not.toBeInTheDocument();
    }, routeTimeout);
    expect(await screen.findByText('Treatment Route Content', {}, routeTimeout)).toBeInTheDocument();
  });

  it('logs out and returns to the login route', async () => {
    useAuthStore.setState({
      token: 'token-1',
      isAuthenticated: true
    });

    render(
      <MemoryRouter initialEntries={['/admin/library']}>
        <App />
      </MemoryRouter>
    );

    expect(await screen.findByText('Library Route Content', {}, routeTimeout)).toBeInTheDocument();

    fireEvent.click(screen.getByRole('button', { name: 'تسجيل الخروج' }));

    await waitFor(() => {
      expect(useAuthStore.getState().isAuthenticated).toBe(false);
    });
    expect(await screen.findByText('لوحة تحكم المشرف')).toBeInTheDocument();
  });
});
