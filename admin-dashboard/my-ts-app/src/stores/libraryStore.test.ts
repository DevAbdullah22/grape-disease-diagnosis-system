import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
  toast: {
    error: vi.fn(),
    success: vi.fn(),
    warning: vi.fn()
  },
  getCategories: vi.fn(),
  getItemsByCategory: vi.fn(),
  deleteItem: vi.fn(),
  resolveImageUrl: vi.fn((path?: string | null) =>
    path ? `resolved:${path}` : undefined
  ),
  createCategory: vi.fn(),
  updateCategory: vi.fn(),
  deleteCategory: vi.fn(),
  getCategoryDeleteInfo: vi.fn()
}));

vi.mock('sonner', () => ({ toast: mocks.toast }));
vi.mock('../features/library/api/libraryApi', () => ({
  getCategories: mocks.getCategories,
  getItemsByCategory: mocks.getItemsByCategory,
  deleteItem: mocks.deleteItem,
  resolveImageUrl: mocks.resolveImageUrl,
  createCategory: mocks.createCategory,
  updateCategory: mocks.updateCategory,
  deleteCategory: mocks.deleteCategory,
  getCategoryDeleteInfo: mocks.getCategoryDeleteInfo
}));

import { useLibraryStore } from './libraryStore';

describe('useLibraryStore', () => {
  beforeEach(() => {
    useLibraryStore.setState(useLibraryStore.getInitialState(), true);

    mocks.getCategories.mockReset();
    mocks.getItemsByCategory.mockReset();
    mocks.deleteItem.mockReset();
    mocks.resolveImageUrl.mockClear();
    mocks.createCategory.mockReset();
    mocks.updateCategory.mockReset();
    mocks.deleteCategory.mockReset();
    mocks.getCategoryDeleteInfo.mockReset();
    mocks.toast.error.mockReset();
    mocks.toast.success.mockReset();
    mocks.toast.warning.mockReset();
  });

  it('loadInitialData maps items, resolves image urls, and sorts by latest date first', async () => {
    mocks.getCategories.mockResolvedValue([
      { id: 'cat-1', name: 'الأمراض' },
      { id: 'cat-2', name: 'الوقاية' }
    ]);
    mocks.getItemsByCategory.mockImplementation(async (categoryId: string) => {
      if (categoryId === 'cat-1') {
        return [
          {
            id: '1',
            title: 'أقدم عنصر',
            content: 'محتوى',
            categoryId: 'cat-1',
            imageUrl: '/old.png',
            sources: 'https://a.test,https://b.test',
            createdAt: '2024-01-01T00:00:00Z'
          }
        ];
      }

      return [
        {
          id: '2',
          title: 'أحدث عنصر',
          content: 'محتوى',
          categoryId: 'cat-2',
          imageUrl: '/new.png',
          sources: null,
          createdAt: '2024-05-01T00:00:00Z'
        }
      ];
    });

    await useLibraryStore.getState().loadInitialData();

    const state = useLibraryStore.getState();
    expect(state.categories).toEqual([
      { id: 'cat-1', name: 'الأمراض' },
      { id: 'cat-2', name: 'الوقاية' }
    ]);
    expect(state.contents.map((item) => item.title)).toEqual(['أحدث عنصر', 'أقدم عنصر']);
    expect(state.contents[1].category).toBe('الأمراض');
    expect(state.contents[1].image).toBe('resolved:/old.png');
    expect(state.contents[1].sources).toEqual(['https://a.test', 'https://b.test']);
    expect(state.isLoadingCategories).toBe(false);
    expect(state.isLoadingItems).toBe(false);
  });

  it('setSelectedCategory dispatches the matching loader based on selected filter', () => {
    const loadAllItems = vi.fn(async () => {});
    const loadItemsForCategory = vi.fn(async () => {});

    useLibraryStore.setState({
      categories: [{ id: 'cat-1', name: 'الأمراض' }],
      loadAllItems,
      loadItemsForCategory
    });

    useLibraryStore.getState().setSelectedCategory('الكل');
    expect(loadAllItems).toHaveBeenCalledTimes(1);

    useLibraryStore.getState().setSelectedCategory('الأمراض');
    expect(loadItemsForCategory).toHaveBeenCalledWith('cat-1');
  });

  it('setSelectedCategory does not load items when the selected category is unknown', () => {
    const loadAllItems = vi.fn(async () => {});
    const loadItemsForCategory = vi.fn(async () => {});

    useLibraryStore.setState({
      categories: [{ id: 'cat-1', name: 'الأمراض' }],
      loadAllItems,
      loadItemsForCategory
    });

    useLibraryStore.getState().setSelectedCategory('غير موجودة');

    expect(loadAllItems).not.toHaveBeenCalled();
    expect(loadItemsForCategory).not.toHaveBeenCalled();
  });

  it('deleteContent removes the item and clears pending delete state on success', async () => {
    mocks.deleteItem.mockResolvedValue(undefined);

    useLibraryStore.setState({
      contents: [
        { id: '1', title: 'A', content: 'x', category: 'الأمراض' },
        { id: '2', title: 'B', content: 'y', category: 'الوقاية' }
      ],
      contentToDelete: { id: '1', title: 'A', content: 'x', category: 'الأمراض' }
    });

    await useLibraryStore.getState().deleteContent('1');

    const state = useLibraryStore.getState();
    expect(state.contents.map((item) => item.id)).toEqual(['2']);
    expect(state.contentToDelete).toBeNull();
    expect(state.isDeleting).toBeNull();
    expect(mocks.toast.success).toHaveBeenCalledWith('تم حذف العنصر');
  });

  it('saveCategory shows backend message when update fails', async () => {
    mocks.updateCategory.mockRejectedValue({
      response: {
        data: {
          message: 'اسم الفئة مستخدم مسبقاً'
        }
      }
    });

    useLibraryStore.setState({
      categoryNameInput: 'فئة مكررة',
      editingCategoryId: 'cat-9'
    });

    await useLibraryStore.getState().saveCategory();

    expect(mocks.updateCategory).toHaveBeenCalledWith({
      id: 'cat-9',
      name: 'فئة مكررة'
    });
    expect(mocks.toast.error).toHaveBeenCalledWith('اسم الفئة مستخدم مسبقاً');
  });

  it('saveCategory updates an existing category successfully', async () => {
    const openManageCategories = vi.fn(async () => {});
    const closeManageCategories = vi.fn();

    mocks.updateCategory.mockResolvedValue({
      id: 'cat-9',
      name: 'فئة معدلة'
    });

    useLibraryStore.setState({
      categoryNameInput: 'فئة معدلة',
      editingCategoryId: 'cat-9',
      openManageCategories,
      closeManageCategories
    });

    await useLibraryStore.getState().saveCategory();

    expect(mocks.updateCategory).toHaveBeenCalledWith({
      id: 'cat-9',
      name: 'فئة معدلة'
    });
    expect(mocks.toast.success).toHaveBeenCalledWith('تم تعديل الفئة');
    expect(openManageCategories).toHaveBeenCalledTimes(1);
    expect(closeManageCategories).toHaveBeenCalledTimes(1);
  });

  it('removeCategory loads delete info and populates the confirmation state', async () => {
    mocks.getCategoryDeleteInfo.mockResolvedValue({
      categoryId: 'cat-3',
      categoryName: 'الوقاية',
      itemsCount: 4
    });

    await useLibraryStore.getState().removeCategory({
      id: 'cat-3',
      name: 'الوقاية'
    });

    expect(useLibraryStore.getState().categoryToDelete).toEqual({
      id: 'cat-3',
      name: 'الوقاية',
      itemsCount: 4
    });
    expect(useLibraryStore.getState().preparingDeleteCategoryId).toBeNull();
  });

  it('loadItemsForCategory maps returned items and falls back to local category names', async () => {
    useLibraryStore.setState({
      categories: [{ id: 'cat-1', name: 'الأمراض' }]
    });
    mocks.getItemsByCategory.mockResolvedValue([
      {
        id: 'item-1',
        title: 'عنصر مرتبط بفئة',
        shortDescription: 'ملخص',
        content: 'تفاصيل',
        categoryId: 'cat-1',
        imageUrl: null,
        sources: 'https://trusted.test',
        createdAt: '2024-04-02T00:00:00Z'
      }
    ]);

    await useLibraryStore.getState().loadItemsForCategory('cat-1');

    expect(useLibraryStore.getState().contents).toEqual([
      {
        id: 'item-1',
        title: 'عنصر مرتبط بفئة',
        shortDescription: 'ملخص',
        content: 'تفاصيل',
        category: 'الأمراض',
        image: undefined,
        sources: ['https://trusted.test'],
        createdAt: '2024-04-02',
        type: 'library'
      }
    ]);
    expect(useLibraryStore.getState().isLoadingItems).toBe(false);
  });

  it('shows an error when the initial library load fails', async () => {
    mocks.getCategories.mockRejectedValue(new Error('network'));

    await useLibraryStore.getState().loadInitialData();

    expect(mocks.toast.error).toHaveBeenCalledWith('فشل جلب البيانات المبدئية');
    expect(useLibraryStore.getState().isLoadingCategories).toBe(false);
    expect(useLibraryStore.getState().isLoadingItems).toBe(false);
  });

  it('loadInitialData falls back when optional item fields are missing', async () => {
    mocks.getCategories.mockResolvedValue([{ id: 'cat-1', name: 'الأمراض' }]);
    mocks.getItemsByCategory.mockResolvedValue([
      {
        id: 'item-2',
        title: 'عنصر ناقص',
        shortDescription: null,
        content: 'تفاصيل',
        categoryId: 'unknown-cat',
        imageUrl: undefined,
        sources: null,
        createdAt: null
      }
    ]);

    await useLibraryStore.getState().loadInitialData();

    expect(useLibraryStore.getState().contents).toEqual([
      {
        id: 'item-2',
        title: 'عنصر ناقص',
        shortDescription: undefined,
        content: 'تفاصيل',
        category: 'غير معروف',
        image: undefined,
        sources: undefined,
        createdAt: undefined,
        type: 'library'
      }
    ]);
  });

  it('loadItemsForCategory shows a toast when the request fails', async () => {
    mocks.getItemsByCategory.mockRejectedValue(new Error('boom'));

    await useLibraryStore.getState().loadItemsForCategory('cat-1');

    expect(mocks.toast.error).toHaveBeenCalledWith('فشل جلب عناصر الفئة');
    expect(useLibraryStore.getState().isLoadingItems).toBe(false);
  });

  it('loadItemsForCategory prefers the API category name and keeps missing metadata undefined', async () => {
    useLibraryStore.setState({
      categories: [{ id: 'cat-1', name: 'الأمراض' }]
    });
    mocks.getItemsByCategory.mockResolvedValue([
      {
        id: 'item-2',
        title: 'عنصر باسم فئة من الخادم',
        shortDescription: null,
        content: 'تفاصيل',
        categoryId: 'cat-1',
        categoryName: 'اسم من الخادم',
        imageUrl: undefined,
        sources: null,
        createdAt: null
      }
    ]);

    await useLibraryStore.getState().loadItemsForCategory('cat-1');

    expect(useLibraryStore.getState().contents).toEqual([
      {
        id: 'item-2',
        title: 'عنصر باسم فئة من الخادم',
        shortDescription: undefined,
        content: 'تفاصيل',
        category: 'اسم من الخادم',
        image: undefined,
        sources: undefined,
        createdAt: undefined,
        type: 'library'
      }
    ]);
  });

  it('loadAllItems clears the list when there are no categories', async () => {
    useLibraryStore.setState({
      categories: [],
      contents: [{ id: 'item-1', title: 'قديم', content: 'x', category: 'الأمراض' }]
    });

    await useLibraryStore.getState().loadAllItems();

    expect(useLibraryStore.getState().contents).toEqual([]);
    expect(mocks.getItemsByCategory).not.toHaveBeenCalled();
  });

  it('loadAllItems merges and sorts content across categories', async () => {
    useLibraryStore.setState({
      categories: [
        { id: 'cat-1', name: 'الأمراض' },
        { id: 'cat-2', name: 'الوقاية' }
      ]
    });
    mocks.getItemsByCategory.mockImplementation(async (categoryId: string) => {
      if (categoryId === 'cat-1') {
        return [
          {
            id: 'item-1',
            title: 'أقدم',
            content: 'x',
            categoryId: 'cat-1',
            imageUrl: '/old.png',
            createdAt: '2024-01-01T00:00:00Z'
          }
        ];
      }

      return [
        {
          id: 'item-2',
          title: 'أحدث',
          content: 'y',
          categoryId: 'cat-2',
          imageUrl: '/new.png',
          createdAt: '2024-06-01T00:00:00Z'
        }
      ];
    });

    await useLibraryStore.getState().loadAllItems();

    expect(useLibraryStore.getState().contents.map((item) => item.title)).toEqual([
      'أحدث',
      'أقدم'
    ]);
    expect(useLibraryStore.getState().isLoadingItems).toBe(false);
  });

  it('loadAllItems falls back to unknown categories and empty optional fields', async () => {
    useLibraryStore.setState({
      categories: [{ id: 'cat-1', name: 'الأمراض' }]
    });
    mocks.getItemsByCategory.mockResolvedValue([
      {
        id: 'item-3',
        title: 'عنصر بدون بيانات إضافية',
        shortDescription: null,
        content: 'تفاصيل',
        categoryId: 'missing-cat',
        imageUrl: undefined,
        sources: null,
        createdAt: null
      }
    ]);

    await useLibraryStore.getState().loadAllItems();

    expect(useLibraryStore.getState().contents).toEqual([
      {
        id: 'item-3',
        title: 'عنصر بدون بيانات إضافية',
        shortDescription: undefined,
        content: 'تفاصيل',
        category: 'غير معروف',
        image: undefined,
        sources: undefined,
        createdAt: undefined,
        type: 'library'
      }
    ]);
  });

  it('loadAllItems shows an error toast when the aggregated load fails', async () => {
    useLibraryStore.setState({
      categories: [{ id: 'cat-1', name: 'الأمراض' }]
    });
    mocks.getItemsByCategory.mockRejectedValue(new Error('boom'));

    await useLibraryStore.getState().loadAllItems();

    expect(mocks.toast.error).toHaveBeenCalledWith('فشل جلب جميع العناصر');
    expect(useLibraryStore.getState().isLoadingItems).toBe(false);
  });

  it('handles deleteContent failure without clearing the pending delete dialog', async () => {
    mocks.deleteItem.mockRejectedValue(new Error('delete failed'));
    useLibraryStore.setState({
      contentToDelete: { id: '1', title: 'A', content: 'x', category: 'الأمراض' }
    });

    await useLibraryStore.getState().deleteContent('1');

    expect(useLibraryStore.getState().isDeleting).toBeNull();
    expect(useLibraryStore.getState().contentToDelete).toEqual({
      id: '1',
      title: 'A',
      content: 'x',
      category: 'الأمراض'
    });
    expect(mocks.toast.error).toHaveBeenCalledWith('فشل حذف العنصر');
  });

  it('ignores deleteContent calls for non-string identifiers', async () => {
    await useLibraryStore.getState().deleteContent(7);

    expect(mocks.deleteItem).not.toHaveBeenCalled();
    expect(useLibraryStore.getState().isDeleting).toBeNull();
  });

  it('opens category management and reloads the categories list', async () => {
    mocks.getCategories.mockResolvedValue([{ id: 'cat-1', name: 'الأمراض' }]);

    await useLibraryStore.getState().openManageCategories();

    expect(useLibraryStore.getState()).toMatchObject({
      isManagingCategories: true,
      isLoadingCategories: false,
      categories: [{ id: 'cat-1', name: 'الأمراض' }]
    });
  });

  it('shows an error when opening category management fails', async () => {
    mocks.getCategories.mockRejectedValue(new Error('boom'));

    await useLibraryStore.getState().openManageCategories();

    expect(useLibraryStore.getState().isManagingCategories).toBe(true);
    expect(useLibraryStore.getState().isLoadingCategories).toBe(false);
    expect(mocks.toast.error).toHaveBeenCalledWith('فشل جلب الفئات');
  });

  it('resets transient category-management state when closing the dialog', () => {
    useLibraryStore.setState({
      isManagingCategories: true,
      editingCategoryId: 'cat-1',
      categoryNameInput: 'مؤقت',
      categoryToDelete: { id: 'cat-1', name: 'الأمراض', itemsCount: 3 },
      preparingDeleteCategoryId: 'cat-1'
    });

    useLibraryStore.getState().closeManageCategories();

    expect(useLibraryStore.getState()).toMatchObject({
      isManagingCategories: false,
      editingCategoryId: null,
      categoryNameInput: '',
      categoryToDelete: null,
      preparingDeleteCategoryId: null
    });
  });

  it('updates simple category and content state setters', () => {
    const content = { id: '1', title: 'A', content: 'x', category: 'الأمراض' };
    const category = { id: 'cat-1', name: 'الأمراض' };

    useLibraryStore.getState().setSearchQuery('ذبابة');
    useLibraryStore.getState().startEditCategory(category);
    useLibraryStore.getState().requestDeleteContent(content);
    useLibraryStore.getState().viewContent(content);
    useLibraryStore.getState().setViewingContent(null);
    useLibraryStore.getState().setCategoryNameInput('فئة جديدة');
    useLibraryStore.getState().setContentToDelete(content);
    useLibraryStore.getState().setCategoryToDelete({
      id: 'cat-1',
      name: 'الأمراض',
      itemsCount: 2
    });

    expect(useLibraryStore.getState()).toMatchObject({
      searchQuery: 'ذبابة',
      editingCategoryId: 'cat-1',
      categoryNameInput: 'فئة جديدة',
      contentToDelete: content,
      viewingContent: null,
      categoryToDelete: {
        id: 'cat-1',
        name: 'الأمراض',
        itemsCount: 2
      }
    });
  });

  it('validates blank category names before saving', async () => {
    useLibraryStore.setState({
      categoryNameInput: '   '
    });

    await useLibraryStore.getState().saveCategory();

    expect(mocks.createCategory).not.toHaveBeenCalled();
    expect(mocks.updateCategory).not.toHaveBeenCalled();
    expect(mocks.toast.error).toHaveBeenCalledWith('يرجى إدخال اسم صالح');
  });

  it('creates a new category then reloads and closes the manager', async () => {
    const openManageCategories = vi.fn(async () => {});
    const closeManageCategories = vi.fn();

    mocks.createCategory.mockResolvedValue({
      id: 'cat-5',
      name: 'فئة جديدة'
    });

    useLibraryStore.setState({
      categoryNameInput: 'فئة جديدة',
      editingCategoryId: null,
      openManageCategories,
      closeManageCategories
    });

    await useLibraryStore.getState().saveCategory();

    expect(mocks.createCategory).toHaveBeenCalledWith({
      name: 'فئة جديدة'
    });
    expect(mocks.toast.success).toHaveBeenCalledWith('تم إضافة الفئة');
    expect(openManageCategories).toHaveBeenCalledTimes(1);
    expect(closeManageCategories).toHaveBeenCalledTimes(1);
  });

  it('confirmRemoveCategory deletes the category, reloads categories, and clears flags', async () => {
    const openManageCategories = vi.fn(async () => {});
    mocks.deleteCategory.mockResolvedValue(undefined);

    useLibraryStore.setState({
      categoryToDelete: {
        id: 'cat-3',
        name: 'الوقاية',
        itemsCount: 4
      },
      openManageCategories
    });

    await useLibraryStore.getState().confirmRemoveCategory();

    expect(mocks.deleteCategory).toHaveBeenCalledWith('cat-3');
    expect(mocks.toast.success).toHaveBeenCalledWith('تم حذف الفئة');
    expect(openManageCategories).toHaveBeenCalledTimes(1);
    expect(useLibraryStore.getState().categoryToDelete).toBeNull();
    expect(useLibraryStore.getState().isDeletingCategory).toBe(false);
  });

  it('shows a generic save error when the API response has no message', async () => {
    mocks.createCategory.mockRejectedValue({ response: { data: {} } });

    useLibraryStore.setState({
      categoryNameInput: 'فئة بدون رسالة'
    });

    await useLibraryStore.getState().saveCategory();

    expect(mocks.toast.error).toHaveBeenCalledWith('فشل حفظ الفئة');
  });

  it('prefers the native Error message when category save throws an Error instance', async () => {
    mocks.createCategory.mockRejectedValue(new Error('تعذر الاتصال بالخادم'));

    useLibraryStore.setState({
      categoryNameInput: 'فئة فاشلة'
    });

    await useLibraryStore.getState().saveCategory();

    expect(mocks.toast.error).toHaveBeenCalledWith('تعذر الاتصال بالخادم');
  });

  it('falls back to the generic save error when the response shape is invalid', async () => {
    mocks.createCategory.mockRejectedValue({
      response: 'bad-response'
    });

    useLibraryStore.setState({
      categoryNameInput: 'فئة غير صالحة'
    });

    await useLibraryStore.getState().saveCategory();

    expect(mocks.toast.error).toHaveBeenCalledWith('فشل حفظ الفئة');
  });

  it('falls back to the generic save error when category save throws a primitive value', async () => {
    mocks.createCategory.mockRejectedValue('boom');

    useLibraryStore.setState({
      categoryNameInput: 'فئة غير قابلة للحفظ'
    });

    await useLibraryStore.getState().saveCategory();

    expect(mocks.toast.error).toHaveBeenCalledWith('فشل حفظ الفئة');
  });

  it('shows an error when loading category delete info fails', async () => {
    mocks.getCategoryDeleteInfo.mockRejectedValue(new Error('boom'));

    await useLibraryStore.getState().removeCategory({
      id: 'cat-3',
      name: 'الوقاية'
    });

    expect(useLibraryStore.getState().preparingDeleteCategoryId).toBeNull();
    expect(mocks.toast.error).toHaveBeenCalledWith('فشل تحميل معلومات الحذف');
  });

  it('does nothing when confirmRemoveCategory is called without a target', async () => {
    await useLibraryStore.getState().confirmRemoveCategory();

    expect(mocks.deleteCategory).not.toHaveBeenCalled();
    expect(mocks.toast.success).not.toHaveBeenCalled();
  });

  it('shows an error when deleting a category fails', async () => {
    mocks.deleteCategory.mockRejectedValue(new Error('boom'));
    useLibraryStore.setState({
      categoryToDelete: {
        id: 'cat-3',
        name: 'الوقاية',
        itemsCount: 4
      }
    });

    await useLibraryStore.getState().confirmRemoveCategory();

    expect(useLibraryStore.getState().isDeletingCategory).toBe(false);
    expect(useLibraryStore.getState().categoryToDelete).toEqual({
      id: 'cat-3',
      name: 'الوقاية',
      itemsCount: 4
    });
    expect(mocks.toast.error).toHaveBeenCalledWith('فشل حذف الفئة');
  });
});
