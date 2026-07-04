import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";
import { getDiseases } from "../../services/treatmentService";
import type { Disease } from "./types";

// دالة مساعد لجمع رسالة الخطأ من أنواع مختلفة من الاستثناءات.
// الهدف هو توحيد رسالة الخطأ المعروضة للمستخدم.
function getErrorMessage(error: unknown) {
  if (!error) return "خطأ في جلب البيانات من الخادم";
  if (typeof error === "string") return error;
  if (error instanceof Error && error.message) {
    return error.message;
  }

  if (typeof error === "object") {
    const err = error as {
      response?: { data?: { message?: unknown } };
      message?: unknown;
    };
    if (err.response?.data?.message) {
      return String(err.response.data.message);
    }
    if (err.message) return String(err.message);
  }

  return "خطأ في جلب البيانات من الخادم";
}

// دالة للكشف إذا كان الجهاز يدعم اللمس.
// تُستخدم لتحسين تجربة المستخدم عند ترتيب الخطوات في الواجهة.
function detectTouchDevice() {
  if (typeof window === "undefined" || typeof navigator === "undefined") {
    return false;
  }

  const hasCoarsePointer =
    typeof window.matchMedia === "function" &&
    window.matchMedia("(pointer: coarse)").matches;

  return hasCoarsePointer || navigator.maxTouchPoints > 0;
}

// hook مخصص لإدارة بيانات الأمراض.
// يستخدم لجلب قائمة الأمراض ثم تمريرها إلى بقية مكونات نظام العلاج.
export function useDiseases() {
  // قائمة الأمراض التي تُعرض في التصفية وفي نماذج اختيار المرض.
  const [diseases, setDiseases] = useState<Disease[]>([]);
  // حالة التحميل العامة لعملية جلب الأمراض والبيانات المرتبطة.
  const [isLoading, setIsLoading] = useState(false);
  // حالة تحدد ما إذا كان الجهاز يعمل باللمس.
  const [isTouchDevice, setIsTouchDevice] = useState(false);
  // قيمة فلتر الأمراض في واجهة المستخدم.
  const [diseaseFilter, setDiseaseFilter] = useState<string>("all");
  // حالة تخزين رسالة الخطأ في حال فشل جلب الأمراض.
  const [error, setError] = useState<string | null>(null);

  // عند تهيئة الهُوك لأول مرة، نحدد ما إذا كان الجهاز يدعم اللمس.
  useEffect(() => {
    setIsTouchDevice(detectTouchDevice());
  }, []);

  // دالة تحميل عامة تعالج مرحلتين:
  // 1) جلب الأمراض من الخادم
  // 2) تشغيل دالة تحميل البيانات المرتبطة بالأمراض (مثل الخطط)
  const fetchAllData = useCallback(async <T,>(
    loadRelated: (ds: Disease[]) => Promise<T>,
    onRelatedLoaded: (data: T) => void
  ) => {
    try {
      // بدء حالة التحميل وإعادة تعيين الأخطاء السابقة.
      setIsLoading(true);
      setError(null);

      // جلب الأمراض من API.
      const ds = ((await getDiseases()) as Disease[]) ?? [];
      setDiseases(ds);

      // بعد الحصول على الأمراض، نستخدم الدالة الممررة لتحميل البيانات المتعلقة.
      const related = await loadRelated(ds);
      onRelatedLoaded(related);
    } catch (error) {
      // في حال وجود خطأ، نحصل على رسالة مقروءة ونعرضها للمستخدم.
      const message = getErrorMessage(error);
      setError(message);
      toast.error(message);
    } finally {
      // إيقاف حالة التحميل في النهاية، سواء نجحت العملية أو فشلت.
      setIsLoading(false);
    }
  }, []);

  return {
    diseases,
    isLoading,
    isTouchDevice,
    diseaseFilter,
    setDiseaseFilter,
    error,
    fetchAllData
  };
}
