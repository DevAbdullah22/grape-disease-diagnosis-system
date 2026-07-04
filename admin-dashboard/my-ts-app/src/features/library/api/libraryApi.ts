// هذا الملف يحتوي على دوال التفاعل مع واجهة API الخاصة بمكتبة المحتوى.
// كل دالة تمثل طلب HTTP يتم استدعاؤه من الأقسام الأخرى مثل الخدمة والمخزن والمكونات.

import api, { API_BASE } from '../../../services/api';

// جلب جميع الفئات المتاحة.
// يستخدم في صفحة إدارة الفئات وفي شاشة إضافة المحتوى لعرض الفئات الحالية.
export async function getCategories() {
  const res = await api.get('/LibraryCategory');
  return res.data as Array<{ id: string; name: string }>;
}

// جلب تفاصيل فئة واحدة بواسطة المعرف.
// يُستخدم عند الحاجة لعرض فئة محددة أو تحديثها.
export async function getCategoryById(id: string) {
  const res = await api.get(`/LibraryCategory/${id}`);
  return res.data as { id: string; name: string };
}

// إنشاء فئة جديدة في النظام.
// يرسل اسم الفئة إلى API ويعيد الفئة المنشأة مع المعرف.
export async function createCategory(dto: { name: string }) {
  const res = await api.post('/LibraryCategory', { name: dto.name });
  return res.data as { id: string; name: string };
}

// تعديل اسم فئة موجودة.
// يستخدم معرف الفئة واسمها الجديد لإرسال طلب التحديث.
export async function updateCategory(dto: { id: string; name: string }) {
  const res = await api.put(`/LibraryCategory/${dto.id}`, { name: dto.name });
  return res.data as { id: string; name: string };
}

// حذف فئة من النظام.
// يعيد الاستجابة النهائية من الـ API، وقد تُستخدم لعرض إشعار نجاح أو فشل.
export async function deleteCategory(id: string) {
  const res = await api.delete(`/LibraryCategory/${id}`);
  return res.data;
}

// جلب معلومات حذف الفئة.
// مثل عدد العناصر المرتبطة بهذه الفئة، حتى يتم عرض تأكيد حذف واضح للمستخدم.
export async function getCategoryDeleteInfo(id: string) {
  const res = await api.get(`/LibraryCategory/${id}/delete-info`);
  return res.data as { categoryId: string; categoryName: string; itemsCount: number };
}

// نوع البيانات الذي يعيده خادم الـ API لكل عنصر مكتبة.
// يُستخدم هذا النوع في المكونات والخدمات لتحويل البيانات إلى شكل العرض المناسب.
export type LibraryItemDto = {
  id: string;
  title: string;
  content: string;
  imageUrl?: string | null;
  sources?: string | null;
  shortDescription?: string | null;
  createdAt?: string | null;
  categoryId?: string;
  categoryName?: string | null;
};

// جلب عناصر المكتبة الخاصة بفئة معينة.
// هذا يتيح عرض قائمة المقالات المرتبطة بفئة مختارة.
export async function getItemsByCategory(categoryId: string): Promise<LibraryItemDto[]> {
  const res = await api.get(`/Library/category/${categoryId}/items`);
  return res.data as LibraryItemDto[];
}

// جلب عنصر معين من المكتبة بواسطة معرفه.
// يستخدم عادة عند فتح صفحة التحرير أو عرض تفاصيل المقال.
export async function getItem(itemId: string) {
  const res = await api.get(`/Library/item/${itemId}`);
  return res.data;
}

// إنشاء عنصر مكتبة جديد مع دعم رفع الصور.
// يتم إرسال FormData لأن العنصر قد يحتوي على ملف صورة.
export async function createItem(formData: FormData) {
  const res = await api.post('/Library/item', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  });
  return res.data;
}

// تحديث عنصر مكتبة موجود.
// يستخدم أيضاً FormData لدعم تحديث الصورة أو بقية الحقول.
export async function updateItem(itemId: string, formData: FormData) {
  const res = await api.put(`/Library/item/${itemId}`, formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  });
  return res.data;
}

// حذف عنصر من المكتبة بواسطة المعرف.
// هذا الطلب يُرسَل عند تأكيد المستخدم لحذف المقال.
export async function deleteItem(itemId: string) {
  const res = await api.delete(`/Library/item/${itemId}`);
  return res.data;
}

// حل رابط الصورة ليصبح رابطًا كاملاً.
// إذا كان الرابط يبدأ بـ http/https يُستخدم كما هو.
// أما إذا كان مسارًا نسبيًا، يُضاف إليه API_BASE لبناء الرابط الكامل.
export function resolveImageUrl(path?: string | null) {
  if (!path) return undefined;
  try {
    const p = path as string;
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    return `${API_BASE}${p.startsWith('/') ? '' : '/'}${p}`;
  } catch {
    return undefined;
  }
}
