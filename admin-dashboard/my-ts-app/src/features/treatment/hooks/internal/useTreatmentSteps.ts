import { useState } from "react";
import type { Dispatch, MutableRefObject, SetStateAction } from "react";
import { createStep, deleteStep, updateStep } from "../../services/treatmentService";
import type {
  ConfirmModalState,
  StepErrors,
  StepFormData,
  ToastType,
  TreatmentPlan,
  TreatmentStep
} from "./types";

// مدخلات hook: قائمة الخطط الحالية، دالة عرض الإشعارات، مرجع لإعادة تحميل البيانات، ودالة إعداد حوار التأكيد.
interface UseTreatmentStepsParams {
  treatmentPlans: TreatmentPlan[];
  addToast: (type: ToastType, message: string) => void;
  refreshAllRef: MutableRefObject<() => Promise<void>>;
  setConfirmModal: Dispatch<SetStateAction<ConfirmModalState>>;
}

// إنشاء نموذج بيانات فارغ خطوة جديدة.
function createEmptyStepFormData(stepOrder = 1): StepFormData {
  return {
    stepOrder,
    pesticideName: "",
    chemicalGroup: "",
    pesticideImageUrl: "",
    dosageInstructions: "",
    mixQuantityAndType: "",
    safetyInfo: "",
    importantNotes: ""
  };
}

// هذا hook يدير حالة الخطوات داخل خطة علاجية واحدة.
// يوفر فتح النموذج، التحقق من الصحة، التحميل، الحفظ، والحذف.
export function useTreatmentSteps({
  treatmentPlans,
  addToast,
  refreshAllRef,
  setConfirmModal
}: UseTreatmentStepsParams) {
  const [stepImageFile, setStepImageFile] = useState<File | null>(null);
  const [isStepFormOpen, setIsStepFormOpen] = useState(false);
  const [isSavingStep, setIsSavingStep] = useState(false);
  const [editingStep, setEditingStep] = useState<TreatmentStep | null>(null);
  const [currentPlanId, setCurrentPlanId] = useState<string>("");
  const [stepErrors, setStepErrors] = useState<StepErrors>({});
  const [stepFormData, setStepFormData] = useState<StepFormData>(createEmptyStepFormData());

  // التحقق من صحة بيانات نموذج الخطوة.
  // يشمل حقول النص الأساسية، وصورة المبيد عند إنشاء خطوة جديدة.
  const validateStepForm = (): boolean => {
    const errors: typeof stepErrors = {};

    if (!stepFormData.pesticideName?.trim())
      errors.pesticideName = "اسم المبيد مطلوب";
    if (!stepFormData.chemicalGroup?.trim())
      errors.chemicalGroup = "المجموعة الكيميائية مطلوبة";
    if (!stepFormData.dosageInstructions?.trim())
      errors.dosageInstructions = "طريقة الاستخدام مطلوبة";
    if (!stepFormData.mixQuantityAndType?.trim())
      errors.mixQuantityAndType = "كمية ونوع الخلط مطلوبة";
    if (!stepFormData.safetyInfo?.trim())
      errors.safetyInfo = "معلومات الأمان مطلوبة";

    // إذا كانت خطوة جديدة، فالصورة إجبارية.
    if (!editingStep && !stepImageFile) errors.image = "صورة المبيد مطلوبة";

    // التأكد من عدم تكرار اسم المبيد ضمن نفس الخطة.
    const plan = treatmentPlans.find((p) => p.id === currentPlanId);
    if (
      plan &&
      stepFormData.pesticideName &&
      plan.steps.some(
        (s) =>
          s.pesticideName.toLowerCase() ===
            stepFormData.pesticideName!.toLowerCase() &&
          s.id !== editingStep?.id
      )
    ) {
      errors.pesticideName = "يوجد بالفعل خطوة بنفس اسم المبيد في هذه الخطة";
    }

    setStepErrors(errors);
    return Object.keys(errors).length === 0;
  };

  // دالة مساعدة لاستخراج رسالة خطأ من نشاط الشبكة.
  const getErrorMessage = (err: unknown): string | null => {
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

      try {
        return JSON.stringify(e);
      } catch {
        return null;
      }
    }

    return null;
  };

  // معالجة تغيير صورة المبيد.
  // تتحقق من نوع الملف وحجمه، وتقوم بإدارة رسالة الخطأ إذا كان الملف غير صالح.
  const handleStepImageChange = (file: File | null) => {
    if (!file) {
      setStepImageFile(null);
      setStepErrors((se) => {
        const n = { ...se };
        delete n.image;
        return n;
      });
      return;
    }

    const allowed = ["image/jpeg", "image/png", "image/webp", "image/svg+xml"];
    if (!allowed.includes(file.type)) {
      setStepErrors((se) => ({
        ...se,
        image: "نوع الملف غير مدعوم. استخدم JPG/PNG/WebP/SVG"
      }));
      setStepImageFile(null);
      return;
    }

    const maxSize = 2 * 1024 * 1024;
    if (file.size > maxSize) {
      setStepErrors((se) => ({
        ...se,
        image: "حجم الصورة كبير جداً (أقصى 2MB)"
      }));
      setStepImageFile(null);
      return;
    }

    setStepErrors((se) => {
      const n = { ...se };
      delete n.image;
      return n;
    });
    setStepImageFile(file);
  };

  // فتح نموذج الخطوة.
  // إذا كان هناك خطوة موجودة، نملأ النموذج ببياناتها.
  // إذا كانت خطوة جديدة، نحدد ترتيبًا جديدًا تلقائيًا.
  const handleOpenStepForm = (planId: string, step?: TreatmentStep) => {
    setCurrentPlanId(planId);
    setStepErrors({});
    setStepImageFile(null);

    if (step) {
      setEditingStep(step);
      setStepFormData(step);
    } else {
      const plan = treatmentPlans.find((p) => p.id === planId);
      const maxOrder = (plan?.steps || []).reduce(
        (max, s) => Math.max(max, s.stepOrder || 0),
        0
      );
      setEditingStep(null);
      setStepFormData(createEmptyStepFormData(maxOrder + 1));
    }

    setIsStepFormOpen(true);
  };

  // إغلاق نموذج الخطوة وإعادة الحالة إلى الوضع الافتراضي.
  const handleCloseStepForm = () => {
    setIsStepFormOpen(false);
    setEditingStep(null);
    setCurrentPlanId("");
    setStepErrors({});
    setStepImageFile(null);
    setStepFormData(createEmptyStepFormData());
  };

  // حفظ الخطوة الجديدة أو المعدلة.
  const handleSaveStep = async () => {
    if (isSavingStep) return;

    if (!validateStepForm()) {
      addToast("warning", "الرجاء تصحيح أخطاء الخطوة قبل الحفظ");
      return;
    }

    setIsSavingStep(true);
    try {
      const plan = treatmentPlans.find((p) => p.id === currentPlanId);
      const maxOrder = (plan?.steps || []).reduce(
        (max, s) => Math.max(max, s.stepOrder || 0),
        0
      );
      const safeStepOrder = editingStep
        ? stepFormData.stepOrder || 1
        : maxOrder + 1;

      const fd = new FormData();
      if (editingStep) fd.append("Id", editingStep.id);
      fd.append("TreatmentPlanId", currentPlanId);
      fd.append("StepOrder", String(safeStepOrder));
      fd.append("PesticideName", stepFormData.pesticideName || "");
      fd.append("ChemicalGroup", stepFormData.chemicalGroup || "");
      if (stepFormData.pesticideImageUrl)
        fd.append("PesticideImageUrl", stepFormData.pesticideImageUrl);
      fd.append("DosageInstructions", stepFormData.dosageInstructions || "");
      fd.append("MixQuantityAndType", stepFormData.mixQuantityAndType || "");
      fd.append("SafetyInfo", stepFormData.safetyInfo || "");
      if (stepFormData.importantNotes) {
        fd.append("ImportantNotes", stepFormData.importantNotes);
      }
      if (stepImageFile) fd.append("pesticideImage", stepImageFile);

      if (editingStep) {
        await updateStep(fd);
        addToast("success", "تم تحديث الخطوة");
      } else {
        await createStep(fd);
        addToast("success", "تم إنشاء الخطوة");
      }

      await refreshAllRef.current();
      handleCloseStepForm();
    } catch (err) {
      const msg = getErrorMessage(err);
      addToast(
        "error",
        msg ? `خطأ أثناء حفظ الخطوة: ${msg}` : "خطأ أثناء حفظ الخطوة"
      );
    } finally {
      setIsSavingStep(false);
    }
  };

  // حذف خطوة بعد تأكيد المستخدم.
  const handleDeleteStep = (planId: string, stepId: string) => {
    void planId;
    setConfirmModal({
      open: true,
      title: "حذف خطوة",
      description:
        "حذف هذه الخطوة إجراء لا يمكن التراجع عنه. هل تريد المتابعة؟",
      onConfirm: async () => {
        try {
          await deleteStep(stepId);
          addToast("success", "تم حذف الخطوة");
          await refreshAllRef.current();
        } catch (err) {
          const msg = getErrorMessage(err);
          addToast(
            "error",
            msg ? `خطأ أثناء حذف الخطوة: ${msg}` : "خطأ أثناء حذف الخطوة"
          );
        }
      }
    });
  };

  // حالة تفعيل زر حفظ الخطوة.
  const canSaveStep =
    !isSavingStep &&
    !!stepFormData.pesticideName?.trim() &&
    !!stepFormData.chemicalGroup?.trim() &&
    !!stepFormData.dosageInstructions?.trim() &&
    !!stepFormData.mixQuantityAndType?.trim() &&
    !!stepFormData.safetyInfo?.trim() &&
    (!!editingStep || !!stepImageFile);

  return {
    stepImageFile,
    setStepImageFile,
    isStepFormOpen,
    isSavingStep,
    editingStep,
    stepErrors,
    setStepErrors,
    stepFormData,
    setStepFormData,
    handleStepImageChange,
    handleOpenStepForm,
    handleCloseStepForm,
    handleSaveStep,
    handleDeleteStep,
    canSaveStep
  };
}
