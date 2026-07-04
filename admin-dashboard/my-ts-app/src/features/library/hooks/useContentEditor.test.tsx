import { act, renderHook } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { Category, ContentItem } from '../types/library.types';
import { useContentEditor } from './useContentEditor';

const mocks = vi.hoisted(() => ({
  toast: {
    error: vi.fn(),
    success: vi.fn(),
    warning: vi.fn()
  },
  mockCategoriesState: [] as Category[],
  mockIsCreatingCategory: false,
  mockCreateCategory: vi.fn(),
  mockRefreshCategories: vi.fn(),
  mockSubmitItem: vi.fn(),
  mockIsSaving: false,
  triggerLoadErrorOnUse: false
}));

vi.mock('sonner', () => ({ toast: mocks.toast }));

vi.mock('./useLibraryCategories', () => ({
  useLibraryCategories: ({ onLoadError }: { onLoadError: () => void }) => {
    if (mocks.triggerLoadErrorOnUse) {
      onLoadError();
    }

    return {
      categoriesState: mocks.mockCategoriesState,
      isCreatingCategory: mocks.mockIsCreatingCategory,
      createCategory: mocks.mockCreateCategory,
      refreshCategories: mocks.mockRefreshCategories
    };
  }
}));

vi.mock('./useLibraryItemSubmit', () => ({
  useLibraryItemSubmit: () => ({
    submitItem: mocks.mockSubmitItem,
    isSaving: mocks.mockIsSaving
  })
}));

const editingContent: ContentItem = {
  id: 'content-1',
  title: 'مقال قديم',
  shortDescription: 'وصف مختصر',
  category: 'الأمراض',
  content: 'محتوى المقال',
  image: 'https://example.com/image.png',
  sources: ['https://example.com/source'],
};

describe('useContentEditor', () => {
  beforeEach(() => {
    mocks.mockCategoriesState = [{ id: 'cat-1', name: 'الأمراض' }];
    mocks.mockIsCreatingCategory = false;
    mocks.mockIsSaving = false;
    mocks.triggerLoadErrorOnUse = false;
    mocks.mockCreateCategory.mockReset();
    mocks.mockRefreshCategories.mockReset();
    mocks.mockSubmitItem.mockReset();
    mocks.mockSubmitItem.mockResolvedValue(true);
    mocks.toast.error.mockReset();
    mocks.toast.success.mockReset();
    mocks.toast.warning.mockReset();
    vi.restoreAllMocks();
  });

  it('returns validation errors and skips submit when required fields are missing', async () => {
    const { result } = renderHook(() => useContentEditor({}));

    let saveResult: boolean | undefined;
    await act(async () => {
      saveResult = await result.current.handleSave();
    });

    expect(saveResult).toBe(false);
    expect(mocks.mockSubmitItem).not.toHaveBeenCalled();
    expect(result.current.errors.title).toBe('هذا الحقل مطلوب');
    expect(result.current.errors.shortDescription).toBe('هذا الحقل مطلوب');
    expect(result.current.errors.content).toBe('يرجى إدخال محتوى المقال');
    expect(result.current.errors.image).toBe('الصورة مطلوبة');
  });

  it('tracks unsaved changes and opens leave dialog on cancel after editing', () => {
    const { result } = renderHook(() =>
      useContentEditor({
        editingContent
      })
    );

    expect(result.current.hasUnsavedChanges).toBe(false);

    act(() => {
      result.current.updateForm({ title: 'عنوان جديد' });
    });

    expect(result.current.hasUnsavedChanges).toBe(true);

    let canLeave: boolean | undefined;
    act(() => {
      canLeave = result.current.handleCancel();
    });

    expect(canLeave).toBe(false);
    expect(result.current.isLeaveDialogOpen).toBe(true);
  });

  it('does not append a second blank source and clears source errors on source update', () => {
    const { result } = renderHook(() => useContentEditor({}));

    expect(result.current.sources).toEqual(['']);

    act(() => {
      result.current.addSource();
    });

    expect(result.current.sources).toEqual(['']);

    act(() => {
      result.current.setErrors({ sources: 'رابط غير صالح' });
    });

    act(() => {
      result.current.updateSource(0, 'https://example.com/source');
    });

    expect(result.current.sources).toEqual(['https://example.com/source']);
    expect(result.current.errors.sources).toBeUndefined();
  });

  it('creates a new category and syncs form state on success', async () => {
    mocks.mockCreateCategory.mockResolvedValue({
      id: 'cat-2',
      name: 'فئة جديدة'
    });

    const { result } = renderHook(() => useContentEditor({}));

    act(() => {
      result.current.setShowNewCategory(true);
      result.current.updateForm({ newCategory: 'فئة جديدة' });
    });

    await act(async () => {
      await result.current.handleCreateCategoryNow();
    });

    expect(mocks.mockCreateCategory).toHaveBeenCalledWith({ name: 'فئة جديدة' });
    expect(result.current.formData.category).toBe('فئة جديدة');
    expect(result.current.formData.newCategory).toBe('');
    expect(result.current.showNewCategory).toBe(false);
    expect(mocks.toast.success).toHaveBeenCalledWith('تم إنشاء الفئة الجديدة: فئة جديدة');
  });

  it('submits successfully when form is already valid in edit mode', async () => {
    const onUpdateContent = vi.fn();
    const { result } = renderHook(() =>
      useContentEditor({
        editingContent,
        onUpdateContent
      })
    );

    expect(result.current.canSave).toBe(true);

    let saveResult: boolean | undefined;
    await act(async () => {
      saveResult = await result.current.handleSave();
    });

    expect(saveResult).toBe(true);
    expect(mocks.mockSubmitItem).toHaveBeenCalledTimes(1);
  });

  it('shows a toast when category loading fails', () => {
    mocks.triggerLoadErrorOnUse = true;

    renderHook(() => useContentEditor({}));

    expect(mocks.toast.error).toHaveBeenCalledWith(
      'تعذّر تحميل قائمة الفئات، يمكنك إنشاء فئة جديدة أو إعادة المحاولة لاحقًا'
    );
  });

  it('prevents creating a blank or duplicate category name', async () => {
    const { result, rerender } = renderHook(() => useContentEditor({}));

    await act(async () => {
      await result.current.handleCreateCategoryNow();
    });

    expect(result.current.newCategoryError).toBe('يرجى إدخال اسم الفئة');

    act(() => {
      result.current.updateForm({ newCategory: ' الأمراض ' });
    });

    rerender();

    await act(async () => {
      await result.current.handleCreateCategoryNow();
    });

    expect(result.current.newCategoryError).toBe('الفئة موجودة بالفعل');
    expect(mocks.mockCreateCategory).not.toHaveBeenCalled();
  });

  it('surfaces category creation failures', async () => {
    mocks.mockCreateCategory.mockRejectedValue(new Error('boom'));
    const { result } = renderHook(() => useContentEditor({}));

    act(() => {
      result.current.updateForm({ newCategory: 'فئة جديدة' });
    });

    await act(async () => {
      await result.current.handleCreateCategoryNow();
    });

    expect(result.current.newCategoryError).toBe('فشل في إنشاء الفئة الجديدة');
    expect(mocks.toast.error).toHaveBeenCalledWith('فشل في إنشاء الفئة الجديدة');
  });

  it('validates invalid sources and missing selected category when saving a new category', async () => {
    mocks.mockCategoriesState = [];
    const { result } = renderHook(() => useContentEditor({}));

    act(() => {
      result.current.updateForm({
        title: 'عنوان',
        shortDescription: 'ملخص',
        content: 'محتوى',
        newCategory: 'فئة جديدة'
      });
      result.current.setShowNewCategory(true);
      result.current.setErrors({});
      result.current.setSources(['http://unsafe.test']);
    });

    let saveResult: boolean | undefined;
    await act(async () => {
      saveResult = await result.current.handleSave();
    });

    expect(saveResult).toBe(false);
    expect(result.current.errors.sources).toBe(
      'يوجد روابط غير صالحة. استخدم https:// فقط وتجنب الروابط غير الآمنة.'
    );
    expect(result.current.errors.category).toBe('يجب إنشاء الفئة الجديدة أو اختيار واحدة');
    expect(mocks.mockSubmitItem).not.toHaveBeenCalled();
  });

  it('returns true on cancel when there are no unsaved changes', () => {
    const { result } = renderHook(() =>
      useContentEditor({
        editingContent
      })
    );

    let canLeave: boolean | undefined;
    act(() => {
      canLeave = result.current.handleCancel();
    });

    expect(canLeave).toBe(true);
    expect(result.current.isLeaveDialogOpen).toBe(false);
  });

  it('warns the browser before unloading when there are unsaved changes', () => {
    const { result } = renderHook(() =>
      useContentEditor({
        editingContent
      })
    );

    act(() => {
      result.current.updateForm({ title: 'عنوان مختلف' });
    });

    const event = new Event('beforeunload', { cancelable: true });
    Object.defineProperty(event, 'returnValue', {
      configurable: true,
      writable: true,
      value: undefined
    });

    window.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(true);
    expect((event as unknown as { returnValue: string }).returnValue).toBe('');
  });

  it('handles image upload validation and successful preview generation', async () => {
    const readAsDataURL = vi.fn();
    class MockFileReader {
      result = 'data:image/png;base64,preview';
      onload: null | (() => void) = null;

      readAsDataURL(file: File) {
        readAsDataURL(file);
        this.onload?.();
      }
    }

    vi.stubGlobal('FileReader', MockFileReader as unknown as typeof FileReader);

    const { result } = renderHook(() => useContentEditor({}));

    const oversizedFile = new File(['a'], 'big.png', { type: 'image/png' });
    Object.defineProperty(oversizedFile, 'size', { value: 6 * 1024 * 1024 });
    act(() => {
      result.current.handleImageUpload({
        target: { files: [oversizedFile] }
      } as unknown as React.ChangeEvent<HTMLInputElement>);
    });
    expect(mocks.toast.error).toHaveBeenCalledWith('حجم الصورة يجب أن يكون أقل من 5 ميجابايت');

    const invalidTypeFile = new File(['a'], 'doc.txt', { type: 'text/plain' });
    act(() => {
      result.current.handleImageUpload({
        target: { files: [invalidTypeFile] }
      } as unknown as React.ChangeEvent<HTMLInputElement>);
    });
    expect(mocks.toast.error).toHaveBeenCalledWith('يرجى اختيار ملف صورة صحيح');

    const validImage = new File(['img'], 'small.png', { type: 'image/png' });
    act(() => {
      result.current.handleImageUpload({
        target: { files: [validImage] }
      } as unknown as React.ChangeEvent<HTMLInputElement>);
    });

    expect(readAsDataURL).toHaveBeenCalledWith(validImage);
    expect(result.current.imagePreview).toBe('data:image/png;base64,preview');

    vi.unstubAllGlobals();
  });

  it('ignores image uploads when no file is selected', () => {
    const { result } = renderHook(() => useContentEditor({}));

    act(() => {
      result.current.handleImageUpload({
        target: { files: [] }
      } as unknown as React.ChangeEvent<HTMLInputElement>);
    });

    expect(result.current.imagePreview).toBe('');
    expect(mocks.toast.error).not.toHaveBeenCalled();
  });

  it('removes the current image and clears the file input element', () => {
    const { result } = renderHook(() =>
      useContentEditor({
        editingContent
      })
    );

    const input = document.createElement('input');
    input.value = 'C:\\fakepath\\image.png';
    result.current.fileInputRef.current = input;

    act(() => {
      result.current.removeImage();
    });

    expect(result.current.imagePreview).toBe('');
    expect(result.current.fileInputRef.current?.value).toBe('');
  });

  it('adds a new blank source when the last source is already filled', () => {
    const { result } = renderHook(() => useContentEditor({}));

    act(() => {
      result.current.setSources(['https://trusted.test']);
    });

    act(() => {
      result.current.addSource();
    });

    expect(result.current.sources).toEqual(['https://trusted.test', '']);
  });

  it('removes sources only when there is more than one', () => {
    const { result } = renderHook(() => useContentEditor({}));

    act(() => {
      result.current.setSources(['https://one.test', 'https://two.test']);
    });

    act(() => {
      result.current.removeSource(0);
    });

    expect(result.current.sources).toEqual(['https://two.test']);

    act(() => {
      result.current.removeSource(0);
    });

    expect(result.current.sources).toEqual(['https://two.test']);
  });

  it('applies markdown formatting to the selected content', () => {
    const rafSpy = vi
      .spyOn(window, 'requestAnimationFrame')
      .mockImplementation((callback: FrameRequestCallback) => {
        callback(0);
        return 0;
      });
    const { result } = renderHook(() =>
      useContentEditor({
        editingContent: {
          ...editingContent,
          content: 'نص'
        }
      })
    );

    const textarea = document.createElement('textarea');
    textarea.value = 'نص';
    textarea.selectionStart = 0;
    textarea.selectionEnd = 2;
    const selectionSpy = vi.spyOn(textarea, 'setSelectionRange');
    const focusSpy = vi.spyOn(textarea, 'focus').mockImplementation(() => {});
    result.current.contentRef.current = textarea;

    act(() => {
      result.current.insertFormatting('bold');
    });

    expect(result.current.formData.content).toBe('**نص**');
    expect(selectionSpy).toHaveBeenCalledWith(6, 6);
    expect(focusSpy).toHaveBeenCalledTimes(1);

    focusSpy.mockRestore();
    rafSpy.mockRestore();
  });

  it('returns early when formatting is requested without a textarea ref', () => {
    const { result } = renderHook(() =>
      useContentEditor({
        editingContent
      })
    );

    act(() => {
      result.current.insertFormatting('bold');
    });

    expect(result.current.formData.content).toBe(editingContent.content);
  });

  it.each([
    ['list', '\n- بند\n'],
    ['numberedList', '\n1. بند\n']
  ])('keeps the cursor shift at zero for selected text with %s formatting', (format, expectedContent) => {
    const rafSpy = vi
      .spyOn(window, 'requestAnimationFrame')
      .mockImplementation((callback: FrameRequestCallback) => {
        callback(0);
        return 0;
      });
    const { result } = renderHook(() =>
      useContentEditor({
        editingContent: {
          ...editingContent,
          content: 'بند'
        }
      })
    );

    const textarea = document.createElement('textarea');
    textarea.value = 'بند';
    textarea.selectionStart = 0;
    textarea.selectionEnd = 3;
    const selectionSpy = vi.spyOn(textarea, 'setSelectionRange');
    result.current.contentRef.current = textarea;

    act(() => {
      result.current.insertFormatting(format);
    });

    expect(result.current.formData.content).toBe(expectedContent);
    expect(selectionSpy).toHaveBeenCalledWith(expectedContent.length, expectedContent.length);

    rafSpy.mockRestore();
  });

  it.each([
    ['italic', '*نص مائل*'],
    ['mainHeading', '\n# عنوان رئيسي\n'],
    ['heading', '\n## عنوان فرعي\n'],
    ['list', '\n- عنصر\n'],
    ['numberedList', '\n1. عنصر\n']
  ])('applies %s formatting when no text is selected', (format, expectedContent) => {
    const rafSpy = vi
      .spyOn(window, 'requestAnimationFrame')
      .mockImplementation((callback: FrameRequestCallback) => {
        callback(0);
        return 0;
      });
    const { result } = renderHook(() => useContentEditor({}));

    const textarea = document.createElement('textarea');
    textarea.value = '';
    textarea.selectionStart = 0;
    textarea.selectionEnd = 0;
    result.current.contentRef.current = textarea;

    act(() => {
      result.current.insertFormatting(format);
    });

    expect(result.current.formData.content).toBe(expectedContent);

    rafSpy.mockRestore();
  });
});
