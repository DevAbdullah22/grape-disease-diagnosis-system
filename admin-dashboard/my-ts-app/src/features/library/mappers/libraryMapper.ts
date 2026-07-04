// هذا الملف يحتوي على دوال تحويل بين ردود API وبيانات المحتوى المستخدمة في الواجهة.
// الهدف هو توحيد بنية العنصر قبل عرضه أو حفظه محليًا.

import type { LibraryItemDto } from '../api/libraryApi';
import type { ContentItem, FormDataState } from '../types/library.types';

type LibraryItemResponse = Partial<LibraryItemDto> & {
  id?: string | number;
};

// تحويل سلسلة المصادر من API إلى مصفوفة جاهزة للعرض.
// إذا كانت قيمة المصدر في الرد عبارة عن سلسلة مفصولة بفواصل، نقوم بتقسيمها.
// وإلا، نستخدم المصادر المعالجة من الواجهة.
function mapSources(value: string[] | string | null | undefined, filteredSources: string[]) {
  return value && typeof value === 'string' ? value.split(',') : filteredSources;
}

// تحويل استجابة إنشاء عنصر جديد إلى كائن ContentItem المستخدم في الواجهة.
// workflow:
// 1. إذا أعاد الـ API معرف عنصر، نستخدمه، وإلا نخلق معرف مؤقت من Date.now().
// 2. نستخدم العنوان والمحتوى من رد الـ API إذا كان موجوداً، وإلا نعتمد على بيانات النموذج.
// 3. الفئة تُستخلص من الرد إن كانت موجودة، وإلا من الحقول الجديدة أو المختارة في النموذج.
// 4. الصورة تُعرض من رابط الـ API إن وجد، وإلا من معاينة الصورة المرفوعة محلياً.
// 5. المصادر تُحاول أن تُقرأ من رد الـ API كسلسلة، وبخلاف ذلك تُستخدم القيم المفلترة من الواجهة.
export function mapCreateItemResponseToContentItem(
  resultItem: LibraryItemResponse,
  formData: FormDataState,
  imagePreview: string,
  filteredSources: string[]
): ContentItem {
  return {
    id: resultItem?.id ?? Date.now(),
    title: resultItem.title || formData.title,
    shortDescription: formData.shortDescription,
    category: resultItem.categoryName ? resultItem.categoryName : (formData.newCategory.trim() || formData.category),
    type: 'مقال',
    content: resultItem.content || formData.content,
    image: resultItem.imageUrl || imagePreview,
    sources: mapSources(resultItem.sources, filteredSources),
  };
}

// تحويل استجابة تحديث عنصر إلى كائن ContentItem.
// workflow:
// 1. نحافظ على المعرف الموجود للعناصر المحررة.
// 2. إذا أعاد الـ API بيانات محدثة للعناصر، نستخدمها. وإلا نعتمد على بيانات النموذج الحالية.
// 3. المصطلح "type" يبقى ثابتاً كـ 'مقال' لأن هذا هو نوع المحتوى المعروض.
// 4. نقوم بنفس معالجة الصورة والمصادر كما في الإنشاء.
export function mapUpdateItemResponseToContentItem(
  resultItem: LibraryItemResponse,
  editingContent: ContentItem,
  formData: FormDataState,
  imagePreview: string,
  filteredSources: string[]
): ContentItem {
  return {
    id: editingContent.id,
    title: resultItem.title || formData.title,
    shortDescription: resultItem.shortDescription || formData.shortDescription,
    category: resultItem.categoryName || formData.category,
    type: 'مقال',
    content: resultItem.content || formData.content,
    image: resultItem.imageUrl || imagePreview,
    sources: mapSources(resultItem.sources, filteredSources),
  };
}
