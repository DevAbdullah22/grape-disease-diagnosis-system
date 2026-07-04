import { useState } from "react";
import type {
  Dispatch,
  DragEvent,
  MutableRefObject,
  SetStateAction
} from "react";
import { reorderSteps } from "../../services/treatmentService";
import type { DragInfo, DragOver, ToastType, TreatmentPlan } from "./types";

// معلمات hook إعادة ترتيب الخطوات.
// هذا hook لا يتحكم مباشرة ببيانات الخطط، بل يستخدم مجموعة الخطط من الأعلى ويعدلها.
interface UseStepReorderParams {
  treatmentPlans: TreatmentPlan[];
  setTreatmentPlans: Dispatch<SetStateAction<TreatmentPlan[]>>;
  addToast: (type: ToastType, message: string) => void;
  refreshAllRef: MutableRefObject<() => Promise<void>>;
}

export function useStepReorder({
  treatmentPlans,
  setTreatmentPlans,
  addToast,
  refreshAllRef
}: UseStepReorderParams) {
  // حالة تحميل حفظ ترتيب الخطوات لكل خطة.
  const [savingOrders, setSavingOrders] = useState<Record<string, boolean>>({});
  // بيانات السحب الحالية أثناء drag & drop.
  const [dragInfo, setDragInfo] = useState<DragInfo | null>(null);
  // موضع العنصر الذي يتم المرور فوقه أثناء السحب.
  const [dragOver, setDragOver] = useState<DragOver | null>(null);
  // علامة على أن ترتيب الخطوات لم يُحفظ بعد لكل خطة.
  const [plansOrderDirty, setPlansOrderDirty] = useState<
    Record<string, boolean>
  >({});
  // خطوة موسعة لعرض تفاصيلها في الواجهة.
  const [expandedStepId, setExpandedStepId] = useState<string | null>(null);

  // فتح/إغلاق تفاصيل خطوة معينة.
  const toggleExpanded = (id: string) =>
    setExpandedStepId((prev) => (prev === id ? null : id));

  // عند بداية السحب، نحفظ بيانات المصدر داخل dataTransfer وحالة drag الحالية.
  const handleDragStart = (
    e: DragEvent,
    planId: string,
    stepId: string,
    index: number
  ) => {
    e.dataTransfer.effectAllowed = "move";
    try {
      e.dataTransfer.setData(
        "application/json",
        JSON.stringify({ planId, stepId, index })
      );
    } catch {
      /* ignore */
    }

    // حفظ بيانات الخطة والخطوة وموقع البداية.
    setDragInfo({ planId, stepId, fromIndex: index });
    setDragOver({ planId, index });
  };

  // أثناء المرور فوق عنصر آخر، نقوم بمنع السلوك الافتراضي وتحديث موقع dragOver.
  const handleDragOver = (e: DragEvent, planId: string, index: number) => {
    if (!dragInfo) return;
    if (dragInfo.planId !== planId) return;
    e.preventDefault();
    if (!dragOver || dragOver.index !== index || dragOver.planId !== planId)
      setDragOver({ planId, index });
  };

  // عند الإفلات، نقرأ بيانات العنصر المصدر ونقوم بإعادة ترتيب الخطوات محليًا.
  const handleDrop = (e: DragEvent, planId: string, toIndex: number) => {
    e.preventDefault();
    if (!dragInfo) return;
    try {
      const payload = JSON.parse(e.dataTransfer.getData("application/json")) as {
        planId: string;
        stepId: string;
        index: number;
      };
      if (payload.planId !== planId) return;

      const fromIndex = payload.index;
      const to = toIndex;
      if (fromIndex === to) return;

      // إعادة ترتيب الخطوات محليًا داخل الخطة.
      setTreatmentPlans((prev) =>
        prev.map((plan) => {
          if (plan.id !== planId) return plan;

          const steps = [...plan.steps]
            .sort((a, b) => a.stepOrder - b.stepOrder)
            .map((step) => ({ ...step }));

          const moved = steps.splice(fromIndex, 1)[0];
          steps.splice(to, 0, moved);

          const reorderedSteps = steps.map((step, i) => ({
            ...step,
            stepOrder: i + 1
          }));

          // علامة على أن الترتيب تغير ولم يُحفظ بعد.
          setPlansOrderDirty((d) => ({ ...d, [planId]: true }));
          addToast("warning", "تم تغيير ترتيب الخطوات ولم يتم الحفظ بعد");

          return { ...plan, steps: reorderedSteps };
        })
      );
    } catch {
      // إذا كانت بيانات السحب غير صحيحة، نتجاهل الخطأ.
    } finally {
      setDragInfo(null);
      setDragOver(null);
    }
  };

  // تنظيف حالة السحب عند انتهاء العملية.
  const handleDragEnd = () => {
    setDragInfo(null);
    setDragOver(null);
  };

  // تحريك خطوة لأعلى أو لأسفل باستخدام أزرار وليس سحب.
  const handleMoveStep = (
    planId: string,
    stepId: string,
    direction: "up" | "down"
  ) => {
    setTreatmentPlans((prev) =>
      prev.map((plan) => {
        if (plan.id === planId) {
          const steps = [...plan.steps]
            .sort((a, b) => a.stepOrder - b.stepOrder)
            .map((step) => ({ ...step }));

          const currentIndex = steps.findIndex((s) => s.id === stepId);
          if (currentIndex === -1) return plan;

          if (
            (direction === "up" && currentIndex === 0) ||
            (direction === "down" && currentIndex === steps.length - 1)
          )
            return plan;

          const targetIndex =
            direction === "up" ? currentIndex - 1 : currentIndex + 1;

          [steps[currentIndex], steps[targetIndex]] = [
            steps[targetIndex],
            steps[currentIndex]
          ];

          const reorderedSteps = steps.map((step, index) => ({
            ...step,
            stepOrder: index + 1
          }));

          setPlansOrderDirty((d) => ({ ...d, [planId]: true }));
          addToast("warning", "تم تغيير ترتيب الخطوات ولم يتم الحفظ بعد");

          return { ...plan, steps: reorderedSteps };
        }
        return plan;
      })
    );
  };

  // دالة مساعدة لأخذ رسالة الخطأ من استجابة الخادم أو أي استثناء.
  const getErrorMessage = (err: unknown): string => {
    if (!err) return "خطأ غير معروف";
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
        return "خطأ غير معروف";
      }
    }

    return "خطأ غير معروف";
  };

  // حفظ ترتيب الخطوات إلى الخادم.
  const handleSaveStepsOrder = async (planId: string) => {
    const plan = treatmentPlans.find((p) => p.id === planId);
    if (!plan) return;

    try {
      setSavingOrders((s) => ({ ...s, [planId]: true }));

      const payload = plan.steps.map((s) => ({
        id: s.id,
        stepOrder: s.stepOrder
      }));

      // التحقق من وجود أرقام ترتيب فريدة قبل إرسال الطلب.
      const orders = payload.map((p) => p.stepOrder);
      if (orders.length !== new Set(orders).size) {
        addToast(
          "error",
          "هناك أرقام ترتيب مكررة. تأكد أن كل خطوة لها ترتيب فريد قبل الحفظ."
        );
        setSavingOrders((s) => ({ ...s, [planId]: false }));
        return;
      }

      await reorderSteps(planId, payload);
      setPlansOrderDirty((d) => ({ ...d, [planId]: false }));
      addToast("success", "تم حفظ ترتيب الخطوات");

      // بعد حفظ الترتيب، يعاد تحميل البيانات من الخادم للتأكد من تزامن الحالة.
      await refreshAllRef.current();
    } catch (err: unknown) {
      const msg = getErrorMessage(err) || "خطأ أثناء حفظ ترتيب الخطوات";
      addToast("error", `خطأ أثناء حفظ ترتيب الخطوات: ${msg}`);
    } finally {
      setSavingOrders((s) => ({ ...s, [planId]: false }));
    }
  };

  return {
    savingOrders,
    dragInfo,
    dragOver,
    setDragOver,
    plansOrderDirty,
    expandedStepId,
    toggleExpanded,
    handleDragStart,
    handleDragOver,
    handleDrop,
    handleDragEnd,
    handleMoveStep,
    handleSaveStepsOrder
  };
}
