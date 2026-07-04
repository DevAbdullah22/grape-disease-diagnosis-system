// TreatmentManagement.tsx
// هذا الملف هو نقطة التجميع الرئيسية لصفحة إدارة خطط العلاج.
// يربط بين الحالة (hooks) وواجهة المستخدم (components) ويعرض المحتوى النهائي.

import { Card, CardContent } from "../../../components/ui/card";
import { Button } from "../../../components/ui/button";
import { resolveImageUrl } from "../../library/api/libraryApi";
import { useTreatmentManagement } from "../hooks/useTreatmentManagement";
import { LoadingSpinner } from "../../../components/LoadingSpinner";
import { ConfirmActionDialog } from "../../../components/ui/confirm-action-dialog";
import { TreatmentHeader } from "./TreatmentHeader";
import { TreatmentList } from "./TreatmentList";
import { TreatmentEditorDialog } from "./TreatmentEditorDialog";
import { DeleteTreatmentDialog } from "./DeleteTreatmentDialog";
import { TreatmentUiProvider } from "./TreatmentUiProvider";

export function TreatmentManagement() {
  // نقرة واحدة تجمع كل الحالة والدوال من hook مركزي واحد.
  const {
    diseases,
    treatmentPlans,
    isLoading,
    diseasesError,
    plansLoadError,
    stepImageFile,
    savingOrders,
    isTouchDevice,
    isFormOpen,
    editingPlan,
    searchTerm,
    setSearchTerm,
    diseaseFilter,
    setDiseaseFilter,
    expandedTextIds,
    setExpandedTextIds,
    isStepFormOpen,
    isSavingStep,
    editingStep,
    dragInfo,
    dragOver,
    setDragOver,
    planFormData,
    setPlanFormData,
    stepFormData,
    setStepFormData,
    expandedStepId,
    stepFormActiveTab,
    setStepFormActiveTab,
    addToast,
    confirmModal,
    setConfirmModal,
    plansOrderDirty,
    planErrors,
    setPlanErrors,
    isSavingPlan,
    isClosePlanDialogOpen,
    setIsClosePlanDialogOpen,
    stepErrors,
    setStepErrors,
    confirmInput,
    setConfirmInput,
    fetchAll,
    closePlanModal,
    handleOpenPlanForm,
    handleCloseWithConfirm,
    handleOpenStepForm,
    handleCloseStepForm,
    handleSavePlan,
    handleSaveStep,
    handleDeletePlan,
    handleDeleteStep,
    handleMoveStep,
    handleSaveStepsOrder,
    handleStepImageChange,
    handleDragStart,
    handleDragOver,
    handleDrop,
    handleDragEnd,
    toggleExpanded,
    filteredPlans,
    canSaveStep,
    canSavePlan
  } = useTreatmentManagement();

  // دالة مساعدة لتحويل النص إلى regex آمن.
  const escapeRegExp = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

  // دالة تساعد على تمييز نتائج البحث في النص المعروض.
  // إذا كان هناك مصطلح بحث، سيتم تغليفه بعنصر <mark>.
  const highlightMatch = (text: string, term: string) => {
    if (!term) return <>{text}</>;
    const regex = new RegExp(`(${escapeRegExp(term)})`, "gi");
    const parts = String(text).split(regex);
    return (
      <>
        {parts.map((part, i) =>
          i % 2 === 1 ? (
            <mark key={i} className="bg-yellow-200 px-0">
              {part}
            </mark>
          ) : (
            <span key={i}>{part}</span>
          )
        )}
      </>
    );
  };

  // دالة لتوسيع/طي النص الطويل مع زر قراءة المزيد.
  const toggleExpandText = (id: string) =>
    setExpandedTextIds((s) => ({ ...s, [id]: !s[id] }));

  const renderTruncated = (
    text: string | undefined,
    id: string,
    limit = 180
  ) => {
    const t = text || "—";
    // إذا النص قصير أو لا يوجد نص، نُرجع النص مباشرةً.
    if (t === "—" || t.length <= limit)
      return <>{highlightMatch(t, searchTerm)}</>;

    // إذا النص طويل، نعرض جزءًا محدودًا مع زر لتوسيعه.
    const expanded = !!expandedTextIds[id];
    return (
      <>
        <div className="text-sm text-gray-700">
          {highlightMatch(
            expanded ? t : `${t.slice(0, limit).trim()}...`,
            searchTerm
          )}
        </div>
        <button
          type="button"
          onClick={() => toggleExpandText(id)}
          className="text-sm text-blue-600 underline mt-1"
        >
          {expanded ? "أقل" : "اقرأ المزيد"}
        </button>
      </>
    );
  };

  // هذا الكائن يمرر الدوال والحالة للمكونات الفرعية عبر Context.
  const uiContextValue = {
    searchTerm,
    highlightMatch,
    renderTruncated,
    isTouchDevice,
    plansOrderDirty,
    savingOrders,
    dragInfo,
    dragOver,
    setDragOver,
    expandedStepId,
    handleSaveStepsOrder,
    handleOpenStepForm,
    handleDragStart,
    handleDragOver,
    handleDrop,
    handleDragEnd,
    toggleExpanded,
    handleDeleteStep,
    handleMoveStep,
    handleOpenPlanForm,
    handleDeletePlan,
    resolveImageUrl
  };

  return (
    // تغليف المكونات الفرعية بسياق UI
    <TreatmentUiProvider value={uiContextValue}>
      <div className="p-6 space-y-6">
        {/* رأس الصفحة: البحث وإضافة خطة علاج جديدة */}
        <TreatmentHeader
          diseases={diseases}
          searchTerm={searchTerm}
          setSearchTerm={setSearchTerm}
          diseaseFilter={diseaseFilter}
          setDiseaseFilter={setDiseaseFilter}
          handleOpenPlanForm={handleOpenPlanForm}
        />

        {/* عرض أخطاء التحميل إذا كانت موجودة */}
        {(diseasesError || plansLoadError) && !isLoading && (
          <div className="space-y-3">
            {diseasesError && (
              <Card className="border-red-200 bg-red-50">
                <CardContent
                  role="alert"
                  aria-live="assertive"
                  className="p-4 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between"
                >
                  <div>
                    <p className="text-sm font-semibold text-red-800">
                      تعذر تحميل قائمة الأمراض
                    </p>
                    <p className="text-sm text-red-700">{diseasesError}</p>
                  </div>
                  <Button
                    size="sm"
                    variant="outline"
                    className="border-red-300 text-red-700"
                    onClick={() => fetchAll({ force: true })}
                  >
                    إعادة المحاولة
                  </Button>
                </CardContent>
              </Card>
            )}
            {plansLoadError && (
              <Card className="border-amber-200 bg-amber-50">
                <CardContent
                  role="alert"
                  aria-live="assertive"
                  className="p-4 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between"
                >
                  <div>
                    <p className="text-sm font-semibold text-amber-800">
                      تعذر تحميل بعض الخطط
                    </p>
                    <p className="text-sm text-amber-700">{plansLoadError}</p>
                  </div>
                  <Button
                    size="sm"
                    variant="outline"
                    className="border-amber-300 text-amber-700"
                    onClick={() => fetchAll({ force: true })}
                  >
                    إعادة المحاولة
                  </Button>
                </CardContent>
              </Card>
            )}
          </div>
        )}

        {/* عرض عنصر التحميل أثناء جلب البيانات */}
        {isLoading && (
          <Card>
            <CardContent
              role="status"
              aria-live="polite"
              aria-busy="true"
              className="p-6 text-center"
            >
              <LoadingSpinner />
              <p className="text-gray-600 mt-2">جاري تحميل البيانات...</p>
            </CardContent>
          </Card>
        )}

        {/* قائمة الخطط المرشحة بعد الفلترة والبحث */}
        <TreatmentList
          filteredPlans={filteredPlans}
          isLoading={isLoading}
          diseases={diseases}
          fetchAll={fetchAll}
        />

        {/* نماذج إضافة/تعديل الخطة والخطوة */}
        <TreatmentEditorDialog
          planModalProps={{
            isFormOpen,
            editingPlan,
            planFormData,
            setPlanFormData,
            planErrors,
            setPlanErrors,
            diseases,
            treatmentPlans,
            isSavingPlan,
            handleSavePlan,
            handleCloseWithConfirm,
            canSavePlan
          }}
          stepModalProps={{
            isStepFormOpen,
            isSavingStep,
            editingStep,
            handleCloseStepForm,
            stepFormActiveTab,
            setStepFormActiveTab,
            stepFormData,
            setStepFormData,
            setStepErrors,
            stepErrors,
            stepImageFile,
            handleStepImageChange,
            handleSaveStep,
            canSaveStep
          }}
        />

        {/* تأكيد إغلاق النموذج عند وجود تغييرات غير محفوظة */}
        <ConfirmActionDialog
          open={isClosePlanDialogOpen}
          onOpenChange={setIsClosePlanDialogOpen}
          title="فقدان التغييرات غير المحفوظة"
          description="لديك بيانات غير محفوظة في نموذج الخطة. إذا أغلقت الآن سيتم فقدانها."
          confirmLabel="نعم، إغلاق بدون حفظ"
          cancelLabel="العودة للنموذج"
          tone="warning"
          contentClassName="bg-gray-50"
          onConfirm={() => {
            setIsClosePlanDialogOpen(false);
            closePlanModal();
          }}
        />

        {/* حوار تأكيد الحذف العام المستخدم لحذف الخطة أو الخطوة */}
        <DeleteTreatmentDialog
          confirmModal={confirmModal}
          setConfirmModal={setConfirmModal}
          confirmInput={confirmInput}
          setConfirmInput={setConfirmInput}
          addToast={addToast}
        />
      </div>
    </TreatmentUiProvider>
  );
}
