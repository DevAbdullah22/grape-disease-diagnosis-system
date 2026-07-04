// مخزن Zustand لإدارة حالة لوحة المكتبة-الإدارية، بما في ذلك الفئات والعناصر والحذف والعرض.
import { create } from 'zustand';
import { toast } from 'sonner';
import {
  getCategories,
  getItemsByCategory,
  deleteItem,
  resolveImageUrl,
  createCategory,
  updateCategory,
  deleteCategory,
  getCategoryDeleteInfo,
} from '../features/library/api/libraryApi';
import type { LibraryItemDto as ApiLibraryItem } from '../features/library/api/libraryApi';
import type { ContentItem, Category } from '../features/library/types/library.types';

// دالة مساعدة لاستخراج رسالة الخطأ من استجابة axios أو من خطأ عام.
function extractApiErrorMessage(error: unknown) {
  if (error instanceof Error && error.message) {
    return error.message;
  }

  if (typeof error !== 'object' || error === null || !('response' in error)) {
    return undefined;
  }

  const response = error.response;
  if (typeof response !== 'object' || response === null || !('data' in response)) {
    return undefined;
  }

  const data = response.data;
  if (typeof data !== 'object' || data === null || !('message' in data)) {
    return undefined;
  }

  return typeof data.message === 'string' ? data.message : undefined;
}

interface LibraryState {
  searchQuery: string;
  selectedCategory: string;
  categories: Category[];
  contents: ContentItem[];
  isLoadingCategories: boolean;
  isLoadingItems: boolean;
  isDeleting: string | null;
  contentToDelete: ContentItem | null;
  viewingContent: ContentItem | null;
  isManagingCategories: boolean;
  editingCategoryId: string | null;
  categoryNameInput: string;
  categoryToDelete: { id: string; name: string; itemsCount: number } | null;
  isDeletingCategory: boolean;
  preparingDeleteCategoryId: string | null;
  setSearchQuery: (query: string) => void;
  setSelectedCategory: (category: string) => void;
  loadInitialData: () => Promise<void>;
  loadItemsForCategory: (categoryId: string) => Promise<void>;
  loadAllItems: () => Promise<void>;
  deleteContent: (id: string | number) => Promise<void>;
  openManageCategories: () => void;
  closeManageCategories: () => void;
  startEditCategory: (category: Category) => void;
  saveCategory: () => Promise<void>;
  removeCategory: (category: Category) => Promise<void>;
  confirmRemoveCategory: () => Promise<void>;
  requestDeleteContent: (content: ContentItem) => void;
  viewContent: (content: ContentItem) => void;
  setViewingContent: (content: ContentItem | null) => void;
  setCategoryNameInput: (name: string) => void;
  setContentToDelete: (content: ContentItem | null) => void;
  setCategoryToDelete: (category: { id: string; name: string; itemsCount: number } | null) => void;
}

export const useLibraryStore = create<LibraryState>((set, get) => ({
  // الحالة الافتراضية
  searchQuery: '',
  selectedCategory: 'الكل',
  categories: [],
  contents: [],
  isLoadingCategories: false,
  isLoadingItems: false,
  isDeleting: null,
  contentToDelete: null,
  viewingContent: null,
  isManagingCategories: false,
  editingCategoryId: null,
  categoryNameInput: '',
  categoryToDelete: null,
  isDeletingCategory: false,
  preparingDeleteCategoryId: null,

  // إعداد الاستعلام المستخدم في البحث
  setSearchQuery: (query) => set({ searchQuery: query }),

  // عند تغيير الفئة المحددة، يتم تحميل العناصر المناسبة أو تحميل الكل
  setSelectedCategory: (category) => {
    set({ selectedCategory: category });
    if (category === 'الكل') {
      get().loadAllItems();
    } else {
      const selected = get().categories.find((c) => c.name === category);
      if (selected) {
        get().loadItemsForCategory(selected.id);
      }
    }
  },

  // تحميل الفئات والعناصر في البداية
  loadInitialData: async () => {
    set({ isLoadingCategories: true, isLoadingItems: true });
    try {
      const cats = await getCategories();
      set({ categories: cats });

      const promises: Promise<ApiLibraryItem[]>[] = cats.map((c) => getItemsByCategory(c.id));
      const results = await Promise.all(promises);
      const allItems: ApiLibraryItem[] = results.flat();

      const mapped = allItems.map(i => ({
        id: i.id as string,
        title: i.title,
        shortDescription: i.shortDescription ?? undefined,
        content: i.content,
        category: cats.find((c) => c.id === i.categoryId)?.name ?? 'غير معروف',
        image: resolveImageUrl(i.imageUrl ?? undefined),
        sources: i.sources ? i.sources.split(',') : undefined,
        createdAt: typeof i.createdAt === 'string' ? new Date(i.createdAt).toISOString().split('T')[0] : undefined,
        type: 'library'
      }));

      mapped.sort((a, b) => {
        const da = a.createdAt ? new Date(a.createdAt).getTime() : 0;
        const db = b.createdAt ? new Date(b.createdAt).getTime() : 0;
        return db - da;
      });

      set({ contents: mapped, isLoadingItems: false, isLoadingCategories: false });
    } catch {
      toast.error('فشل جلب البيانات المبدئية');
      set({ isLoadingItems: false, isLoadingCategories: false });
    }
  },

  // تحميل العناصر لفئة واحدة محددة
  loadItemsForCategory: async (categoryId) => {
    set({ isLoadingItems: true });
    try {
      const items = await getItemsByCategory(categoryId);
      const mapped = items.map((i) => ({
        id: i.id as string,
        title: i.title,
        shortDescription: i.shortDescription ?? undefined,
        content: i.content,
        category: i.categoryName ?? get().categories.find((c) => c.id === i.categoryId)?.name ?? 'غير معروف',
        image: resolveImageUrl(i.imageUrl ?? undefined),
        sources: i.sources ? i.sources.split(',') : undefined,
        createdAt: typeof i.createdAt === 'string' ? new Date(i.createdAt).toISOString().split('T')[0] : undefined,
        type: 'library'
      }));
      set({ contents: mapped, isLoadingItems: false });
    } catch {
      toast.error('فشل جلب عناصر الفئة');
      set({ isLoadingItems: false });
    }
  },

  // تحميل كل العناصر عبر جميع الفئات
  loadAllItems: async () => {
    const { categories } = get();
    if (!categories || categories.length === 0) {
      set({ contents: [] });
      return;
    }

    set({ isLoadingItems: true });
    try {
      const promises: Promise<ApiLibraryItem[]>[] = categories.map((c) => getItemsByCategory(c.id));
      const results = await Promise.all(promises);
      const allItems: ApiLibraryItem[] = results.flat();
      const mapped = allItems.map(i => ({
        id: i.id as string,
        title: i.title,
        shortDescription: i.shortDescription ?? undefined,
        content: i.content,
        category: categories.find((c) => c.id === i.categoryId)?.name ?? 'غير معروف',
        image: resolveImageUrl(i.imageUrl ?? undefined),
        sources: i.sources ? i.sources.split(',') : undefined,
        createdAt: typeof i.createdAt === 'string' ? new Date(i.createdAt).toISOString().split('T')[0] : undefined,
        type: 'library'
      }));
      mapped.sort((a, b) => {
        const da = a.createdAt ? new Date(a.createdAt).getTime() : 0;
        const db = b.createdAt ? new Date(b.createdAt).getTime() : 0;
        return db - da;
      });
      set({ contents: mapped, isLoadingItems: false });
    } catch {
      toast.error('فشل جلب جميع العناصر');
      set({ isLoadingItems: false });
    }
  },

  // حذف عنصر مكتبة وتحديث الحالة المحلية بعد النجاح
  deleteContent: async (id) => {
    if (typeof id === 'string') {
      set({ isDeleting: id });
      try {
        await deleteItem(id);
        set((state) => ({
          contents: state.contents.filter((c) => c.id !== id),
          isDeleting: null,
          contentToDelete: null,
        }));
        toast.success('تم حذف العنصر');
      } catch {
        toast.error('فشل حذف العنصر');
        set({ isDeleting: null });
      }
    }
  },

  // فتح واجهة إدارة الفئات وجلب الفئات من API
  openManageCategories: async () => {
    set({ isManagingCategories: true });
    set({ isLoadingCategories: true });
    try {
      const cats = await getCategories();
      set({ categories: cats, isLoadingCategories: false });
    } catch {
      toast.error('فشل جلب الفئات');
      set({ isLoadingCategories: false });
    }
  },

  // إعادة الحالة إلى الوضع الافتراضي عند إغلاق واجهة إدارة الفئات
  closeManageCategories: () => {
    set({
      isManagingCategories: false,
      editingCategoryId: null,
      categoryNameInput: '',
      categoryToDelete: null,
      preparingDeleteCategoryId: null,
    });
  },

  // بدء تعديل الفئة عن طريق ملء حقل الاسم الحالي
  startEditCategory: (category) => {
    set({ editingCategoryId: category.id, categoryNameInput: category.name });
  },

  // حفظ الفئة الجديدة أو تعديل الفئة الحالية ثم إعادة تحميل الفئات
  saveCategory: async () => {
    const { categoryNameInput, editingCategoryId } = get();
    const name = categoryNameInput.trim();
    if (!name) {
      toast.error('يرجى إدخال اسم صالح');
      return;
    }
    try {
      if (editingCategoryId) {
        await updateCategory({ id: editingCategoryId, name });
        toast.success('تم تعديل الفئة');
      } else {
        await createCategory({ name });
        toast.success('تم إضافة الفئة');
      }
      get().openManageCategories(); // إعادة تحميل الفئات بعد التغيير
      get().closeManageCategories();
    } catch (error) {
      toast.error(extractApiErrorMessage(error) || 'فشل حفظ الفئة');
    }
  },

  // بدء طلب حذف فئة عن طريق استدعاء API للحصول على عدد العناصر المرتبطة
  removeCategory: async (category) => {
    set({ preparingDeleteCategoryId: category.id });
    try {
      const info = await getCategoryDeleteInfo(category.id);
      set({
        categoryToDelete: { id: category.id, name: category.name, itemsCount: info.itemsCount },
        preparingDeleteCategoryId: null,
      });
    } catch {
      toast.error('فشل تحميل معلومات الحذف');
      set({ preparingDeleteCategoryId: null });
    }
  },

  // تأكيد الحذف بعد الحصول على معلومات الفئة المرتبطة
  confirmRemoveCategory: async () => {
    const { categoryToDelete } = get();
    if (!categoryToDelete) return;
    set({ isDeletingCategory: true });
    try {
      await deleteCategory(categoryToDelete.id);
      toast.success('تم حذف الفئة');
      get().openManageCategories(); // إعادة تحميل بعد الحذف
      set({ categoryToDelete: null, isDeletingCategory: false });
    } catch {
      toast.error('فشل حذف الفئة');
      set({ isDeletingCategory: false });
    }
  },

  // فتح نافذة تأكيد حذف عنصر المكتبة
  requestDeleteContent: (content) => {
    set({ contentToDelete: content });
  },

  // فتح نافذة عرض المحتوى
  viewContent: (content) => {
    set({ viewingContent: content });
  },

  // تحديث حالات التحكم في النافذة مباشرة
  setViewingContent: (content) => set({ viewingContent: content }),
  setCategoryNameInput: (name) => set({ categoryNameInput: name }),
  setContentToDelete: (content) => set({ contentToDelete: content }),
  setCategoryToDelete: (category) => set({ categoryToDelete: category }),
}));
