import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';

import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle
} from './card';

describe('Card', () => {
  it('renders all card slots with their content and slot markers', () => {
    const { container } = render(
      <Card className="custom-card">
        <CardHeader className="header-extra">
          <CardTitle>عنوان البطاقة</CardTitle>
          <CardDescription>وصف البطاقة</CardDescription>
          <CardAction>إجراء</CardAction>
        </CardHeader>
        <CardContent>المحتوى</CardContent>
        <CardFooter>التذييل</CardFooter>
      </Card>
    );

    expect(screen.getByText('عنوان البطاقة')).toHaveAttribute('data-slot', 'card-title');
    expect(screen.getByText('وصف البطاقة')).toHaveAttribute('data-slot', 'card-description');
    expect(screen.getByText('إجراء')).toHaveAttribute('data-slot', 'card-action');
    expect(screen.getByText('المحتوى')).toHaveAttribute('data-slot', 'card-content');
    expect(screen.getByText('التذييل')).toHaveAttribute('data-slot', 'card-footer');

    const card = container.querySelector('[data-slot="card"]');
    expect(card).toHaveClass('custom-card');
    expect(card?.className).toContain('rounded-xl');
  });
});
