import { act, renderHook, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';

import type { Category, ContentItem, FormDataState } from '../types/library.types';

const mocks = vi.hoisted(() => ({
  toast: {
    error: vi.fn(),
    success: vi.fn(),
    warning: vi.fn()
  },
  resolveCategoryId: vi.fn(),
  validateSources: vi.fn(),
  createLibraryItem: vi.fn(),
  updateLibraryItem: vi.fn()
}));

vi.mock('sonner', () => ({ toast: mocks.toast }));
vi.mock('../services/libraryService', () => ({
  resolveCategoryId: mocks.resolveCategoryId,
  validateSources: mocks.validateSources,
  createLibraryItem: mocks.createLibraryItem,
  updateLibraryItem: mocks.updateLibraryItem
}));

import { useLibraryItemSubmit } from './useLibraryItemSubmit';

function createStateSetter<T>(initialValue: T) {
  let currentValue = initialValue;
  const setter = vi.fn((nextValue: T | ((prev: T) => T)) => {
    currentValue =
      typeof nextValue === 'function'
        ? (nextValue as (prev: T) => T)(currentValue)
        : nextValue;
    return currentValue;
  });

  return {
    setter,
    getValue: () => currentValue
  };
}

describe('useLibraryItemSubmit', () => {
  const categoriesState: Category[] = [{ id: 'cat-1', name: 'الأمراض' }];
  const baseFormData: FormDataState = {
    title: 'عنوان',
    shortDescription: 'ملخص',
    category: 'الأمراض',
    content: 'محتوى',
    newCategory: ''
  };
  const editingContent: ContentItem = {
    id: 'item-1',
    title: 'قديم',
    shortDescription: 'قديم',
    category: 'الأمراض',
    content: 'نسخة قديمة'
  };

  beforeEach(() => {
    mocks.resolveCategoryId.mockReset();
    mocks.validateSources.mockReset();
    mocks.createLibraryItem.mockReset();
    mocks.updateLibraryItem.mockReset();
    mocks.toast.error.mockReset();
    mocks.toast.success.mockReset();
    mocks.toast.warning.mockReset();
    vi.restoreAllMocks();
  });

  it('reuses an existing category and saves a new item successfully', async () => {
    const setFormDataState = createStateSetter<FormDataState>(baseFormData);
    const setShowNewCategory = createStateSetter(true);
    const setErrorsState = createStateSetter<Record<string, string>>({});
    const onAddContent = vi.fn();

    mocks.resolveCategoryId.mockResolvedValue({
      categoryId: 'cat-1',
      status: 'reused',
      category: { id: 'cat-1', name: 'الأمراض' },
      nextFormData: { ...baseFormData, newCategory: '', category: 'الأمراض' },
      nextShowNewCategory: false
    });
    mocks.validateSources.mockReturnValue({
      filteredSources: ['https://trusted.test'],
      invalidSourceValues: []
    });
    mocks.createLibraryItem.mockResolvedValue({
      contentData: {
        id: 'new-item',
        title: 'عنوان',
        shortDescription: 'ملخص',
        category: 'الأمراض',
        content: 'محتوى'
      }
    });

    const { result } = renderHook(() =>
      useLibraryItemSubmit({
        categoriesState,
        createCategory: vi.fn(),
        refreshCategories: vi.fn(),
        selectedCategoryId: '',
        formData: baseFormData,
        setFormData: setFormDataState.setter,
        setShowNewCategory: setShowNewCategory.setter,
        imageFile: null,
        imagePreview: 'preview://cover.png',
        sources: ['https://trusted.test'],
        setErrors: setErrorsState.setter,
        isEditMode: false,
        onAddContent,
        isValidSecureSourceUrl: (value) => value.startsWith('https://')
      })
    );

    let submitResult: boolean | undefined;
    await act(async () => {
      submitResult = await result.current.submitItem();
    });

    expect(submitResult).toBe(true);
    expect(setFormDataState.setter).toHaveBeenCalled();
    expect(setFormDataState.getValue()).toEqual({
      ...baseFormData,
      newCategory: '',
      category: 'الأمراض'
    });
    expect(setShowNewCategory.setter).toHaveBeenCalledWith(false);
    expect(mocks.createLibraryItem).toHaveBeenCalledWith(
      expect.objectContaining({
        categoryId: 'cat-1',
        filteredSources: ['https://trusted.test']
      })
    );
    expect(onAddContent).toHaveBeenCalledWith(
      expect.objectContaining({
        id: 'new-item'
      })
    );
    expect(mocks.toast.success).toHaveBeenCalledWith('الفئة موجودة مسبقاً وسيتم استخدامها: الأمراض');
    expect(mocks.toast.success).toHaveBeenCalledWith('تم حفظ المحتوى بنجاح');
  });

  it('refreshes categories after creating a new category and tolerates refresh failure', async () => {
    const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
    const refreshCategories = vi.fn().mockRejectedValue(new Error('refresh failed'));

    mocks.resolveCategoryId.mockResolvedValue({
      categoryId: 'cat-2',
      status: 'created',
      category: { id: 'cat-2', name: 'فئة جديدة' }
    });
    mocks.validateSources.mockReturnValue({
      filteredSources: [],
      invalidSourceValues: []
    });
    mocks.createLibraryItem.mockResolvedValue({
      contentData: {
        id: 'new-item',
        title: 'عنوان',
        shortDescription: 'ملخص',
        category: 'فئة جديدة',
        content: 'محتوى'
      }
    });

    const { result } = renderHook(() =>
      useLibraryItemSubmit({
        categoriesState,
        createCategory: vi.fn(),
        refreshCategories,
        selectedCategoryId: '',
        formData: { ...baseFormData, category: '', newCategory: 'فئة جديدة' },
        setFormData: vi.fn(),
        setShowNewCategory: vi.fn(),
        imageFile: null,
        imagePreview: 'preview://cover.png',
        sources: [],
        setErrors: vi.fn(),
        isEditMode: false,
        isValidSecureSourceUrl: (value) => value.startsWith('https://')
      })
    );

    await act(async () => {
      await result.current.submitItem();
    });

    expect(refreshCategories).toHaveBeenCalledTimes(1);
    expect(consoleErrorSpy).toHaveBeenCalledWith(
      'Failed to refresh categories:',
      expect.any(Error)
    );
    expect(mocks.toast.success).toHaveBeenCalledWith('تم إنشاء الفئة الجديدة: فئة جديدة');

    consoleErrorSpy.mockRestore();
  });

  it('refreshes categories after creating the default category', async () => {
    const refreshCategories = vi.fn().mockResolvedValue(categoriesState);

    mocks.resolveCategoryId.mockResolvedValue({
      categoryId: 'cat-default',
      status: 'default-created',
      category: { id: 'cat-default', name: 'عام' }
    });
    mocks.validateSources.mockReturnValue({
      filteredSources: [],
      invalidSourceValues: []
    });
    mocks.createLibraryItem.mockResolvedValue({
      contentData: {
        id: 'new-item',
        title: 'عنوان',
        shortDescription: 'ملخص',
        category: 'عام',
        content: 'محتوى'
      }
    });

    const { result } = renderHook(() =>
      useLibraryItemSubmit({
        categoriesState: [],
        createCategory: vi.fn(),
        refreshCategories,
        selectedCategoryId: '',
        formData: { ...baseFormData, category: '', newCategory: '' },
        setFormData: vi.fn(),
        setShowNewCategory: vi.fn(),
        imageFile: null,
        imagePreview: 'preview://cover.png',
        sources: [],
        setErrors: vi.fn(),
        isEditMode: false,
        isValidSecureSourceUrl: (value) => value.startsWith('https://')
      })
    );

    await act(async () => {
      await result.current.submitItem();
    });

    expect(refreshCategories).toHaveBeenCalledTimes(1);
    expect(mocks.toast.success).toHaveBeenCalledWith('تم إنشاء الفئة: عام');
    expect(mocks.toast.success).toHaveBeenCalledWith('تم حفظ المحتوى بنجاح');
  });

  it('rejects the save when source validation fails', async () => {
    const setErrorsState = createStateSetter<Record<string, string>>({});

    mocks.resolveCategoryId.mockResolvedValue({
      categoryId: 'cat-1',
      status: 'existing'
    });
    mocks.validateSources.mockReturnValue({
      filteredSources: ['http://unsafe.test'],
      invalidSourceValues: ['http://unsafe.test']
    });

    const { result } = renderHook(() =>
      useLibraryItemSubmit({
        categoriesState,
        createCategory: vi.fn(),
        refreshCategories: vi.fn(),
        selectedCategoryId: 'cat-1',
        formData: baseFormData,
        setFormData: vi.fn(),
        setShowNewCategory: vi.fn(),
        imageFile: null,
        imagePreview: 'preview://cover.png',
        sources: ['http://unsafe.test'],
        setErrors: setErrorsState.setter,
        isEditMode: false,
        isValidSecureSourceUrl: (value) => value.startsWith('https://')
      })
    );

    let submitResult: boolean | undefined;
    await act(async () => {
      submitResult = await result.current.submitItem();
    });

    expect(submitResult).toBeUndefined();
    expect(setErrorsState.getValue()).toEqual({
      sources: 'تم رفض الحفظ: جميع المصادر يجب أن تكون روابط https:// صالحة وآمنة.'
    });
    expect(mocks.createLibraryItem).not.toHaveBeenCalled();
    expect(mocks.updateLibraryItem).not.toHaveBeenCalled();
    expect(mocks.toast.error).toHaveBeenCalledWith(
      'بعض الروابط غير آمنة أو غير صالحة. استخدم https:// فقط.'
    );
  });

  it('updates an existing item in edit mode', async () => {
    const onUpdateContent = vi.fn();

    mocks.resolveCategoryId.mockResolvedValue({
      categoryId: 'cat-1',
      status: 'existing'
    });
    mocks.validateSources.mockReturnValue({
      filteredSources: ['https://trusted.test'],
      invalidSourceValues: []
    });
    mocks.updateLibraryItem.mockResolvedValue({
      updatedContent: {
        ...editingContent,
        title: 'نسخة محدثة'
      }
    });

    const { result } = renderHook(() =>
      useLibraryItemSubmit({
        categoriesState,
        createCategory: vi.fn(),
        refreshCategories: vi.fn(),
        selectedCategoryId: 'cat-1',
        formData: { ...baseFormData, title: 'نسخة محدثة' },
        setFormData: vi.fn(),
        setShowNewCategory: vi.fn(),
        imageFile: null,
        imagePreview: 'preview://cover.png',
        sources: ['https://trusted.test'],
        setErrors: vi.fn(),
        isEditMode: true,
        editingContent,
        onUpdateContent,
        isValidSecureSourceUrl: (value) => value.startsWith('https://')
      })
    );

    await act(async () => {
      await result.current.submitItem();
    });

    expect(mocks.updateLibraryItem).toHaveBeenCalledWith(
      expect.objectContaining({
        editingContent,
        categoryId: 'cat-1'
      })
    );
    expect(onUpdateContent).toHaveBeenCalledWith(
      expect.objectContaining({
        title: 'نسخة محدثة'
      })
    );
    expect(mocks.toast.success).toHaveBeenCalledWith('تم تحديث المحتوى بنجاح');
  });

  it('handles service-specific category creation errors', async () => {
    const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

    mocks.resolveCategoryId.mockRejectedValue({
      code: 'CREATE_NEW_CATEGORY_FAILED'
    });

    const { result } = renderHook(() =>
      useLibraryItemSubmit({
        categoriesState,
        createCategory: vi.fn(),
        refreshCategories: vi.fn(),
        selectedCategoryId: '',
        formData: baseFormData,
        setFormData: vi.fn(),
        setShowNewCategory: vi.fn(),
        imageFile: null,
        imagePreview: 'preview://cover.png',
        sources: [],
        setErrors: vi.fn(),
        isEditMode: false,
        isValidSecureSourceUrl: (value) => value.startsWith('https://')
      })
    );

    await expect(result.current.submitItem()).resolves.toBe(false);
    expect(mocks.toast.error).toHaveBeenCalledWith('فشل في إنشاء الفئة الجديدة');
    expect(consoleErrorSpy).toHaveBeenCalledWith(
      'Failed to create category:',
      expect.objectContaining({ code: 'CREATE_NEW_CATEGORY_FAILED' })
    );

    consoleErrorSpy.mockRestore();
  });

  it('resets saving state when an unexpected save error occurs', async () => {
    const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

    mocks.resolveCategoryId.mockResolvedValue({
      categoryId: 'cat-1',
      status: 'existing'
    });
    mocks.validateSources.mockReturnValue({
      filteredSources: [],
      invalidSourceValues: []
    });
    mocks.createLibraryItem.mockRejectedValue(new Error('db unavailable'));

    const { result } = renderHook(() =>
      useLibraryItemSubmit({
        categoriesState,
        createCategory: vi.fn(),
        refreshCategories: vi.fn(),
        selectedCategoryId: 'cat-1',
        formData: baseFormData,
        setFormData: vi.fn(),
        setShowNewCategory: vi.fn(),
        imageFile: null,
        imagePreview: 'preview://cover.png',
        sources: [],
        setErrors: vi.fn(),
        isEditMode: false,
        isValidSecureSourceUrl: (value) => value.startsWith('https://')
      })
    );

    expect(result.current.isSaving).toBe(false);

    let submitResult: boolean | undefined;
    await act(async () => {
      submitResult = await result.current.submitItem();
    });

    expect(submitResult).toBe(false);
    await waitFor(() => {
      expect(result.current.isSaving).toBe(false);
    });
    expect(mocks.toast.error).toHaveBeenCalledWith('حدث خطأ أثناء حفظ المحتوى');
    expect(consoleErrorSpy).toHaveBeenCalledWith(expect.any(Error));

    consoleErrorSpy.mockRestore();
  });

  it('handles default-category creation errors', async () => {
    const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

    mocks.resolveCategoryId.mockRejectedValue({
      code: 'CREATE_DEFAULT_CATEGORY_FAILED'
    });

    const { result } = renderHook(() =>
      useLibraryItemSubmit({
        categoriesState: [],
        createCategory: vi.fn(),
        refreshCategories: vi.fn(),
        selectedCategoryId: '',
        formData: { ...baseFormData, category: '', newCategory: '' },
        setFormData: vi.fn(),
        setShowNewCategory: vi.fn(),
        imageFile: null,
        imagePreview: 'preview://cover.png',
        sources: [],
        setErrors: vi.fn(),
        isEditMode: false,
        isValidSecureSourceUrl: (value) => value.startsWith('https://')
      })
    );

    await expect(result.current.submitItem()).resolves.toBe(false);
    expect(mocks.toast.error).toHaveBeenCalledWith('فشل في إنشاء الفئة الافتراضية');
    expect(consoleErrorSpy).toHaveBeenCalledWith(
      'Failed to create default category:',
      expect.objectContaining({ code: 'CREATE_DEFAULT_CATEGORY_FAILED' })
    );

    consoleErrorSpy.mockRestore();
  });
});
