import { useCallback, useState } from "react";
import type { Dispatch, MutableRefObject, SetStateAction } from "react";
import {
  createPlan,
  deletePlan,
  getPlansByDisease,
  updatePlan
} from "../../services/treatmentService";
import type { TreatmentPlanDto, TreatmentStepDto } from "../../../../types/treatment";
import type {
  ConfirmModalState,
  Disease,
  PlanErrors,
  PlanFormData,
  ToastType,
  TreatmentPlan
} from "./types";

// معلمات الـ hook: دالة عرض التنبيه، مرجع لإعادة تحميل البيانات، ودالة إعداد حوار التأكيد.
interface UseTreatmentPlansParams {
  addToast: (type: ToastType, message: string) => void;
  refreshAllRef: MutableRefObject<() => Promise<void>>;
  setConfirmModal: Dispatch<SetStateAction<ConfirmModalState>>;
}

// القيم الافتراضية لنموذج إنشاء/تعديل خطة.
const DEFAULT_PLAN_FORM_DATA: PlanFormData = {
  name: "",
  diseaseId: "",
  doseIntervalDays: 7
};

// تحويل DTO الخاص بالخادم إلى نوع خطوة العلاج المستخدم في الواجهة.
function mapTreatmentStepDto(step: TreatmentStepDto, planId: string) {
  return {
    id: step.id ?? `${planId}-${step.stepOrder ?? 0}`,
    stepOrder: step.stepOrder ?? 1,
    pesticideName: step.pesticideName ?? "",
    chemicalGroup: step.chemicalGroup ?? "",
    pesticideImageUrl: step.pesticideImageUrl ?? "",
    dosageInstructions: step.dosageInstructions ?? "",
    mixQuantityAndType: step.mixQuantityAndType ?? "",
    safetyInfo: step.safetyInfo ?? "",
    importantNotes: step.importantNotes ?? ""
  };
}

// تحويل DTO خطة العلاج إلى النموذج الداخلي المستخدم في التطبيق.
function mapTreatmentPlanDto(plan: TreatmentPlanDto, disease: Disease): TreatmentPlan {
  const planId = plan.id ?? "";

  return {
    id: planId,
    diseaseId: plan.diseaseId ?? disease.id,
    diseaseName: plan.diseaseName ?? disease.name ?? plan.disease?.name ?? "",
    name: plan.name ?? plan.planName ?? "",
    doseIntervalDays: plan.doseIntervalDays ?? 7,
    steps: (plan.steps ?? []).map((step) => mapTreatmentStepDto(step, planId))
  };
}

// دالة مساعدة للحصول على رسالة خطأ من مصادر مختلفة.
function getErrorMessage(err: unknown): string | null {
  if (!err) return null;
  if (typeof err === "string") return err;
  if (err instanceof Error) return err.message;

  if (typeof err === "object" && err !== null) {
    const e = err as {
      response?: { data?: { message?: unknown } };
      message?: unknown;
      [key: string]: unknown;
    };

    if (
      e.response?.data &&
      typeof e.response.data === "object" &&
      "message" in e.response.data &&
      e.response.data.message
    ) {
      return String(e.response.data.message);
    }
    if (e.message) return String(e.message);
  }

  return null;
}

// hook مخصص لإدارة قائمة خطط العلاج ونموذج إنشاء/تعديل الخطط.
export function useTreatmentPlans({
  addToast,
  refreshAllRef,
  setConfirmModal
}: UseTreatmentPlansParams) {
  const [treatmentPlans, setTreatmentPlans] = useState<TreatmentPlan[]>([]);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingPlan, setEditingPlan] = useState<TreatmentPlan | null>(null);
  const [isSavingPlan, setIsSavingPlan] = useState(false);
  const [planFormData, setPlanFormData] = useState<PlanFormData>(DEFAULT_PLAN_FORM_DATA);
  const [planErrors, setPlanErrors] = useState<PlanErrors>({});
  const [loadError, setLoadError] = useState<string | null>(null);

  // تحميل خطط العلاج لكل الأمراض المعروفة، وإرجاع مصفوفة الخطط.
  const loadPlansByDiseases = useCallback(async (ds: Disease[]) => {
    setLoadError(null);
    const failedDiseases: string[] = [];

    // نحاول تحميل الخطط لكل مرض على حدة حتى نتمكن من متابعة التحميل رغم فشل بعض الأمراض.
    const groupedPlans = await Promise.all(
      ds.map(async (disease) => {
        try {
          const plans = ((await getPlansByDisease(disease.id)) as TreatmentPlanDto[]) ?? [];
          return plans.map((plan) => mapTreatmentPlanDto(plan, disease));
        } catch {
          if (disease.name) {
            failedDiseases.push(disease.name);
          } else {
            failedDiseases.push("مرض غير معروف");
          }
          return [];
        }
      })
    );

    // إذا فشلت بعض الأمراض في التحميل، نعرض رسالة خطأ موحدة.
    if (failedDiseases.length > 0) {
      const unique = Array.from(new Set(failedDiseases));
      const label = unique.join("، ");
      const message = `تعذر تحميل خطط الأمراض التالية: ${label}`;
      setLoadError(message);
      addToast("error", message);
    }

    return groupedPlans.flat();
  }, [addToast]);

  // التحقق من صحة بيانات نموذج الخطة قبل الحفظ.
  const validatePlanForm = (): boolean => {
    const errors: typeof planErrors = {};

    if (!planFormData.name.trim()) errors.name = "اسم الخطة مطلوب";
    if (!planFormData.diseaseId) errors.diseaseId = "يجب اختيار المرض";
    if (
      !Number.isFinite(planFormData.doseIntervalDays) ||
      planFormData.doseIntervalDays <= 0
    ) {
      errors.doseIntervalDays = "يجب إدخال فاصل جرعات أكبر من صفر";
    }

    // حماية إضافية: لا نسمح بتغيير المرض إذا كانت الخطة تحتوي على خطوات موجودة.
    if (
      editingPlan &&
      editingPlan.steps.length > 0 &&
      planFormData.diseaseId !== editingPlan.diseaseId
    ) {
      errors.diseaseId = "لا يمكن تغيير المرض لخطة تحتوي خطوات";
    }

    // التحقق من عدم وجود خطة أخرى بنفس المرض.
    const diseaseUsed = treatmentPlans.some(
      (p) => p.diseaseId === planFormData.diseaseId && p.id !== editingPlan?.id
    );

    if (diseaseUsed) errors.diseaseId = "هذا المرض مرتبط بخطة علاج أخرى";

    // التحقق من عدم وجود خطة بنفس الاسم ونفس المرض.
    const duplicate = treatmentPlans.some(
      (p) =>
        p.name.trim().toLowerCase() ===
          planFormData.name.trim().toLowerCase() &&
        p.diseaseId === planFormData.diseaseId &&
        p.id !== editingPlan?.id
    );

    if (duplicate) errors.name = "يوجد خطة بنفس الاسم لهذا المرض";

    setPlanErrors(errors);
    return Object.keys(errors).length === 0;
  };

  // إغلاق نموذج الخطة وإعادة الحالة الافتراضية.
  const closePlanModal = () => {
    setIsFormOpen(false);
    setEditingPlan(null);
    setPlanFormData(DEFAULT_PLAN_FORM_DATA);
    setPlanErrors({});
    setIsSavingPlan(false);
  };

  // فتح نموذج إنشاء خطة جديدة.
  const openCreatePlanModal = () => {
    setEditingPlan(null);
    setPlanFormData(DEFAULT_PLAN_FORM_DATA);
    setPlanErrors({});
    setIsSavingPlan(false);
    setIsFormOpen(true);
  };

  // فتح نموذج تعديل خطة موجودة وملئ الحقول بقيمها.
  const openEditPlanModal = (plan: TreatmentPlan) => {
    setEditingPlan(plan);
    setPlanFormData({
      name: plan.name,
      diseaseId: plan.diseaseId,
      doseIntervalDays: plan.doseIntervalDays ?? 7
    });
    setPlanErrors({});
    setIsSavingPlan(false);
    setIsFormOpen(true);
  };

  // دالة واحدة لفتح النموذج سواء كان إنشاء جديد أو تعديل.
  const handleOpenPlanForm = (plan?: TreatmentPlan) => {
    if (plan) {
      openEditPlanModal(plan);
      return;
    }
    openCreatePlanModal();
  };

  // التحقق مما إذا كانت هناك تغييرات غير محفوظة في نموذج الخطة.
  const hasUnsavedChanges = editingPlan
    ? planFormData.name.trim() !== editingPlan.name.trim() ||
      planFormData.diseaseId !== editingPlan.diseaseId ||
      planFormData.doseIntervalDays !== editingPlan.doseIntervalDays
    : !!planFormData.name.trim() ||
      !!planFormData.diseaseId ||
      planFormData.doseIntervalDays !== DEFAULT_PLAN_FORM_DATA.doseIntervalDays;

  // حفظ النموذج إما بإنشاء خطة جديدة أو تحديث خطة موجودة.
  const handleSavePlan = async () => {
    if (isSavingPlan) return;
    if (!validatePlanForm()) return;

    const diseaseUsed = treatmentPlans.some(
      (p) => p.diseaseId === planFormData.diseaseId && p.id !== editingPlan?.id
    );

    if (diseaseUsed) {
      setPlanErrors((e) => ({
        ...e,
        diseaseId: "تم استخدام هذا المرض في خطة أخرى"
      }));
      return;
    }

    setIsSavingPlan(true);

    try {
      const safeDoseIntervalDays =
        Number.isFinite(planFormData.doseIntervalDays) &&
        planFormData.doseIntervalDays > 0
          ? planFormData.doseIntervalDays
          : 7;

      if (editingPlan) {
        // تحديث خطة موجودة فقط بالاسم والفاصل.
        await updatePlan({
          id: editingPlan.id,
          name: planFormData.name.trim(),
          doseIntervalDays: safeDoseIntervalDays
        });
        addToast("success", "تم تعديل الخطة بنجاح");
      } else {
        // إنشاء خطة جديدة.
        await createPlan({
          diseaseId: planFormData.diseaseId,
          name: planFormData.name.trim(),
          doseIntervalDays: safeDoseIntervalDays
        });
        addToast("success", "تم إضافة الخطة بنجاح");
      }

      closePlanModal();
      await refreshAllRef.current();
    } catch (err) {
      const message = getErrorMessage(err);
      addToast("error", message || "حدث خطأ أثناء حفظ الخطة");
    } finally {
      setIsSavingPlan(false);
    }
  };

  // حذف خطة مع تأكيد قوي إذا كانت الخطة تحتوي على خطوات.
  const handleDeletePlan = (id: string) => {
    const plan = treatmentPlans.find((p) => p.id === id);
    const stepsCount = plan?.steps?.length || 0;

    if (stepsCount > 0) {
      // إذا كان هناك خطوات، نطلب تأكيد name للحذف.
      setConfirmModal({
        open: true,
        title: "حذف خطة العلاج (تأكيد قوي)",
        description: `هذه الخطة تحتوي على ${stepsCount} خطوة/خطوات وسيتم حذفها كلها. هذا الإجراء لا يمكن التراجع عنه. للمزيد من الحماية اكتب اسم الخطة أدناه للتأكيد.`,
        requiredConfirmText: plan?.name || "",
        onConfirm: async () => {
          try {
            await deletePlan(id);
            addToast("success", "تم حذف الخطة");
            await refreshAllRef.current();
          } catch (err) {
            const message = getErrorMessage(err);
            addToast(
              "error",
              message ? `خطأ أثناء حذف الخطة: ${message}` : "خطأ أثناء حذف الخطة"
            );
          }
        }
      });
    } else {
      // حذف خطة بدون خطوات بدون تأكيد الاسم.
      setConfirmModal({
        open: true,
        title: "حذف خطة العلاج",
        description: "سيتم حذف الخطة. هذا الإجراء لا يمكن التراجع عنه.",
        onConfirm: async () => {
          try {
            await deletePlan(id);
            addToast("success", "تم حذف الخطة");
            await refreshAllRef.current();
          } catch (err) {
            const message = getErrorMessage(err);
            addToast(
              "error",
              message ? `خطأ أثناء حذف الخطة: ${message}` : "خطأ أثناء حذف الخطة"
            );
          }
        }
      });
    }
  };

  // صفة تحدد ما إذا كان زر الحفظ يجب أن يكون مفعلًا.
  const canSavePlan =
    !isSavingPlan &&
    !!planFormData.name.trim() &&
    !!planFormData.diseaseId &&
    Number.isFinite(planFormData.doseIntervalDays) &&
    planFormData.doseIntervalDays > 0;

  return {
    treatmentPlans,
    setTreatmentPlans,
    isFormOpen,
    setIsFormOpen,
    editingPlan,
    setEditingPlan,
    planFormData,
    setPlanFormData,
    planErrors,
    setPlanErrors,
    isSavingPlan,
    setIsSavingPlan,
    defaultPlanFormData: DEFAULT_PLAN_FORM_DATA,
    loadPlansByDiseases,
    loadError,
    closePlanModal,
    handleOpenPlanForm,
    handleSavePlan,
    handleDeletePlan,
    hasUnsavedChanges,
    canSavePlan
  };
}
