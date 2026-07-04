import { describe, expect, it, vi } from 'vitest';
import { resolveCategoryId, validateSources } from './libraryService';

describe('validateSources', () => {
  it('filters blanks and keeps only invalid secure urls in invalidSourceValues', () => {
    const result = validateSources(
      [' https://example.com ', '', 'http://unsafe.test', 'javascript:alert(1)'],
      (value) => value.startsWith('https://')
    );

    expect(result.filteredSources).toEqual([
      'https://example.com',
      'http://unsafe.test',
      'javascript:alert(1)'
    ]);
    expect(result.invalidSourceValues).toEqual([
      'http://unsafe.test',
      'javascript:alert(1)'
    ]);
  });
});

describe('resolveCategoryId', () => {
  it('uses the selected category id when provided', async () => {
    const result = await resolveCategoryId({
      categoriesState: [{ id: '1', name: 'الوقاية' }],
      selectedCategoryId: '1',
      formData: {
        title: 'title',
        shortDescription: 'short',
        category: 'الوقاية',
        content: 'content',
        newCategory: ''
      }
    });

    expect(result).toEqual({
      categoryId: '1',
      status: 'existing'
    });
  });

  it('reuses an existing duplicate category name ignoring case and spaces', async () => {
    const result = await resolveCategoryId({
      categoriesState: [{ id: '2', name: 'Pesticides' }],
      selectedCategoryId: '',
      formData: {
        title: 'title',
        shortDescription: 'short',
        category: '',
        content: 'content',
        newCategory: '  pesticides  '
      }
    });

    expect(result.status).toBe('reused');
    expect(result.categoryId).toBe('2');
    expect(result.nextFormData).toEqual({
      title: 'title',
      shortDescription: 'short',
      category: 'Pesticides',
      content: 'content',
      newCategory: ''
    });
    expect(result.nextShowNewCategory).toBe(false);
  });

  it('creates a new category when no existing match is found', async () => {
    const createCategory = vi.fn().mockResolvedValue({
      id: '3',
      name: 'فئة جديدة'
    });

    const result = await resolveCategoryId({
      categoriesState: [],
      selectedCategoryId: '',
      formData: {
        title: 'title',
        shortDescription: 'short',
        category: '',
        content: 'content',
        newCategory: 'فئة جديدة'
      },
      createCategory
    });

    expect(createCategory).toHaveBeenCalledWith({ name: 'فئة جديدة' });
    expect(result).toEqual({
      categoryId: '3',
      status: 'created',
      category: {
        id: '3',
        name: 'فئة جديدة'
      }
    });
  });

  it('throws a typed error when creating a new category fails', async () => {
    const createCategory = vi.fn().mockRejectedValue(new Error('boom'));

    await expect(
      resolveCategoryId({
        categoriesState: [],
        selectedCategoryId: '',
        formData: {
          title: 'title',
          shortDescription: 'short',
          category: '',
          content: 'content',
          newCategory: 'فئة جديدة'
        },
        createCategory
      })
    ).rejects.toMatchObject({
      code: 'CREATE_NEW_CATEGORY_FAILED'
    });
  });

  it('creates a default category from the chosen category name before falling back to عام', async () => {
    const createCategory = vi.fn().mockResolvedValue({
      id: '5',
      name: 'التوصيات'
    });

    const result = await resolveCategoryId({
      categoriesState: [],
      selectedCategoryId: '',
      formData: {
        title: 'title',
        shortDescription: 'short',
        category: 'التوصيات',
        content: 'content',
        newCategory: '   '
      },
      createCategory
    });

    expect(createCategory).toHaveBeenCalledWith({ name: 'التوصيات' });
    expect(result).toEqual({
      categoryId: '5',
      status: 'default-created',
      category: {
        id: '5',
        name: 'التوصيات'
      }
    });
  });
});
