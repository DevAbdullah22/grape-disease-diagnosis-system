import { describe, expect, it, vi } from 'vitest';
import {
  mapCreateItemResponseToContentItem,
  mapUpdateItemResponseToContentItem
} from './libraryMapper';

describe('libraryMapper', () => {
  it('maps create response values with fallbacks from form data', () => {
    const result = mapCreateItemResponseToContentItem(
      {
        id: 'new-id',
        title: 'عنوان من الخادم',
        content: 'محتوى من الخادم',
        categoryName: 'الأمراض',
        imageUrl: '/img.png',
        sources: 'https://a.test,https://b.test'
      },
      {
        title: 'عنوان محلي',
        shortDescription: 'وصف',
        category: '',
        content: 'محتوى محلي',
        newCategory: 'فئة جديدة'
      },
      'preview-image',
      ['https://fallback.test']
    );

    expect(result).toEqual({
      id: 'new-id',
      title: 'عنوان من الخادم',
      shortDescription: 'وصف',
      category: 'الأمراض',
      type: 'مقال',
      content: 'محتوى من الخادم',
      image: '/img.png',
      sources: ['https://a.test', 'https://b.test']
    });
  });

  it('maps update response while preserving editing content id', () => {
    const result = mapUpdateItemResponseToContentItem(
      {
        title: 'عنوان محدّث',
        shortDescription: 'وصف من الخادم',
        categoryName: 'الوقاية',
        content: 'محتوى جديد'
      },
      {
        id: 'edit-1',
        title: 'قديم',
        content: 'قديم',
        category: 'قديمة'
      },
      {
        title: 'عنوان محلي',
        shortDescription: 'وصف محلي',
        category: 'فئة محلية',
        content: 'محتوى محلي',
        newCategory: ''
      },
      'preview-image',
      ['https://fallback.test']
    );

    expect(result).toEqual({
      id: 'edit-1',
      title: 'عنوان محدّث',
      shortDescription: 'وصف من الخادم',
      category: 'الوقاية',
      type: 'مقال',
      content: 'محتوى جديد',
      image: 'preview-image',
      sources: ['https://fallback.test']
    });
  });

  it('falls back to local values when the create response is mostly empty', () => {
    const nowSpy = vi.spyOn(Date, 'now').mockReturnValue(12345);

    const result = mapCreateItemResponseToContentItem(
      {
        sources: null
      },
      {
        title: 'عنوان محلي',
        shortDescription: 'وصف محلي',
        category: 'فئة محلية',
        content: 'محتوى محلي',
        newCategory: '  فئة جديدة  '
      },
      'preview-image',
      ['https://fallback.test']
    );

    expect(result).toEqual({
      id: 12345,
      title: 'عنوان محلي',
      shortDescription: 'وصف محلي',
      category: 'فئة جديدة',
      type: 'مقال',
      content: 'محتوى محلي',
      image: 'preview-image',
      sources: ['https://fallback.test']
    });

    nowSpy.mockRestore();
  });

  it('falls back to edit form values when the update response omits optional fields', () => {
    const result = mapUpdateItemResponseToContentItem(
      {
        title: '',
        shortDescription: '',
        categoryName: '',
        content: '',
        imageUrl: null,
        sources: null
      },
      {
        id: 'edit-2',
        title: 'عنوان قديم',
        shortDescription: 'وصف قديم',
        category: 'فئة قديمة',
        content: 'محتوى قديم'
      },
      {
        title: 'عنوان من النموذج',
        shortDescription: 'وصف من النموذج',
        category: 'فئة من النموذج',
        content: 'محتوى من النموذج',
        newCategory: ''
      },
      'preview-image',
      ['https://fallback.test']
    );

    expect(result).toEqual({
      id: 'edit-2',
      title: 'عنوان من النموذج',
      shortDescription: 'وصف من النموذج',
      category: 'فئة من النموذج',
      type: 'مقال',
      content: 'محتوى من النموذج',
      image: 'preview-image',
      sources: ['https://fallback.test']
    });
  });
});
