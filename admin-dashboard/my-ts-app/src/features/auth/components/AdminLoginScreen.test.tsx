import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
  adminLogin: vi.fn(),
  setAuthToken: vi.fn(),
  navigate: vi.fn()
}));

vi.mock('../../../services/api', async () => {
  const actual = await vi.importActual<typeof import('../../../services/api')>(
    '../../../services/api'
  );

  return {
    ...actual,
    adminLogin: mocks.adminLogin,
    setAuthToken: mocks.setAuthToken
  };
});

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>(
    'react-router-dom'
  );

  return {
    ...actual,
    useNavigate: () => mocks.navigate
  };
});

import { useAuthStore } from '../../../stores/authStore';
import { AdminLoginScreen } from './AdminLoginScreen';

describe('AdminLoginScreen', () => {
  beforeEach(() => {
    localStorage.clear();
    useAuthStore.setState({
      token: null,
      isAuthenticated: false
    });
    mocks.adminLogin.mockReset();
    mocks.setAuthToken.mockReset();
    mocks.navigate.mockReset();
  });

  it('shows a validation error when the form is submitted empty', async () => {
    const { container } = render(<AdminLoginScreen />);

    fireEvent.submit(container.querySelector('form')!);

    expect(await screen.findByRole('alert')).toHaveTextContent('يرجى ملء جميع الحقول');
    expect(mocks.adminLogin).not.toHaveBeenCalled();
  });

  it('toggles password visibility from the eye button', () => {
    const { container } = render(<AdminLoginScreen />);
    const passwordInput = screen.getByLabelText('كلمة المرور');
    const toggleButton = container.querySelector('button[type="button"]');

    expect(passwordInput).toHaveAttribute('type', 'password');

    fireEvent.click(toggleButton!);
    expect(passwordInput).toHaveAttribute('type', 'text');

    fireEvent.click(toggleButton!);
    expect(passwordInput).toHaveAttribute('type', 'password');
  });

  it('moves focus to the password field on Enter, then logs in and navigates', async () => {
    mocks.adminLogin.mockResolvedValue('token-123');

    render(<AdminLoginScreen />);

    const usernameInput = screen.getByLabelText('اسم المستخدم');
    const passwordInput = screen.getByLabelText('كلمة المرور');

    await waitFor(() => {
      expect(usernameInput).toHaveFocus();
    });

    fireEvent.change(usernameInput, { target: { value: 'admin' } });
    fireEvent.keyDown(usernameInput, { key: 'Enter' });
    expect(passwordInput).toHaveFocus();

    fireEvent.change(passwordInput, { target: { value: 'secret' } });
    fireEvent.keyDown(passwordInput, { key: 'Enter' });

    await waitFor(() => {
      expect(mocks.adminLogin).toHaveBeenCalledWith('admin', 'secret');
    });
    expect(useAuthStore.getState()).toMatchObject({
      token: 'token-123',
      isAuthenticated: true
    });
    expect(mocks.setAuthToken).toHaveBeenCalledWith('token-123');
    expect(mocks.navigate).toHaveBeenCalledWith('/admin/library', { replace: true });
  });

  it('shows the unauthorized message when the backend returns 401', async () => {
    mocks.adminLogin.mockRejectedValue({
      response: {
        status: 401
      }
    });

    render(<AdminLoginScreen />);

    const usernameInput = screen.getByLabelText('اسم المستخدم');
    const passwordInput = screen.getByLabelText('كلمة المرور');

    fireEvent.change(usernameInput, { target: { value: 'admin' } });
    fireEvent.change(passwordInput, { target: { value: 'wrong-pass' } });
    fireEvent.click(screen.getByRole('button', { name: 'تسجيل الدخول' }));

    expect(await screen.findByRole('alert')).toHaveTextContent('بيانات الاعتماد غير صحيحة');
    expect(passwordInput).toHaveFocus();
  });

  it('shows the forbidden-account message when the backend returns 403', async () => {
    mocks.adminLogin.mockRejectedValue({
      response: {
        status: 403
      }
    });

    render(<AdminLoginScreen />);

    fireEvent.change(screen.getByLabelText('اسم المستخدم'), {
      target: { value: 'admin' }
    });
    fireEvent.change(screen.getByLabelText('كلمة المرور'), {
      target: { value: 'secret' }
    });
    fireEvent.click(screen.getByRole('button', { name: 'تسجيل الدخول' }));

    expect(await screen.findByRole('alert')).toHaveTextContent('الحساب غير مفعل أو محظور');
  });

  it('shows the generic error message when a normal Error is thrown', async () => {
    mocks.adminLogin.mockRejectedValue(new Error('Network unavailable'));

    render(<AdminLoginScreen />);

    fireEvent.change(screen.getByLabelText('اسم المستخدم'), {
      target: { value: 'admin' }
    });
    fireEvent.change(screen.getByLabelText('كلمة المرور'), {
      target: { value: 'secret' }
    });
    fireEvent.click(screen.getByRole('button', { name: 'تسجيل الدخول' }));

    expect(await screen.findByRole('alert')).toHaveTextContent('Network unavailable');
  });

  it('falls back to the default login error when an Error has no message', async () => {
    mocks.adminLogin.mockRejectedValue(new Error(''));

    render(<AdminLoginScreen />);

    fireEvent.change(screen.getByLabelText('اسم المستخدم'), {
      target: { value: 'admin' }
    });
    fireEvent.change(screen.getByLabelText('كلمة المرور'), {
      target: { value: 'secret' }
    });
    fireEvent.click(screen.getByRole('button', { name: 'تسجيل الدخول' }));

    expect(await screen.findByRole('alert')).toHaveTextContent('حدث خطأ أثناء تسجيل الدخول');
  });

  it('falls back to the generic login error when the rejection is not an Error object', async () => {
    mocks.adminLogin.mockRejectedValue('unexpected failure');

    render(<AdminLoginScreen />);

    fireEvent.change(screen.getByLabelText('اسم المستخدم'), {
      target: { value: 'admin' }
    });
    fireEvent.change(screen.getByLabelText('كلمة المرور'), {
      target: { value: 'secret' }
    });
    fireEvent.click(screen.getByRole('button', { name: 'تسجيل الدخول' }));

    expect(await screen.findByRole('alert')).toHaveTextContent('حدث خطأ أثناء تسجيل الدخول');
  });

  it('adds the shake animation class after a validation failure', () => {
    const { container } = render(<AdminLoginScreen />);

    fireEvent.submit(container.querySelector('form')!);

    const animatedBlock = container.querySelector('.animate-shake');
    expect(animatedBlock).not.toBeNull();
  });
});
