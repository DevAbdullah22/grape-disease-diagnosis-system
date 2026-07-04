// شاشة إضافة أو تحرير محتوى المكتبة الزراعية.
// هذا الملف يجمع مكونات تحرير المحتوى ويستخدم hook منفصل لإدارة الحالة والعمليات.
import { Button } from '../../../components/ui/button';
import { ConfirmActionDialog } from '../../../components/ui/confirm-action-dialog';
import { ArrowRight, Save } from 'lucide-react';
import { CategorySelector } from '../components/CategorySelector';
import { ContentForm } from '../components/ContentForm';
import { ImageUploader } from '../components/ImageUploader';
import { SourceList } from '../components/SourceList';
import { useLocation, useNavigate } from 'react-router-dom';
import { useContentEditor } from '../hooks/useContentEditor';
import { getSourceHostname, isTrustedSourceDomain, isValidSecureSourceUrl } from '../utils/urlUtils';
import type { ContentItem } from '../types/library.types';

interface AddContentScreenProps {
  onAddContent?: (content: ContentItem) => void;
  editingContent?: ContentItem | null;
  onUpdateContent?: (content: ContentItem) => void;
}

export function AddContentScreen(props: AddContentScreenProps) {
  const location = useLocation();

  // الصفحة قد تُفتح لتحرير عنصر موجود أو لإضافة عنصر جديد.
  // في حالة التحرير، يُرسل العنصر عبر state عبر `navigate(...)`.
  const editingContent = location.state?.editingContent;

  // استخدام مفتاح فريد لإعادة إنشاء المكون عندما يتغير العنصر الجاري تحريره.
  const editorKey = editingContent?.id ? `library-content-${editingContent.id}` : 'library-content-new';

  return <AddContentScreenBody key={editorKey} {...props} editingContent={editingContent} />;
}

function AddContentScreenBody(props: AddContentScreenProps) {
  const navigate = useNavigate();

  // استخدام hook مركزي لإدارة حالة النموذج، صلاحية البيانات، رفع الصورة، المصادر، الفئة، وحفظ العنصر.
  const {
    formData,
    errors,
    imagePreview,
    showNewCategory,
    categoriesState,
    isCreatingCategory,
    isSaving,
    canSave,
    missing,
    isEditMode,
    fileInputRef,
    contentRef,
    isLeaveDialogOpen,
    setIsLeaveDialogOpen,
    newCategoryError,
    sources,
    setErrors,
    setShowNewCategory,
    setNewCategoryError,
    updateForm,
    handleCreateCategoryNow,
    handleImageUpload,
    removeImage,
    addSource,
    updateSource,
    removeSource,
    insertFormatting,
    handleSave,
    handleCancel: checkUnsavedChanges
  } = useContentEditor(props);

  // ارتفاع المحرر قابل للتعديل من خلال المتغير.
  const editorHeight = 'h-[500px] md:h-[50vh]';

  // حفظ المحتوى. إذا نجح، نرجع إلى شاشة المكتبة.
  const onSave = async () => {
    const success = await handleSave();
    if (success) {
      navigate('/admin/library');
    }
  };

  // إلغاء التحرير. إذا لا يوجد تغييرات غير محفوظة أو تم التأكد من تجاهلها، نعود للشاشة السابقة.
  const onCancel = () => {
    const canLeave = checkUnsavedChanges();
    if (canLeave) {
      navigate('/admin/library');
    }
  };

  return (
    <div dir="rtl" lang="ar" className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-4xl mx-auto">
        {/* رأس الصفحة مع زر العودة والهدف من الشاشة */}
        <div className="flex items-center justify-between mb-8">
          <div className="flex items-center gap-4">
            <Button
              variant="outline"
              size="sm"
              onClick={onCancel}
              className="flex items-center gap-2"
            >
              <ArrowRight className="h-4 w-4" />
              العودة
            </Button>
            <h1 className="text-3xl text-gray-900">{isEditMode ? 'تحرير المحتوى' : 'إضافة محتوى جديد'}</h1>
          </div>
        </div>

        <div className="space-y-8">
          {/* مكون رفع الصورة وتعزيز معاينة الصورة */}
          <ImageUploader
            imagePreview={imagePreview}
            fileInputRef={fileInputRef}
            onImageUpload={handleImageUpload}
            onRemoveImage={removeImage}
          />

          {/* نموذج البيانات الأساسية والمحتوى مع قسم اختيار الفئة */}
          <ContentForm
            formData={formData}
            updateForm={updateForm}
            errors={errors}
            setErrors={setErrors}
            contentRef={contentRef}
            editorHeight={editorHeight}
            onInsertFormatting={insertFormatting}
            categorySection={
              <CategorySelector
                formData={formData}
                updateForm={updateForm}
                errors={errors}
                setErrors={setErrors}
                categoriesState={categoriesState}
                showNewCategory={showNewCategory}
                setShowNewCategory={setShowNewCategory}
                isCreatingCategory={isCreatingCategory}
                newCategoryError={newCategoryError}
                setNewCategoryError={setNewCategoryError}
                onCreateCategoryNow={handleCreateCategoryNow}
              />
            }
          />

          {/* قائمة المصادر مع التحقق من صحة الرابط والعرض */}
          <SourceList
            sources={sources}
            errors={errors}
            onAddSource={addSource}
            onUpdateSource={updateSource}
            onRemoveSource={removeSource}
            isValidSecureSourceUrl={isValidSecureSourceUrl}
            getSourceHostname={getSourceHostname}
            isTrustedSourceDomain={isTrustedSourceDomain}
          />

          {/* عرض رسائل الحقول الناقصة إذا لم يكن النموذج صالحًا */}
          {!canSave && missing.length > 0 && (
            <div className="text-sm text-gray-500 mb-2">
              {missing.map((msg, idx) => (
                <div key={idx}>• {msg}</div>
              ))}
            </div>
          )}

          {/* أزرار الإلغاء والحفظ */}
          <div className="flex gap-4 justify-start">
            <Button
              variant="outline"
              onClick={onCancel}
              className="px-8"
            >
              إلغاء
            </Button>
            <Button
              onClick={onSave}
              disabled={!canSave || isSaving || isCreatingCategory}
              className="px-8 bg-green-600 hover:bg-green-700 flex items-center gap-2"
            >
              {/* مؤشر تحميل يظهر أثناء حفظ النموذج أو إنشاء فئة */}
              {(isSaving || isCreatingCategory) && (
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
              )}
              <Save className="h-4 w-4" />
              {isCreatingCategory ? 'إنشاء الفئة...' : isSaving ? 'جاري الحفظ...' : (isEditMode ? 'حفظ التغييرات' : 'حفظ المحتوى')}
            </Button>
          </div>
        </div>
      </div>

      {/* حوار تأكيد الخروج عند وجود تغييرات غير محفوظة */}
      <ConfirmActionDialog
        open={isLeaveDialogOpen}
        onOpenChange={setIsLeaveDialogOpen}
        title="تجاهل التغييرات؟"
        description="لديك تغييرات غير محفوظة. إذا خرجت الآن سيتم فقدان جميع التعديلات التي أجريتها."
        confirmLabel="نعم، تجاهل التغييرات"
        cancelLabel="الاستمرار في التحرير"
        tone="warning"
        contentClassName="bg-gray-50"
        onConfirm={() => {
          setIsLeaveDialogOpen(false);
          navigate('/admin/library');
        }}
      />
    </div>
  );
}
