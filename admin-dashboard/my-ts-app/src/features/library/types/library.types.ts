// تعريف أنواع TypeScript المستخدمة في ميزة مكتبة المحتوى.
// هذه الأنواع تربط الواجهة بالمكونات، الخدمة، وطبقات API.

export interface Category {
  id: string;
  name: string;
}

// تمثل عنصر محتوى مكتوب في المكتبة.
// يمكن أن تظهر هذه البيانات في الشبكة، في حوار العرض، أو تُستخدم عند التعديل.
export interface ContentItem {
  id: string | number;
  title: string;
  shortDescription?: string;
  category: string;
  type?: string;
  content: string;
  image?: string | null;
  sources?: string[];
  createdAt?: string;
  imageFile?: File;
}

// حالة النموذج المستخدمة في شاشة إضافة/تحرير المحتوى.
// تشمل الحقول الأساسية التي يُملؤها المستخدم.
export interface FormDataState {
  title: string;
  shortDescription: string;
  category: string;
  content: string;
  newCategory: string;
}

// معلمات دالة resolveCategoryId في الخدمة.
// تتضمن حالة الفئات الحالية، الفئة المختارة، بيانات النموذج، ودالة إنشاء الفئة إن وُجدت.
export interface ResolveCategoryIdParams {
  categoriesState: Category[];
  selectedCategoryId: string;
  formData: FormDataState;
  createCategory?: (dto: { name: string }) => Promise<Category>;
}

// نتيجة دالة resolveCategoryId التي تحدد معرف الفئة النهائي المستخدم للحفظ.
// status يشرح الحالة:
// - existing: فئة موجودة تم استخدامها.
// - reused: تم إعادة استخدام فئة مطابقة من القائمة.
// - created: تم إنشاء فئة جديدة باسم المستخدم.
// - default-created: أنشأنا فئة افتراضية لعدم وجود أي فئات.
export interface ResolveCategoryIdResult {
  categoryId: string;
  status: 'existing' | 'reused' | 'created' | 'default-created';
  category?: Category;
  nextFormData?: FormDataState;
  nextSelectedCategoryId?: string;
  nextShowNewCategory?: boolean;
}

// نتيجة التحقق من مصادر الروابط.
// filteredSources هي المصادر النظيفة الصالحة.
// invalidSourceValues هي المصادر التي فشلت في التحقق.
export interface SourceValidationResult {
  filteredSources: string[];
  invalidSourceValues: string[];
}

// معلمات إنشاء عنصر مكتبة جديد.
// تُنقل من واجهة المستخدم إلى خدمة الحفظ.
export interface CreateLibraryItemParams {
  formData: FormDataState;
  categoryId: string;
  filteredSources: string[];
  imageFile: File | null;
  imagePreview: string;
}

// معلمات تحديث عنصر موجود.
// ترث نفس حقول الإنشاء وتضيف العنصر الجاري تحريره.
export interface UpdateLibraryItemParams extends CreateLibraryItemParams {
  editingContent: ContentItem;
}

// خطأ خدمة مخصص يسمح بفصل أنواع الأخطاء المتعلقة بإنشاء الفئات.
export interface LibraryServiceError extends Error {
  code?: 'CREATE_NEW_CATEGORY_FAILED' | 'CREATE_DEFAULT_CATEGORY_FAILED';
}
