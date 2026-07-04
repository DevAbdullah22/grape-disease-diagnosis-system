import { useCallback, useState } from 'react';
import type { Dispatch, SetStateAction } from 'react';

import { toast } from 'sonner';

import {
  createLibraryItem,
  resolveCategoryId,
  updateLibraryItem,
  validateSources
} from '../services/libraryService';
import type {
  Category,
  ContentItem,
  FormDataState,
  LibraryServiceError
} from '../types/library.types';

interface UseLibraryItemSubmitParams {
  categoriesState: Category[];
  createCategory: (dto: { name: string }) => Promise<Category>;
  refreshCategories: () => Promise<Category[]>;
  selectedCategoryId: string;
  formData: FormDataState;
  setFormData: Dispatch<SetStateAction<FormDataState>>;
  setShowNewCategory: Dispatch<SetStateAction<boolean>>;
  imageFile: File | null;
  imagePreview: string;
  sources: string[];
  setErrors: Dispatch<SetStateAction<{ [key: string]: string }>>;
  isEditMode: boolean;
  editingContent?: ContentItem | null;
  onUpdateContent?: (content: ContentItem) => void;
  onAddContent?: (content: ContentItem) => void;
  isValidSecureSourceUrl: (value: string) => boolean;
}

// hook لإدارة حفظ عنصر المكتبة سواء إضافة جديد أو تعديل موجود.
export function useLibraryItemSubmit({
  categoriesState,
  createCategory,
  refreshCategories,
  selectedCategoryId,
  formData,
  setFormData,
  setShowNewCategory,
  imageFile,
  imagePreview,
  sources,
  setErrors,
  isEditMode,
  editingContent,
  onUpdateContent,
  onAddContent,
  isValidSecureSourceUrl
}: UseLibraryItemSubmitParams) {
  const [isSaving, setIsSaving] = useState(false);

  // تدفق حفظ العنصر:
  // 1. حل الفئة المستخدمة أو إنشاء فئة جديدة
  // 2. تحديث الحالة إذا تم إعادة استخدام فئة موجودة
  // 3. التحقق من صحة مصادر الروابط
  // 4. إرسال الطلب عبر API لإنشاء أو تحديث العنصر
  // 5. عرض إشعارات النجاح/الفشل
  const submitItem = useCallback(async () => {
    try {
      const categoryResolution = await resolveCategoryId({
        categoriesState,
        selectedCategoryId,
        formData,
        createCategory
      });

      // إذا تم إعادة استخدام فئة موجودة، نحفظ الحالة الجديدة للمستخدم.
      if (categoryResolution.status === 'reused' && categoryResolution.category) {
        if (categoryResolution.nextFormData) {
          setFormData(categoryResolution.nextFormData);
        }
        if (typeof categoryResolution.nextShowNewCategory === 'boolean') {
          setShowNewCategory(categoryResolution.nextShowNewCategory);
        }
        toast.success(`الفئة موجودة مسبقاً وسيتم استخدامها: ${categoryResolution.category.name}`);
      }

      // إذا أنشأنا فئة جديدة مباشرة عبر الطلب، نحدث قائمة الفئات.
      if (categoryResolution.status === 'created' && categoryResolution.category) {
        toast.success(`تم إنشاء الفئة الجديدة: ${categoryResolution.category.name}`);
        try {
          await refreshCategories();
        } catch (refreshError) {
          console.error('Failed to refresh categories:', refreshError);
        }
      }

      // إذا تم إنشاء فئة افتراضية فرضاً، نحدّث القائمة أيضاً.
      if (categoryResolution.status === 'default-created' && categoryResolution.category) {
        toast.success(`تم إنشاء الفئة: ${categoryResolution.category.name}`);
        try {
          await refreshCategories();
        } catch (refreshError) {
          console.error('Failed to refresh categories:', refreshError);
        }
      }

      // تحقق شامل من مصادر URLs قبل إرسال البيانات.
      const { filteredSources, invalidSourceValues } = validateSources(
        sources,
        isValidSecureSourceUrl
      );
      if (invalidSourceValues.length > 0) {
        setErrors(prev => ({
          ...prev,
          sources: 'تم رفض الحفظ: جميع المصادر يجب أن تكون روابط https:// صالحة وآمنة.'
        }));
        toast.error('بعض الروابط غير آمنة أو غير صالحة. استخدم https:// فقط.');
        return;
      }

      setIsSaving(true);

      // إذا كانت الشاشة في وضع التحرير، نرسل طلب التحديث.
      if (isEditMode && editingContent && editingContent.id !== undefined && editingContent.id !== null) {
        const { updatedContent } = await updateLibraryItem({
          editingContent,
          formData,
          categoryId: categoryResolution.categoryId,
          filteredSources,
          imageFile,
          imagePreview
        });
        if (onUpdateContent) {
          onUpdateContent(updatedContent);
        }
        toast.success('تم تحديث المحتوى بنجاح');
      } else {
        // في حال إضافة محتوى جديد.
        const { contentData } = await createLibraryItem({
          formData,
          categoryId: categoryResolution.categoryId,
          filteredSources,
          imageFile,
          imagePreview
        });
        onAddContent?.(contentData);
        toast.success('تم حفظ المحتوى بنجاح');
      }

      setIsSaving(false);
      return true;
    } catch (err) {
      const serviceError = err as LibraryServiceError;
      if (serviceError.code === 'CREATE_NEW_CATEGORY_FAILED') {
        console.error('Failed to create category:', err);
        toast.error('فشل في إنشاء الفئة الجديدة');
        return false;
      }
      if (serviceError.code === 'CREATE_DEFAULT_CATEGORY_FAILED') {
        console.error('Failed to create default category:', err);
        toast.error('فشل في إنشاء الفئة الافتراضية');
        return false;
      }
      console.error(err);
      toast.error('حدث خطأ أثناء حفظ المحتوى');
      setIsSaving(false);
      return false;
    }
  }, [
    categoriesState,
    createCategory,
    editingContent,
    formData,
    imageFile,
    imagePreview,
    isEditMode,
    isValidSecureSourceUrl,
    onAddContent,
    onUpdateContent,
    refreshCategories,
    selectedCategoryId,
    setErrors,
    setFormData,
    setShowNewCategory,
    sources
  ]);

  return {
    submitItem,
    isSaving
  };
}
