import { useEffect, useMemo, useRef } from "react";
import type { Dispatch, SetStateAction } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "../../../components/ui/card";
import { Button } from "../../../components/ui/button";
import { Badge } from "../../../components/ui/badge";
import { ImageWithFallback } from "../../../components/figma/ImageWithFallback";
import {
  Plus,
  Edit2,
  Trash2,
  Save,
  X,
  AlertTriangle,
  Info,
  Droplets,
  StickyNote,
  ChevronDown,
  MoveUp,
  MoveDown,
  List
} from "lucide-react";
import { LoadingSpinner } from "../../../components/LoadingSpinner";
import { useTreatmentUi } from "./TreatmentUiContext";
import type {
  StepErrors,
  StepFormData,
  StepTab,
  TreatmentPlan,
  TreatmentStep
} from "../types";

interface TreatmentStepsSectionProps {
  plan: TreatmentPlan;
}

interface TreatmentStepModalProps {
  isStepFormOpen: boolean;
  isSavingStep: boolean;
  editingStep: TreatmentStep | null;
  handleCloseStepForm: () => void;
  stepFormActiveTab: StepTab;
  setStepFormActiveTab: Dispatch<SetStateAction<StepTab>>;
  stepFormData: StepFormData;
  setStepFormData: Dispatch<SetStateAction<StepFormData>>;
  setStepErrors: Dispatch<SetStateAction<StepErrors>>;
  stepErrors: StepErrors;
  stepImageFile: File | null;
  handleStepImageChange: (file: File | null) => void;
  handleSaveStep: () => void;
  canSaveStep: boolean;
}

// مكون عرض قسم الخطوات داخل بطاقة الخطة.
// يعرض أزرار حفظ الترتيب، إضافة خطوة، والجدول التفصيلي لكل خطوة.
export function TreatmentStepsSection({
  plan
}: TreatmentStepsSectionProps) {
  const {
    isTouchDevice,
    plansOrderDirty,
    savingOrders,
    dragInfo,
    dragOver,
    setDragOver,
    expandedStepId,
    searchTerm,
    handleSaveStepsOrder,
    handleOpenStepForm,
    handleDragStart,
    handleDragOver,
    handleDrop,
    handleDragEnd,
    toggleExpanded,
    handleDeleteStep,
    handleMoveStep,
    highlightMatch,
    renderTruncated,
    resolveImageUrl
  } = useTreatmentUi();

  // حالات عرض حفظ الترتيب وحالة وجود تغييرات غير محفوظة.
  const isSavingOrder = !!savingOrders[plan.id];
  const isOrderDirty = !!plansOrderDirty[plan.id];

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between mb-4">
        <h3 className="text-lg font-semibold text-gray-800 flex items-center gap-2">
          <List className="h-5 w-5 text-green-600" />
          خطوات العلاج
        </h3>

        <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2 sm:gap-3 w-full sm:w-auto">
          {/* زر حفظ ترتيب الخطوات بعد السحب أو استخدام أزرار التحريك */}
          <Button
            onClick={() => handleSaveStepsOrder(plan.id)}
            size="sm"
            disabled={!plansOrderDirty[plan.id] || !!savingOrders[plan.id]}
            className="w-full sm:w-auto flex items-center justify-center gap-2 bg-amber-500 hover:bg-amber-600 disabled:opacity-50"
          >
            {savingOrders[plan.id] ? <LoadingSpinner /> : <Save className="h-4 w-4" />}
            حفظ ترتيب الخطوات
          </Button>

          {/* زر فتح نموذج إضافة خطوة جديدة */}
          <Button
            onClick={() => handleOpenStepForm(plan.id)}
            size="sm"
            className="w-full sm:w-auto bg-green-600 hover:bg-green-700 flex items-center justify-center gap-2"
          >
            <Plus className="h-4 w-4" />
            إضافة خطوة
          </Button>
        </div>
      </div>
      {isTouchDevice && (
        <p className="text-xs text-gray-500 -mt-2 mb-2">
          للترتيب في الجوال استخدم أزرار أعلى/أسفل لكل خطوة ثم اضغط "حفظ ترتيب
          الخطوات".
        </p>
      )}
      {/* حالة حفظ ترتيب الخطوات */}
      {isSavingOrder ? (
        <div
          role="status"
          aria-live="polite"
          className="flex items-center gap-2 text-blue-700 bg-blue-50 border border-blue-200 px-3 py-2 rounded-md text-sm"
        >
          <LoadingSpinner />
          جارٍ حفظ ترتيب الخطوات...
        </div>
      ) : (
        isOrderDirty && (
          <div
            role="status"
            aria-live="polite"
            className="flex items-center gap-2 text-amber-700 bg-amber-50 border border-amber-200 px-3 py-2 rounded-md text-sm"
          >
            <AlertTriangle className="h-4 w-4" />
            لم يتم حفظ ترتيب الخطوات بعد.
          </div>
        )
      )}

      {plan.steps.length === 0 ? (
        <div className="text-center py-8 bg-gray-50 rounded-lg">
          <Info className="h-12 w-12 text-gray-400 mx-auto mb-2" />
          <p className="text-gray-600">لا توجد خطوات علاجية</p>
          <Button
            onClick={() => handleOpenStepForm(plan.id)}
            size="sm"
            variant="outline"
            className="mt-3"
          >
            إضافة الخطوة الأولى
          </Button>
        </div>
      ) : (
        <>
          {/* عرض كل خطوة بترتيبها، مع دعم السحب والإفلات على أجهزة غير اللمس */}
          {[...plan.steps]
            .sort((a, b) => a.stepOrder - b.stepOrder)
            .map((step, index) => {
              const isOpen = expandedStepId === step.id;
              const isDragOverHere = !!(
                dragOver &&
                dragOver.planId === plan.id &&
                dragOver.index === index
              );
              return (
                <div
                  key={step.id}
                  draggable={!isTouchDevice}
                  onDragStart={(e) => {
                    if (!isTouchDevice) {
                      handleDragStart(e, plan.id, step.id, index);
                    }
                  }}
                  onDragOver={(e) => {
                    if (!isTouchDevice) {
                      handleDragOver(e, plan.id, index);
                    }
                  }}
                  onDrop={(e) => {
                    if (!isTouchDevice) {
                      handleDrop(e, plan.id, index);
                    }
                  }}
                  onDragEnd={handleDragEnd}
                  className={`border border-gray-200 rounded-lg overflow-hidden ${isDragOverHere ? "ring-2 ring-dashed ring-green-400" : ""}`}
                >
                  <div
                    dir="rtl"
                    className="w-full flex flex-col-reverse sm:flex-row items-start sm:items-center gap-3 sm:gap-4 p-3 sm:p-4 bg-white"
                  >
                    <button
                      type="button"
                      onClick={() => toggleExpanded(step.id)}
                      aria-expanded={isOpen}
                      aria-controls={`step-details-${step.id}`}
                      className={`flex-1 w-full sm:w-auto flex items-center gap-3 text-left ${isTouchDevice ? "cursor-default" : "cursor-grab"}`}
                    >
                      <div
                        className={`transform transition-transform duration-200 ${isOpen ? "rotate-180" : "rotate-0"}`}
                      >
                        <ChevronDown className="h-5 w-5 text-gray-400" />
                      </div>
                      <div className="w-12 h-12 rounded-full bg-green-600 text-white flex items-center justify-center font-semibold text-lg">
                        {step.stepOrder}
                      </div>
                      <div className="text-left min-w-0">
                        <div className="flex items-center gap-2">
                          <h4 className="text-sm font-semibold text-gray-900">
                            {highlightMatch(step.pesticideName, searchTerm)}
                          </h4>
                          <Badge className="bg-purple-100 text-purple-700 border-purple-300 text-sm">
                            {step.chemicalGroup}
                          </Badge>
                        </div>
                      </div>
                    </button>

                    <div className="flex w-full sm:w-auto items-center justify-end gap-2">
                      {/* أزرار تعديل وحذف الخطوة */}
                      <Button
                        onClick={() => handleOpenStepForm(plan.id, step)}
                        variant="outline"
                        size="sm"
                        className="text-blue-600"
                        aria-label={`تعديل الخطوة ${step.stepOrder}`}
                      >
                        <Edit2 className="h-4 w-4" />
                      </Button>
                      <Button
                        onClick={() => handleDeleteStep(plan.id, step.id)}
                        variant="outline"
                        size="sm"
                        className="text-red-600"
                        aria-label={`حذف الخطوة ${step.stepOrder}`}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                      <div className="flex flex-col gap-1">
                        {/* أزرار تحريك الخطوة للأعلى والأسفل مع تعطيلها عند الحدود */}
                        <Button
                          onClick={() => handleMoveStep(plan.id, step.id, "up")}
                          disabled={index === 0}
                          variant="outline"
                          size="sm"
                          className="h-8 w-8 sm:h-7 sm:w-7 p-0"
                          aria-label={`تحريك الخطوة ${step.stepOrder} للأعلى`}
                        >
                          <MoveUp className="h-4 w-4" />
                        </Button>
                        <Button
                          onClick={() => handleMoveStep(plan.id, step.id, "down")}
                          disabled={index === plan.steps.length - 1}
                          variant="outline"
                          size="sm"
                          className="h-8 w-8 sm:h-7 sm:w-7 p-0"
                          aria-label={`تحريك الخطوة ${step.stepOrder} للأسفل`}
                        >
                          <MoveDown className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  </div>

                  <div
                    id={`step-details-${step.id}`}
                    className={`overflow-hidden transition-[max-height,opacity] duration-300 px-4 ${isOpen ? "max-h-[1000px] py-4 opacity-100" : "max-h-0 opacity-0"}`}
                  >
                    <div className="flex gap-4">
                      <div className="w-24 h-24 rounded-lg overflow-hidden bg-gray-100 flex-shrink-0">
                        {step.pesticideImageUrl ? (
                          <ImageWithFallback
                            src={resolveImageUrl(step.pesticideImageUrl)}
                            alt={step.pesticideName}
                            className="w-full h-full object-cover"
                          />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center text-gray-300">
                            —
                          </div>
                        )}
                      </div>

                      <div className="flex-1 space-y-3 text-sm">
                        <div className="grid md:grid-cols-2 gap-3">
                          <div className="bg-blue-50 rounded-lg p-3">
                            <div className="flex items-center gap-2 mb-1">
                              <Droplets className="h-4 w-4 text-blue-600" />
                              <div className="font-medium text-blue-800">
                                طريقة الاستخدام
                              </div>
                            </div>
                            <div className="text-blue-700">
                              {renderTruncated(
                                step.dosageInstructions,
                                `step-dosage-${step.id}`,
                                200
                              )}
                            </div>
                          </div>

                          <div className="bg-green-50 rounded-lg p-3">
                            <div className="flex items-center gap-2 mb-1">
                              <Info className="h-4 w-4 text-green-600" />
                              <div className="font-medium text-green-800">
                                كمية الخلط
                              </div>
                            </div>
                            <div className="text-green-700">
                              {renderTruncated(
                                step.mixQuantityAndType,
                                `step-mix-${step.id}`,
                                120
                              )}
                            </div>
                          </div>
                        </div>

                        <div className="bg-orange-50 rounded-lg p-3">
                          <div className="flex items-center gap-2 mb-1">
                            <AlertTriangle className="h-4 w-4 text-orange-600" />
                            <div className="font-medium text-orange-800">
                              معلومات الأمان
                            </div>
                          </div>
                          <div className="text-orange-700 whitespace-pre-line">
                            {renderTruncated(
                              step.safetyInfo,
                              `step-safety-${step.id}`,
                              200
                            )}
                          </div>
                        </div>

                        {step.importantNotes && (
                          <div className="bg-yellow-50 rounded-lg p-3">
                            <div className="flex items-center gap-2 mb-1">
                              <StickyNote className="h-4 w-4 text-yellow-600" />
                              <div className="font-medium text-yellow-800">
                                ملاحظات مهمة
                              </div>
                            </div>
                            <div className="text-yellow-700 whitespace-pre-line">
                              {renderTruncated(
                                step.importantNotes,
                                `step-notes-${step.id}`,
                                200
                              )}
                            </div>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          {!isTouchDevice && (
            <div
              onDragOver={(e) => {
                if (dragInfo?.planId === plan.id) {
                  e.preventDefault();
                  setDragOver({
                    planId: plan.id,
                    index: plan.steps.length
                  });
                }
              }}
              onDrop={(e) => handleDrop(e, plan.id, plan.steps.length)}
              className={`h-6 rounded ${dragOver && dragOver.planId === plan.id && dragOver.index === plan.steps.length ? "bg-green-100" : ""}`}
            />
          )}
        </>
      )}
    </div>
  );
}

// نافذة النموذج الخاصة بإضافة أو تعديل خطوة.
// تُنشأ بصورة شرطية فقط عندما تكون مفتوحة، وتتحكم في التركيز وعرض معاينة الصورة.
export function TreatmentStepModal({
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
}: TreatmentStepModalProps) {
  const titleId = "treatment-step-modal-title";
  const firstFieldRef = useRef<HTMLInputElement | null>(null);
  const previousFocusRef = useRef<HTMLElement | null>(null);
  const previewUrl = useMemo(
    () => (stepImageFile ? URL.createObjectURL(stepImageFile) : null),
    [stepImageFile]
  );

  useEffect(() => {
    if (!previewUrl) return;
    return () => {
      URL.revokeObjectURL(previewUrl);
    };
  }, [previewUrl]);

  useEffect(() => {
    if (!isStepFormOpen) return;
    previousFocusRef.current = document.activeElement as HTMLElement | null;
    const timer = window.setTimeout(() => {
      firstFieldRef.current?.focus();
    }, 0);
    return () => {
      window.clearTimeout(timer);
      previousFocusRef.current?.focus();
    };
  }, [isStepFormOpen]);

  if (!isStepFormOpen) return null;

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby={titleId}
      className="fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center z-50 p-2 sm:p-4"
    >
      <Card className="w-full max-w-3xl max-h-[95dvh] bg-white rounded-2xl overflow-y-auto">
        <CardHeader className="border-b sticky top-0 bg-white z-10">
          <div className="flex items-center justify-between">
            <CardTitle id={titleId}>
              {editingStep ? "تعديل الخطوة العلاجية" : "إضافة خطوة علاجية جديدة"}
            </CardTitle>
            <Button
              onClick={handleCloseStepForm}
              variant="ghost"
              size="sm"
              aria-label="إغلاق نموذج الخطوة"
            >
              <X className="h-5 w-5" />
            </Button>
          </div>
        </CardHeader>
        <CardContent className="p-4 sm:p-6">
          <div className="mb-4">
            {/* تبويب النموذج لإظهار أقسام مختلفة من بيانات الخطوة */}
            <div className="flex gap-2 rtl:space-x-reverse overflow-auto">
              <button
                type="button"
                onClick={() => setStepFormActiveTab("general")}
                className={`px-3 py-2 rounded-md ${stepFormActiveTab === "general" ? "bg-green-600 text-white" : "bg-gray-100 text-gray-700"}`}
              >
                معلومات عامة
              </button>
              <button
                type="button"
                onClick={() => setStepFormActiveTab("dosage")}
                className={`px-3 py-2 rounded-md ${stepFormActiveTab === "dosage" ? "bg-green-600 text-white" : "bg-gray-100 text-gray-700"}`}
              >
                الجرعة والخلط
              </button>
              <button
                type="button"
                onClick={() => setStepFormActiveTab("safety")}
                className={`px-3 py-2 rounded-md ${stepFormActiveTab === "safety" ? "bg-green-600 text-white" : "bg-gray-100 text-gray-700"}`}
              >
                الأمان
              </button>
              <button
                type="button"
                onClick={() => setStepFormActiveTab("notes")}
                className={`px-3 py-2 rounded-md ${stepFormActiveTab === "notes" ? "bg-green-600 text-white" : "bg-gray-100 text-gray-700"}`}
              >
                ملاحظات
              </button>
            </div>
          </div>
          {stepFormActiveTab === "general" && (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  ترتيب الخطوة
                </label>
                {editingStep ? (
                  <div className="text-sm text-gray-700">
                    الترتيب الحالي:{" "}
                    <span className="font-medium">{stepFormData.stepOrder}</span>{" "}
                    — لتغييره استخدم أزرار السهم أعلى/أسفل في قائمة الخطوات ثم
                    اضغط "حفظ ترتيب الخطوات".
                  </div>
                ) : (
                  <div className="text-sm text-gray-700">
                    سيتم تعيين الترتيب تلقائياً كخطوة رقم{" "}
                    <span className="font-medium">{stepFormData.stepOrder}</span>{" "}
                    بعد الحفظ. لتغييره لاحقًا استخدم أزرار السهم ثم اضغط "حفظ ترتيب
                    الخطوات".
                  </div>
                )}
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  اسم المبيد <span className="text-red-500">*</span>
                </label>
                <input
                  ref={firstFieldRef}
                  type="text"
                  value={stepFormData.pesticideName}
                  onChange={(e) => {
                    setStepFormData({
                      ...stepFormData,
                      pesticideName: e.target.value
                    });
                    setStepErrors((se) => {
                      const n = { ...se };
                      delete n.pesticideName;
                      return n;
                    });
                  }}
                  className="w-full px-4 py-2 border rounded-lg"
                  placeholder="مثال: بروبيكونازول 25% EC"
                />
                {stepErrors.pesticideName && (
                  <p className="text-sm text-red-600 mt-1">
                    {stepErrors.pesticideName}
                  </p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  المجموعة الكيميائية <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  className="w-full px-4 py-2 border rounded-lg"
                  placeholder="أدخل المجموعة الكيميائية"
                  value={stepFormData.chemicalGroup || ""}
                  onChange={(e) => {
                    setStepFormData((s) => ({
                      ...s,
                      chemicalGroup: e.target.value
                    }));
                    setStepErrors((se) => {
                      const n = { ...se };
                      delete n.chemicalGroup;
                      return n;
                    });
                  }}
                />
                {stepErrors.chemicalGroup && (
                  <p className="text-sm text-red-600 mt-1">
                    {stepErrors.chemicalGroup}
                  </p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  ارفع صورة للمبيد<span className="text-red-500">*</span>
                </label>
                <div className="flex items-start gap-4">
                  <div className="w-24">
                    <input
                      type="file"
                      accept="image/*"
                      onChange={(e) =>
                        handleStepImageChange(e.target.files?.[0] || null)
                      }
                    />
                    {stepImageFile && previewUrl && (
                      <div className="mt-2 w-24 h-24 rounded overflow-hidden border">
                        <img
                          src={previewUrl}
                          className="w-full h-full object-cover"
                          alt="preview"
                        />
                      </div>
                    )}
                    {stepErrors.image && (
                      <p className="text-sm text-red-600 mt-1">
                        {stepErrors.image}
                      </p>
                    )}
                  </div>
                </div>
              </div>
            </div>
          )}
          {stepFormActiveTab === "dosage" && (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  طريقة استخدام المبيد <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  className="w-full px-4 py-2 border rounded-lg"
                  placeholder="وصف الجرعة/الطريقة"
                  value={stepFormData.dosageInstructions || ""}
                  onChange={(e) =>
                    setStepFormData((s) => ({
                      ...s,
                      dosageInstructions: e.target.value
                    }))
                  }
                />
                {stepErrors.dosageInstructions && (
                  <p className="text-sm text-red-600 mt-1">
                    {stepErrors.dosageInstructions}
                  </p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  كمية ونوع الخلط <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={stepFormData.mixQuantityAndType}
                  onChange={(e) =>
                    setStepFormData((s) => ({
                      ...s,
                      mixQuantityAndType: e.target.value
                    }))
                  }
                  className="w-full px-4 py-2 border rounded-lg"
                  placeholder="مثال: 75-50 مل /100 لتر"
                />
                {stepErrors.mixQuantityAndType && (
                  <p className="text-sm text-red-600 mt-1">
                    {stepErrors.mixQuantityAndType}
                  </p>
                )}
              </div>
            </div>
          )}

          {stepFormActiveTab === "safety" && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                معلومات الأمان <span className="text-red-500">*</span>
              </label>
              <textarea
                rows={4}
                value={stepFormData.safetyInfo}
                onChange={(e) =>
                  setStepFormData((s) => ({
                    ...s,
                    safetyInfo: e.target.value
                  }))
                }
                className="w-full px-4 py-2 border rounded-lg"
                placeholder="فترة الأمان: 15 يوم قبل حصد الثمار"
              />
              {stepErrors.safetyInfo && (
                <p className="text-sm text-red-600 mt-1">{stepErrors.safetyInfo}</p>
              )}
            </div>
          )}

          {stepFormActiveTab === "notes" && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                ملاحظات مهمة
              </label>
              <textarea
                rows={5}
                value={stepFormData.importantNotes}
                onChange={(e) =>
                  setStepFormData((s) => ({
                    ...s,
                    importantNotes: e.target.value
                  }))
                }
                className="w-full px-4 py-2 border rounded-lg"
                placeholder="أدخل كل ملاحظة في سطر منفصل"
              />
            </div>
          )}

          <div className="flex flex-col-reverse sm:flex-row gap-3 pt-4 border-t mt-4 sticky bottom-0 bg-white pb-1">
            {/* زر حفظ النموذج يقوم بالتحقق الداخلي في hook قبل الاستدعاء */}
            <Button
              onClick={handleSaveStep}
              disabled={!canSaveStep || isSavingStep}
              title={Object.values(stepErrors).find(Boolean) || ""}
              className={`flex-1 ${!canSaveStep || isSavingStep ? "opacity-50 cursor-not-allowed" : "bg-green-600 hover:bg-green-700"} flex items-center justify-center gap-2`}
            >
              <Save className="h-4 w-4" />
              {editingStep ? "حفظ التعديلات" : "إضافة الخطوة"}
            </Button>
            {/* زر إغلاق النموذج دون حفظ */}
            <Button
              onClick={handleCloseStepForm}
              variant="outline"
              className="flex-1 w-full"
            >
              إلغاء
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
