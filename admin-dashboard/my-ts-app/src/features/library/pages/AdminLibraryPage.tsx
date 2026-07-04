// صفحة إدارة المكتبة الزراعية للمسؤول.
// تعرض محتوى المكتبة وتتيح البحث والفلاتر وإدارة الفئات وحذف المحتوى.
import { useEffect } from 'react';
import { Button } from '../../../components/ui/button';
import { Input } from '../../../components/ui/input';
import { Badge } from '../../../components/ui/badge';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '../../../components/ui/dialog';
import { ConfirmActionDialog } from '../../../components/ui/confirm-action-dialog';
import { Plus, Edit, Trash2, Search, Loader2 } from 'lucide-react';
import { ViewContentDialog } from '../components/ViewContentDialog';
import { LibraryContentGrid } from '../components/LibraryContentGrid';
import { getCategoryColor } from '../utils/categoryUtils';
import { useNavigate } from 'react-router-dom';
import { useLibraryStore } from '../../../stores/libraryStore';

export function AdminLibraryManagement() {
  // hook التنقل من React Router
  const navigate = useNavigate();

  // استرجاع الحالة والإجراءات من مخزن Zustand الخاص بالمكتبة
  const {
    searchQuery,
    setSearchQuery,
    selectedCategory,
    setSelectedCategory,
    categories,
    contents,
    isLoadingCategories,
    isLoadingItems,
    isDeleting,
    contentToDelete,
    viewingContent,
    isManagingCategories,
    editingCategoryId,
    categoryNameInput,
    categoryToDelete,
    isDeletingCategory,
    preparingDeleteCategoryId,
    loadInitialData,
    deleteContent,
    openManageCategories,
    closeManageCategories,
    startEditCategory,
    saveCategory,
    removeCategory,
    confirmRemoveCategory,
    requestDeleteContent,
    viewContent,
    setViewingContent,
    setCategoryNameInput,
    setContentToDelete,
    setCategoryToDelete,
  } = useLibraryStore();

  // عند تحميل الصفحة لأول مرة، نطلب البيانات المبدئية من الـ store
  useEffect(() => {
    loadInitialData();
  }, [loadInitialData]);

  // فلترة المحتوى بناءً على النص المدخل في البحث والفئة المختارة
  const filteredContents = contents.filter(content => {
    const shortDesc = (content.shortDescription ?? '').toString();
    const matchesSearch = content.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         shortDesc.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCategory = selectedCategory === 'الكل' || content.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  // قائمة الفئات الفعّالة التي تظهر للمستخدم مع زر الكل
  const effectiveCategories = ['الكل', ...categories.map(c => c.name)];

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto p-4 md:p-6 lg:p-8 space-y-6 md:space-y-8">
        {/* رأس الصفحة: العنوان والأزرار */}
        <div className="bg-white rounded-xl shadow-sm p-4 md:p-6">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
              <h1 className="text-2xl md:text-3xl lg:text-4xl font-bold text-gray-900">
                إدارة المكتبة الزراعية
              </h1>
              <p className="text-gray-600 mt-1 md:mt-2 text-sm md:text-base">
                إدارة وتحرير محتوى المكتبة
              </p>
            </div>

            <div className="flex flex-wrap gap-2">
              {/* زر الانتقال إلى صفحة إضافة محتوى جديد */}
              <Button
                onClick={() => navigate('/admin/library/add')}
                className="flex items-center justify-center gap-2 bg-green-600 hover:bg-green-700 w-full md:w-auto px-4 py-2 md:px-6 md:py-3 text-sm md:text-base"
              >
                <Plus className="h-4 w-4 md:h-5 md:w-5" />
                إضافة محتوى جديد
              </Button>

              {/* زر فتح حوار إدارة الفئات */}
              <Button
                onClick={openManageCategories}
                variant="outline"
                className="flex items-center justify-center gap-2 w-full md:w-auto px-4 py-2 md:px-6 md:py-3 text-sm md:text-base text-blue-600 border-blue-600 hover:bg-blue-50"
              >
                إدارة الفئات
              </Button>
            </div>
          </div>
        </div>

        {/* شريط البحث وأزرار فلترة الفئات */}
        <div className="bg-white rounded-xl shadow-sm p-4 md:p-6 space-y-4">
          <div className="relative">
            <Input
              placeholder="البحث في المحتوى..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pr-10 h-10 md:h-11 text-sm md:text-base"
            />
            <Search className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
          </div>

          <div className="flex flex-wrap gap-2 md:gap-3">
            {effectiveCategories.map((category) => (
              <Button
                key={category}
                variant={selectedCategory === category ? 'default' : 'outline'}
                onClick={() => setSelectedCategory(category)}
                disabled={isLoadingCategories}
                className={`text-xs md:text-sm px-3 py-1.5 md:px-4 md:py-2 ${
                  selectedCategory === category
                    ? 'bg-green-500 hover:bg-green-600'
                    : 'hover:bg-green-50'
                }`}
              >
                {category}
              </Button>
            ))}
          </div>
        </div>

        {/* الشبكة التي تعرض العناصر المفلترة */}
        <LibraryContentGrid
          isLoading={isLoadingItems}
          contents={filteredContents}
          onView={viewContent}
          onEdit={(content) => navigate('/admin/library/edit', { state: { editingContent: content } })}
          onDeleteRequest={requestDeleteContent}
          isDeletingId={isDeleting}
        />
      </div>

      {/* حوار إدارة الفئات */}
      <Dialog open={isManagingCategories} onOpenChange={(open) => {
            if (!open) closeManageCategories();
          }}>
        <DialogContent
          className="w-[95vw] md:max-w-2xl max-h-[90vh] overflow-y-auto bg-white rounded-xl"
          dir="rtl"
        >
          <DialogHeader className="border-b pb-4 text-right items-end">
            <DialogTitle className="text-xl md:text-2xl font-bold text-gray-900">
              إدارة الفئات
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-5 pt-2">
            {/* حقل إدخال اسم الفئة وزر الحفظ */}
            <div className="flex flex-col sm:flex-row gap-2">
              <Input
                placeholder="اسم الفئة"
                value={categoryNameInput}
                onChange={(e) => setCategoryNameInput(e.target.value)}
                className="h-10 md:h-11 text-sm md:text-base"
              />
              <Button
                onClick={saveCategory}
                className="bg-blue-600 hover:bg-blue-700 h-10 md:h-11 px-4 text-sm md:text-base"
              >
                {editingCategoryId ? 'تعديل' : 'إضافة'}
              </Button>
            </div>

            {/* قائمة الفئات الحالية مع أزرار التعديل والحذف */}
            <ul className="space-y-2 max-h-72 overflow-y-auto pr-1">
              {categories.map(cat => (
                <li
                  key={cat.id}
                  className="flex items-center justify-between bg-gray-50 border border-gray-100 rounded-lg px-3 py-2"
                >
                  <span className="text-sm md:text-base text-gray-800">{cat.name}</span>
                  <div className="flex gap-2">
                    <Button
                      size="icon"
                      variant="outline"
                      className="h-8 w-8 md:h-9 md:w-9"
                      onClick={() => startEditCategory(cat)}
                      disabled={isDeletingCategory || preparingDeleteCategoryId === cat.id}
                      title="تعديل الفئة"
                    >
                      <Edit className="h-4 w-4" />
                    </Button>
                    <Button
                      size="icon"
                      variant="outline"
                      className="h-8 w-8 md:h-9 md:w-9 text-red-600 hover:bg-red-50"
                      onClick={() => removeCategory(cat)}
                      disabled={isDeletingCategory || preparingDeleteCategoryId === cat.id}
                      title="حذف الفئة"
                    >
                      {/* عرض مؤشر تحميل عند تجهيز الحذف */}
                      {preparingDeleteCategoryId === cat.id ? (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      ) : (
                        <Trash2 className="h-4 w-4" />
                      )}
                    </Button>
                  </div>
                </li>
              ))}
            </ul>

            {/* رسالة عندما لا توجد فئات */}
            {categories.length === 0 && (
              <div className="text-center text-sm text-gray-500 py-4">
                لا توجد فئات حالياً
              </div>
            )}

            <div className="flex justify-end gap-3 pt-3 border-t">
              <Button variant="outline" onClick={closeManageCategories} className="px-5 py-2 text-sm md:text-base">
                إغلاق
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* حوار تأكيد حذف المحتوى */}
      <ConfirmActionDialog
        open={!!contentToDelete}
        onOpenChange={(open) => {
          if (!open) setContentToDelete(null);
        }}
        title="تأكيد حذف المحتوى"
        description="هذا الإجراء نهائي ولا يمكن التراجع عنه."
        confirmLabel="حذف المحتوى"
        cancelLabel="إلغاء"
        loading={typeof contentToDelete?.id === 'string' ? isDeleting === contentToDelete.id : false}
        loadingLabel="جارٍ الحذف..."
        onConfirm={() => {
          if (!contentToDelete) return;
          deleteContent(contentToDelete.id as string);
        }}
        tone="danger"
        contentClassName="bg-gray-50"
      >
        {contentToDelete && (
          <div className="rounded-xl border border-red-100 bg-red-50/70 p-4">
            <div className="flex items-center justify-between gap-3">
              <span className="font-semibold text-gray-900 line-clamp-1">{contentToDelete.title}</span>
              <Badge className={`${getCategoryColor(contentToDelete.category)} text-xs`}>
                {contentToDelete.category}
              </Badge>
            </div>
          </div>
        )}
      </ConfirmActionDialog>

      {/* حوار تأكيد حذف الفئة */}
      <ConfirmActionDialog
        open={!!categoryToDelete}
        onOpenChange={(open) => {
          // عندما يغلق المستخدم الحوار، نعيد تعيين الحالة
          if (!open) setCategoryToDelete(null);
        }}
        title="تأكيد حذف الفئة"
        description="هذا الإجراء نهائي ولا يمكن التراجع عنه."
        confirmLabel="تأكيد الحذف"
        cancelLabel="إلغاء"
        loading={isDeletingCategory}
        loadingLabel="جارٍ الحذف..."
        onConfirm={confirmRemoveCategory}
        tone="danger"
        contentClassName="bg-gray-50"
      >
        {categoryToDelete && (
          <div className="rounded-xl border border-red-100 bg-red-50/70 p-4">
            <div className="flex items-center justify-between gap-3">
              <span className="font-semibold text-gray-900">{categoryToDelete.name}</span>
              <span className="inline-flex items-center rounded-full border border-red-200 bg-white px-2.5 py-1 text-xs font-medium text-red-700">
                {categoryToDelete.itemsCount} عنصر
              </span>
            </div>
            <p className="mt-2 text-xs leading-6 text-red-700">
              {categoryToDelete.itemsCount > 0
                ? 'سيتم حذف الفئة وجميع العناصر المرتبطة بها من النظام.'
                : 'لن يتم حذف أي عنصر محتوى مرتبط.'}
            </p>
          </div>
        )}
      </ConfirmActionDialog>

      {/* حوار عرض المقالة كاملة */}
      <ViewContentDialog
        content={viewingContent}
        onClose={() => setViewingContent(null)}
      />
    </div>
  );
}
