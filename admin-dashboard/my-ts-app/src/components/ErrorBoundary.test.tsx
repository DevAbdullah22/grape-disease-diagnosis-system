import { fireEvent, render, screen } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { useState } from 'react';
import { ErrorBoundary } from './ErrorBoundary';

describe('ErrorBoundary', () => {
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    consoleErrorSpy.mockRestore();
  });

  it('renders children while no error is thrown', () => {
    render(
      <ErrorBoundary>
        <div>Safe content</div>
      </ErrorBoundary>
    );

    expect(screen.getByText('Safe content')).toBeInTheDocument();
  });

  it('shows the fallback UI and recovers after retrying', () => {
    function FlakyChild({ shouldThrow }: { shouldThrow: boolean }) {
      if (shouldThrow) {
        throw new Error('Crash once');
      }

      return <div>Recovered content</div>;
    }

    function Harness() {
      const [shouldThrow, setShouldThrow] = useState(true);

      return (
        <>
          <button type="button" onClick={() => setShouldThrow(false)}>
            تجهيز الاستعادة
          </button>
          <ErrorBoundary>
            <FlakyChild shouldThrow={shouldThrow} />
          </ErrorBoundary>
        </>
      );
    }

    render(
      <Harness />
    );

    expect(screen.getByText('حدث خطأ غير متوقع')).toBeInTheDocument();
    expect(screen.getByText('Crash once')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'إعادة المحاولة' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'إعادة تحميل الصفحة' })).toBeInTheDocument();

    fireEvent.click(screen.getByRole('button', { name: 'تجهيز الاستعادة' }));
    fireEvent.click(screen.getByRole('button', { name: 'إعادة المحاولة' }));

    expect(screen.getByText('Recovered content')).toBeInTheDocument();
  });

  it('reloads the page through the boundary reload handler', () => {
    const reloadSpy = vi.fn();
    const originalWindow = window;

    Object.defineProperty(globalThis, 'window', {
      configurable: true,
      value: {
        ...originalWindow,
        location: {
          ...originalWindow.location,
          reload: reloadSpy
        }
      }
    });

    const boundary = new ErrorBoundary({ children: null });
    (boundary as unknown as { handleReload: () => void }).handleReload();

    expect(reloadSpy).toHaveBeenCalledTimes(1);

    Object.defineProperty(globalThis, 'window', {
      configurable: true,
      value: originalWindow
    });
  });
});
