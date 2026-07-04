import { useCallback, useEffect, useState } from 'react';
import { toast } from 'sonner';

import { createCategory as createLibraryCategory, getCategories } from '../api/libraryApi';
import type { Category } from '../types/library.types';

interface UseLibraryCategoriesOptions {
  onLoadError?: (error: unknown) => void;
}

// hook لإدارة قائمة الفئات: التحميل الأولي، التحديث، وإنشاء فئات جديدة.
export function useLibraryCategories({ onLoadError }: UseLibraryCategoriesOptions = {}) {
  const [categoriesState, setCategoriesState] = useState<Category[]>([]);
  const [isLoadingCategories, setIsLoadingCategories] = useState(false);
  const [isCreatingCategory, setIsCreatingCategory] = useState(false);

  // استدعاء API للحصول على الفئات وتخزينها في الحالة.
  const refreshCategories = useCallback(async () => {
    setIsLoadingCategories(true);
    try {
      const cats = await getCategories();
      const mapped = cats.map((c) => ({ id: c.id, name: c.name }));
      setCategoriesState(mapped);
      return mapped;
    } catch (error) {
      onLoadError?.(error);
      return [];
    } finally {
      setIsLoadingCategories(false);
    }
  }, [onLoadError]);

  // تحميل الفئات عند تحميل المكون لأول مرة.
  useEffect(() => {
    void refreshCategories();
  }, [refreshCategories]);

  // إنشاء فئة جديدة وتحديث القائمة محليًا بعد نجاح الطلب.
  const createCategory = useCallback(async (dto: { name: string }) => {
    setIsCreatingCategory(true);
    try {
      const created = await createLibraryCategory(dto);
      const mapped = { id: created.id, name: created.name };
      setCategoriesState(prev => [...prev, mapped]);
      return mapped;
    } catch (error) {
        toast.error('فشل في إنشاء الفئة');
        throw error;
    } finally {
      setIsCreatingCategory(false);
    }
  }, []);

  return {
    categoriesState,
    isLoadingCategories,
    isCreatingCategory,
    createCategory,
    refreshCategories
  };
}
