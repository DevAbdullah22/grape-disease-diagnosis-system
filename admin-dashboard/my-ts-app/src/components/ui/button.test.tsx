import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';

import { Button, buttonVariants } from './button';

describe('Button', () => {
  it('renders a native button with default variants', () => {
    render(<Button>حفظ</Button>);

    const button = screen.getByRole('button', { name: 'حفظ' });
    expect(button).toHaveAttribute('data-slot', 'button');
    expect(button.className).toContain('inline-flex');
    expect(button.className).toContain('bg-primary');
  });

  it('supports explicit variants and asChild rendering', () => {
    render(
      <Button asChild variant="outline" size="sm">
        <a href="/docs">Docs</a>
      </Button>
    );

    const link = screen.getByRole('link', { name: 'Docs' });
    expect(link).toHaveAttribute('data-slot', 'button');
    expect(link).toHaveAttribute('href', '/docs');
    expect(link.className).toContain('border');
    expect(link.className).toContain('h-8');
  });

  it('exposes class helpers for destructive icon buttons', () => {
    const classes = buttonVariants({ variant: 'destructive', size: 'icon' });

    expect(classes).toContain('bg-destructive');
    expect(classes).toContain('size-9');
  });
});
