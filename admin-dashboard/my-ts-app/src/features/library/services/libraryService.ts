// خدمات الدعم الخاصة بمكتبة المحتوى.
// هذا الملف يوفر منطق المعالجة بين واجهة المستخدم وطبقة API.

import {
  createCategory as createCategoryApi,
  createItem as createItemApi,
  updateItem as updateItemApi
} from '../api/libraryApi';
import {
  mapCreateItemResponseToContentItem,
  mapUpdateItemResponseToContentItem
} from '../mappers/libraryMapper';
import type {
  CreateLibraryItemParams,
  LibraryServiceError,
  ResolveCategoryIdParams,
  ResolveCategoryIdResult,
  SourceValidationResult,
  UpdateLibraryItemParams
} from '../types/library.types';

// ينشئ خطأ خدمة خاص يحتوي على رمز مخصص يمكن للواجهة التعامل معه.
function createLibraryServiceError(
  code: NonNullable<LibraryServiceError['code']>,
  cause: unknown
) {
  const error = new Error(String(cause instanceof Error ? cause.message : cause)) as LibraryServiceError;
  error.code = code;
  return error;
}

// يحول بيانات النموذج إلى FormData ليتم إرسالها إلى واجهة الـ API.
function buildLibraryItemFormData({
  formData,
  categoryId,
  filteredSources,
  imageFile
}: CreateLibraryItemParams) {
  const data = new FormData();
  data.append('Title', formData.title);
  data.append('ShortDescription', formData.shortDescription);
  data.append('Content', formData.content);
  data.append('CategoryId', categoryId);

  if (filteredSources.length > 0) {
    data.append('Sources', filteredSources.join(','));
  }
  if (imageFile) data.append('Image', imageFile);

  return data;
}

// حل معرف الفئة قبل إنشاء/تحديث عنصر المكتبة.
// هذا هو أهم دفق عمل في الملف.
export async function resolveCategoryId({
  categoriesState,
  selectedCategoryId,
  formData,
  createCategory
}: ResolveCategoryIdParams): Promise<ResolveCategoryIdResult> {
  // استخدم دالة إنشاء الفئة التي تمرَّر من الخارج أو default من API.
  const createCategoryAction = createCategory ?? createCategoryApi;
  let categoryId = selectedCategoryId;

  // إذا كان المستخدم قد اختار فئة من القائمة، نستخدمها.
  if (!categoryId) {
    const name = formData.newCategory.trim() || formData.category;
    const found = categoriesState.find(c => c.name === name);
    if (found) categoryId = found.id;
  }

  // إذا لم يكن هناك فئة محددة ولكنه يوجد اسم فئة جديدة
  // نحاول إعادة استخدام فئة موجودة بنفس الاسم قبل إنشاء جديدة.
  if (!categoryId && formData.newCategory.trim()) {
    const normalized = (n: string) => n.trim().toLowerCase();
    const foundDup = categoriesState.find(c => normalized(c.name) === normalized(formData.newCategory));
    if (foundDup) {
      return {
        categoryId: foundDup.id,
        status: 'reused',
        category: foundDup,
        nextFormData: { ...formData, category: foundDup.name, newCategory: '' },
        nextSelectedCategoryId: foundDup.id,
        nextShowNewCategory: false
      };
    }

    // إذا الاسم جديد، ننشئ فئة جديدة عبر الـ API.
    try {
      const created = await createCategoryAction({ name: formData.newCategory.trim() });
      return {
        categoryId: created.id,
        status: 'created',
        category: { id: created.id, name: created.name }
      };
    } catch (error) {
      throw createLibraryServiceError('CREATE_NEW_CATEGORY_FAILED', error);
    }
  }

  // إذا لم يتم اختيار فئة بعد، ونمتلك فئات موجودة بالفعل،
  // نستخدم الفئة الأولى كاختيار افتراضي.
  if (!categoryId) {
    if (categoriesState.length > 0) {
      return {
        categoryId: categoriesState[0].id,
        status: 'existing'
      };
    }

    // إذا لم تكن هناك أي فئات حتى الآن، ننشئ فئة افتراضية باسم عام.
    try {
      const created = await createCategoryAction({ name: formData.newCategory.trim() || formData.category || 'عام' });
      return {
        categoryId: created.id,
        status: 'default-created',
        category: { id: created.id, name: created.name }
      };
    } catch (error) {
      throw createLibraryServiceError('CREATE_DEFAULT_CATEGORY_FAILED', error);
    }
  }

  // حالة الفئة موجودة ومحددة بالفعل.
  return {
    categoryId,
    status: 'existing'
  };
}

// يتحقق من صحة روابط المصادر ويعيد القيم النظيفة وغير الصحيحة.
export function validateSources(
  sources: string[],
  isValidSecureSourceUrl: (value: string) => boolean
): SourceValidationResult {
  const filteredSources = sources.map(source => source.trim()).filter(Boolean);
  const invalidSourceValues = filteredSources.filter(source => !isValidSecureSourceUrl(source));

  return {
    filteredSources,
    invalidSourceValues
  };
}

// إنشاء عنصر مكتبة جديد عبر API وإرجاع الكائن المستخدم في الواجهة.
export async function createLibraryItem({
  formData,
  categoryId,
  filteredSources,
  imageFile,
  imagePreview
}: CreateLibraryItemParams) {
  const data = buildLibraryItemFormData({
    formData,
    categoryId,
    filteredSources,
    imageFile,
    imagePreview
  });
  const resultItem = await createItemApi(data);
  const contentData = mapCreateItemResponseToContentItem(
    resultItem,
    formData,
    imagePreview,
    filteredSources
  );

  return {
    contentData
  };
}

// تحديث عنصر مكتبة موجود عبر API وإرجاع النسخة المحدثة.
export async function updateLibraryItem({
  editingContent,
  formData,
  categoryId,
  filteredSources,
  imageFile,
  imagePreview
}: UpdateLibraryItemParams) {
  const data = buildLibraryItemFormData({
    formData,
    categoryId,
    filteredSources,
    imageFile,
    imagePreview
  });
  const resultItem = await updateItemApi(String(editingContent.id), data);
  const updatedContent = mapUpdateItemResponseToContentItem(
    resultItem,
    editingContent,
    formData,
    imagePreview,
    filteredSources
  );

  return {
    updatedContent
  };
}
