import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { toast } from "sonner";
import { useDiseases } from "./internal/useDiseases";
import { useStepReorder } from "./internal/useStepReorder";
import { useTreatmentPlans } from "./internal/useTreatmentPlans";
import { useTreatmentSteps } from "./internal/useTreatmentSteps";
import type { ConfirmModalState, StepTab, ToastType } from "../types";

// هذا hook هو نقطة التجميع لإدارة ميزة العلاج.
// يجمع بين تحميل الأمراض، إدارة الخطط، إدارة الخطوات، وإعادة ترتيب الخطوات.
export function useTreatmentManagement() {
  // حالة البحث الحي والتي يتم تدويرها إلى قيمة مهدأة لتقليل عمليات الفلترة المتكررة.
  const [searchTerm, setSearchTerm] = useState("");
  const [debouncedTerm, setDebouncedTerm] = useState("");

  // حالة تتبع النصوص الموسعة داخل القوائم وتحديثها حسب الحاجة.
  const [expandedTextIds, setExpandedTextIds] = useState<
    Record<string, boolean>
  >({});

  // علامة تبويب نموذج الخطوة: عام أو تفاصيل إضافية.
  const [stepFormActiveTab, setStepFormActiveTab] =
    useState<StepTab>("general");

  // دالة عرض الإشعارات العامة المستخدمة عبر جميع hook الداخلية.
  const addToast = useCallback((type: ToastType, message: string) => {
    switch (type) {
      case "success":
        toast.success(message);
        break;
      case "error":
        toast.error(message);
        break;
      case "warning":
        toast.warning(message);
        break;
    }
  }, []);

  // حالة حوار تأكيد عام، تُستخدم لحذف خطة أو خطوة أو إغلاق النموذج بدون حفظ.
  const [confirmModal, setConfirmModal] = useState<ConfirmModalState>({
    open: false
  });
  const [confirmInput, setConfirmInput] = useState("");
  const [isClosePlanDialogOpen, setIsClosePlanDialogOpen] = useState(false);

  // استدعاء hook تحميل الأمراض من ملف داخلي.
  // هذا hook يعيد قائمة الأمراض وحالة التحميل والفلاتر.
  const diseasesState = useDiseases();
  const {
    diseases,
    isLoading,
    isTouchDevice,
    diseaseFilter,
    setDiseaseFilter,
    error: diseasesError,
    fetchAllData
  } = diseasesState;

  // مرجع لإعادة تحميل البيانات من أي hook داخلي.
  const refreshAllRef = useRef<() => Promise<void>>(async () => {});

  // قيود زمنية تمنع إعادة التحميل المتكرر جدًا.
  const lastFetchAtRef = useRef(0);
  const fetchInFlightRef = useRef(false);

  // استدعاء hook إدارة الخطط الداخلية.
  const plansState = useTreatmentPlans({
    addToast,
    refreshAllRef,
    setConfirmModal
  });
  const {
    treatmentPlans,
    setTreatmentPlans,
    loadPlansByDiseases,
    hasUnsavedChanges,
    loadError: plansLoadError
  } = plansState;

  // استدعاء hook إدارة الخطوات الداخلية، يعتمد على الخطة الحالية.
  const stepsState = useTreatmentSteps({
    treatmentPlans,
    addToast,
    refreshAllRef,
    setConfirmModal
  });

  // استدعاء hook إعادة ترتيب الخطوات لتمكين السحب والإفلات.
  const reorderState = useStepReorder({
    treatmentPlans,
    setTreatmentPlans,
    addToast,
    refreshAllRef
  });

  // دالة تحميل البيانات العامة.
  // تمنع التحميل المتكرر إذا تم استدعاؤها خلال 5 ثوانٍ من آخر تحميل.
  const fetchAll = useCallback(
    async (options?: { force?: boolean }) => {
      const now = Date.now();
      const minIntervalMs = 5000;
      if (
        !options?.force &&
        lastFetchAtRef.current &&
        now - lastFetchAtRef.current < minIntervalMs
      ) {
        return;
      }
      if (fetchInFlightRef.current) return;
      fetchInFlightRef.current = true;
      try {
        await fetchAllData(loadPlansByDiseases, setTreatmentPlans);
      } finally {
        fetchInFlightRef.current = false;
        lastFetchAtRef.current = Date.now();
      }
    },
    [fetchAllData, loadPlansByDiseases, setTreatmentPlans]
  );

  // ربط دالة إعادة التحميل المرجعية بالدالة الفعلية.
  useEffect(() => {
    refreshAllRef.current = () => fetchAll({ force: true });
  }, [fetchAll]);

  // تشغيل التحميل الأولي عند تحميل hook.
  useEffect(() => {
    void fetchAll();
  }, [fetchAll]);

  // قيمة البحث المهدأة لتقليل عمليات الفلترة أثناء الكتابة.
  useEffect(() => {
    const handle = window.setTimeout(() => {
      setDebouncedTerm(searchTerm);
    }, 300);
    return () => window.clearTimeout(handle);
  }, [searchTerm]);

  // عند محاولة إغلاق نموذج الخطة، نتحقق أولاً من وجود تغييرات غير محفوظة.
  const handleCloseWithConfirm = () => {
    if (hasUnsavedChanges) {
      setIsClosePlanDialogOpen(true);
      return;
    }
    plansState.closePlanModal();
  };

  // إعداد القيمة المطبعة الفعلية للبحث.
  const normalizedTerm = debouncedTerm.trim().toLowerCase();

  // فلترة الخطط حسب المرض والنص البحثي.
  const filteredPlans = useMemo(
    () =>
      treatmentPlans.filter((plan) => {
        if (diseaseFilter !== "all" && plan.diseaseId !== diseaseFilter) {
          return false;
        }
        if (!normalizedTerm) return true;

        const includesTerm = (value: string | null | undefined) =>
          (value || "").toLowerCase().includes(normalizedTerm);

        const stepsMatch = plan.steps.some(
          (step) =>
            includesTerm(step.pesticideName) ||
            includesTerm(step.chemicalGroup) ||
            includesTerm(step.dosageInstructions) ||
            includesTerm(step.mixQuantityAndType) ||
            includesTerm(step.safetyInfo) ||
            includesTerm(step.importantNotes)
        );

        return (
          includesTerm(plan.name) ||
          includesTerm(plan.diseaseName) ||
          stepsMatch
        );
      }),
    [diseaseFilter, normalizedTerm, treatmentPlans]
  );

  // إعادة الحالة والدوال للاستخدام في واجهة المستخدم.
  return {
    diseases,
    treatmentPlans,
    isLoading,
    diseasesError,
    plansLoadError,
    stepImageFile: stepsState.stepImageFile,
    savingOrders: reorderState.savingOrders,
    isTouchDevice,
    isFormOpen: plansState.isFormOpen,
    editingPlan: plansState.editingPlan,
    searchTerm,
    setSearchTerm,
    diseaseFilter,
    setDiseaseFilter,
    expandedTextIds,
    setExpandedTextIds,
    isStepFormOpen: stepsState.isStepFormOpen,
    isSavingStep: stepsState.isSavingStep,
    editingStep: stepsState.editingStep,
    dragInfo: reorderState.dragInfo,
    dragOver: reorderState.dragOver,
    setDragOver: reorderState.setDragOver,
    planFormData: plansState.planFormData,
    setPlanFormData: plansState.setPlanFormData,
    stepFormData: stepsState.stepFormData,
    setStepFormData: stepsState.setStepFormData,
    expandedStepId: reorderState.expandedStepId,
    stepFormActiveTab,
    setStepFormActiveTab,
    addToast,
    confirmModal,
    setConfirmModal,
    plansOrderDirty: reorderState.plansOrderDirty,
    planErrors: plansState.planErrors,
    setPlanErrors: plansState.setPlanErrors,
    isSavingPlan: plansState.isSavingPlan,
    isClosePlanDialogOpen,
    setIsClosePlanDialogOpen,
    stepErrors: stepsState.stepErrors,
    setStepErrors: stepsState.setStepErrors,
    confirmInput,
    setConfirmInput,
    fetchAll,
    closePlanModal: plansState.closePlanModal,
    handleOpenPlanForm: plansState.handleOpenPlanForm,
    handleCloseWithConfirm,
    handleOpenStepForm: stepsState.handleOpenStepForm,
    handleCloseStepForm: stepsState.handleCloseStepForm,
    handleSavePlan: plansState.handleSavePlan,
    handleSaveStep: stepsState.handleSaveStep,
    handleDeletePlan: plansState.handleDeletePlan,
    handleDeleteStep: stepsState.handleDeleteStep,
    handleMoveStep: reorderState.handleMoveStep,
    handleSaveStepsOrder: reorderState.handleSaveStepsOrder,
    handleStepImageChange: stepsState.handleStepImageChange,
    handleDragStart: reorderState.handleDragStart,
    handleDragOver: reorderState.handleDragOver,
    handleDrop: reorderState.handleDrop,
    handleDragEnd: reorderState.handleDragEnd,
    toggleExpanded: reorderState.toggleExpanded,
    filteredPlans,
    canSaveStep: stepsState.canSaveStep,
    canSavePlan: plansState.canSavePlan
  };
}
