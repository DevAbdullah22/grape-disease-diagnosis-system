import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
  createCategory: vi.fn(),
  createItem: vi.fn(),
  updateItem: vi.fn(),
  mapCreateItemResponseToContentItem: vi.fn(),
  mapUpdateItemResponseToContentItem: vi.fn()
}));

vi.mock('../api/libraryApi', () => ({
  createCategory: mocks.createCategory,
  createItem: mocks.createItem,
  updateItem: mocks.updateItem
}));

vi.mock('../mappers/libraryMapper', () => ({
  mapCreateItemResponseToContentItem: mocks.mapCreateItemResponseToContentItem,
  mapUpdateItemResponseToContentItem: mocks.mapUpdateItemResponseToContentItem
}));

import {
  createLibraryItem,
  resolveCategoryId,
  updateLibraryItem
} from './libraryService';

describe('libraryService mutations', () => {
  beforeEach(() => {
    mocks.createCategory.mockReset();
    mocks.createItem.mockReset();
    mocks.updateItem.mockReset();
    mocks.mapCreateItemResponseToContentItem.mockReset();
    mocks.mapUpdateItemResponseToContentItem.mockReset();
  });

  it('resolves an existing category id from the selected category name', async () => {
    const result = await resolveCategoryId({
      categoriesState: [
        { id: 'cat-1', name: 'الأمراض' },
        { id: 'cat-2', name: 'الوقاية' }
      ],
      selectedCategoryId: '',
      formData: {
        title: 'title',
        shortDescription: 'short',
        category: 'الوقاية',
        content: 'content',
        newCategory: ''
      }
    });

    expect(result).toEqual({
      categoryId: 'cat-2',
      status: 'existing'
    });
  });

  it('falls back to the first category when no selection is provided', async () => {
    const result = await resolveCategoryId({
      categoriesState: [{ id: 'cat-1', name: 'الأمراض' }],
      selectedCategoryId: '',
      formData: {
        title: 'title',
        shortDescription: 'short',
        category: '',
        content: 'content',
        newCategory: ''
      }
    });

    expect(result).toEqual({
      categoryId: 'cat-1',
      status: 'existing'
    });
  });

  it('creates a default category when no categories exist yet', async () => {
    mocks.createCategory.mockResolvedValue({
      id: 'cat-default',
      name: 'عام'
    });

    const result = await resolveCategoryId({
      categoriesState: [],
      selectedCategoryId: '',
      formData: {
        title: 'title',
        shortDescription: 'short',
        category: '',
        content: 'content',
        newCategory: ''
      }
    });

    expect(mocks.createCategory).toHaveBeenCalledWith({ name: 'عام' });
    expect(result).toEqual({
      categoryId: 'cat-default',
      status: 'default-created',
      category: {
        id: 'cat-default',
        name: 'عام'
      }
    });
  });

  it('throws a typed error when creating the default category fails', async () => {
    mocks.createCategory.mockRejectedValue(new Error('fallback failed'));

    await expect(
      resolveCategoryId({
        categoriesState: [],
        selectedCategoryId: '',
        formData: {
          title: 'title',
          shortDescription: 'short',
          category: '',
          content: 'content',
          newCategory: ''
        }
      })
    ).rejects.toMatchObject({
      code: 'CREATE_DEFAULT_CATEGORY_FAILED'
    });
  });

  it('creates a library item with the expected form-data payload and mapper call', async () => {
    const imageFile = new File(['image'], 'cover.png', { type: 'image/png' });
    const serverItem = { id: 'server-item' };
    const mappedItem = { id: 'mapped-item', title: 'عنوان', content: 'Body', category: 'الأمراض' };

    mocks.createItem.mockImplementation(async (data: FormData) => {
      expect(data.get('Title')).toBe('عنوان');
      expect(data.get('ShortDescription')).toBe('ملخص');
      expect(data.get('Content')).toBe('Body');
      expect(data.get('CategoryId')).toBe('cat-1');
      expect(data.get('Sources')).toBe('https://one.test,https://two.test');
      expect(data.get('Image')).toBe(imageFile);
      return serverItem;
    });
    mocks.mapCreateItemResponseToContentItem.mockReturnValue(mappedItem);

    const result = await createLibraryItem({
      formData: {
        title: 'عنوان',
        shortDescription: 'ملخص',
        category: 'الأمراض',
        content: 'Body',
        newCategory: ''
      },
      categoryId: 'cat-1',
      filteredSources: ['https://one.test', 'https://two.test'],
      imageFile,
      imagePreview: 'preview://cover.png'
    });

    expect(mocks.mapCreateItemResponseToContentItem).toHaveBeenCalledWith(
      serverItem,
      {
        title: 'عنوان',
        shortDescription: 'ملخص',
        category: 'الأمراض',
        content: 'Body',
        newCategory: ''
      },
      'preview://cover.png',
      ['https://one.test', 'https://two.test']
    );
    expect(result).toEqual({
      contentData: mappedItem
    });
  });

  it('updates a library item with the expected payload and mapper call', async () => {
    const imageFile = new File(['image'], 'updated.png', { type: 'image/png' });
    const serverItem = { id: 'server-updated' };
    const editingContent = {
      id: 'content-1',
      title: 'نسخة قديمة',
      shortDescription: 'قديم',
      category: 'الأمراض',
      content: 'old body'
    };
    const mappedItem = { ...editingContent, title: 'نسخة جديدة' };

    mocks.updateItem.mockImplementation(async (id: string, data: FormData) => {
      expect(id).toBe('content-1');
      expect(data.get('Title')).toBe('نسخة جديدة');
      expect(data.get('CategoryId')).toBe('cat-1');
      expect(data.get('Sources')).toBe('https://trusted.test');
      expect(data.get('Image')).toBe(imageFile);
      return serverItem;
    });
    mocks.mapUpdateItemResponseToContentItem.mockReturnValue(mappedItem);

    const result = await updateLibraryItem({
      editingContent,
      formData: {
        title: 'نسخة جديدة',
        shortDescription: 'محدث',
        category: 'الأمراض',
        content: 'new body',
        newCategory: ''
      },
      categoryId: 'cat-1',
      filteredSources: ['https://trusted.test'],
      imageFile,
      imagePreview: 'preview://updated.png'
    });

    expect(mocks.mapUpdateItemResponseToContentItem).toHaveBeenCalledWith(
      serverItem,
      editingContent,
      {
        title: 'نسخة جديدة',
        shortDescription: 'محدث',
        category: 'الأمراض',
        content: 'new body',
        newCategory: ''
      },
      'preview://updated.png',
      ['https://trusted.test']
    );
    expect(result).toEqual({
      updatedContent: mappedItem
    });
  });

  it('omits optional image and sources fields when creating an item without them', async () => {
    const serverItem = { id: 'server-item-2' };
    const mappedItem = { id: 'mapped-item-2', title: 'عنوان', content: 'Body', category: 'الأمراض' };

    mocks.createItem.mockImplementation(async (data: FormData) => {
      expect(data.get('Title')).toBe('عنوان');
      expect(data.get('ShortDescription')).toBe('ملخص');
      expect(data.get('Content')).toBe('Body');
      expect(data.get('CategoryId')).toBe('cat-1');
      expect(data.has('Sources')).toBe(false);
      expect(data.has('Image')).toBe(false);
      return serverItem;
    });
    mocks.mapCreateItemResponseToContentItem.mockReturnValue(mappedItem);

    const result = await createLibraryItem({
      formData: {
        title: 'عنوان',
        shortDescription: 'ملخص',
        category: 'الأمراض',
        content: 'Body',
        newCategory: ''
      },
      categoryId: 'cat-1',
      filteredSources: [],
      imageFile: null,
      imagePreview: ''
    });

    expect(result).toEqual({
      contentData: mappedItem
    });
  });

  it('stringifies numeric item ids before updating', async () => {
    mocks.updateItem.mockResolvedValue({ id: 'server-updated-2' });
    mocks.mapUpdateItemResponseToContentItem.mockReturnValue({
      id: 7,
      title: 'نسخة جديدة',
      content: 'new body',
      category: 'الأمراض'
    });

    await updateLibraryItem({
      editingContent: {
        id: 7,
        title: 'نسخة قديمة',
        shortDescription: 'قديم',
        category: 'الأمراض',
        content: 'old body'
      },
      formData: {
        title: 'نسخة جديدة',
        shortDescription: 'محدث',
        category: 'الأمراض',
        content: 'new body',
        newCategory: ''
      },
      categoryId: 'cat-1',
      filteredSources: [],
      imageFile: null,
      imagePreview: ''
    });

    expect(mocks.updateItem).toHaveBeenCalledWith('7', expect.any(FormData));
  });
});
