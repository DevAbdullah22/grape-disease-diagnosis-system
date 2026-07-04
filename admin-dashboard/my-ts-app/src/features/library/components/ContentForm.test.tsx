import { render, screen } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';

import { ContentForm } from './ContentForm';

describe('ContentForm', () => {
  it('applies explicit styling to markdown headings in the preview pane', () => {
    render(
      <ContentForm
        formData={{
          title: 'عنوان',
          shortDescription: 'وصف',
          category: 'الأمراض',
          content: '# عنوان رئيسي\n## عنوان فرعي\nفقرة توضيحية',
          newCategory: ''
        }}
        updateForm={vi.fn()}
        errors={{}}
        setErrors={vi.fn()}
        contentRef={{ current: null }}
        editorHeight="h-96"
        onInsertFormatting={vi.fn()}
        categorySection={<div>Category Section</div>}
      />
    );

    const mainHeading = screen.getByRole('heading', { level: 1, name: 'عنوان رئيسي' });
    const subHeading = screen.getByRole('heading', { level: 2, name: 'عنوان فرعي' });

    expect(mainHeading.className).toContain('text-3xl');
    expect(mainHeading.className).toContain('font-bold');
    expect(subHeading.className).toContain('text-2xl');
    expect(subHeading.className).toContain('font-semibold');
  });
});
