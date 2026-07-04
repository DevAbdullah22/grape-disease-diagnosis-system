import { useEffect, useRef } from "react";
import type { Dispatch, SetStateAction } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "../../../components/ui/card";
import { Button } from "../../../components/ui/button";
import { ChevronDown, Save, X } from "lucide-react";
import type {
  Disease,
  PlanErrors,
  PlanFormData,
  TreatmentPlan
} from "../types";

interface TreatmentPlanModalProps {
  isFormOpen: boolean;
  editingPlan: TreatmentPlan | null;
  planFormData: PlanFormData;
  setPlanFormData: Dispatch<SetStateAction<PlanFormData>>;
  planErrors: PlanErrors;
  setPlanErrors: Dispatch<SetStateAction<PlanErrors>>;
  diseases: Disease[];
  treatmentPlans: TreatmentPlan[];
  isSavingPlan: boolean;
  handleSavePlan: () => void;
  handleCloseWithConfirm: () => void;
  canSavePlan: boolean;
}

export function TreatmentPlanModal({
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
}: TreatmentPlanModalProps) {
  const titleId = "treatment-plan-modal-title";
  const firstFieldRef = useRef<HTMLSelectElement | null>(null);
  const previousFocusRef = useRef<HTMLElement | null>(null);

  useEffect(() => {
    if (!isFormOpen) return;
    previousFocusRef.current = document.activeElement as HTMLElement | null;
    const timer = window.setTimeout(() => {
      firstFieldRef.current?.focus();
    }, 0);

    return () => {
      window.clearTimeout(timer);
      previousFocusRef.current?.focus();
    };
  }, [isFormOpen]);

  if (!isFormOpen) return null;

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby={titleId}
      className="fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center z-50 p-2 sm:p-4"
    >
      <Card className="w-full max-w-2xl max-h-[95dvh] bg-white rounded-2xl overflow-y-auto">
        <CardHeader className="border-b sticky top-0 bg-white z-10">
          <div className="flex items-center justify-between">
            <CardTitle id={titleId}>
              {editingPlan ? "تعديل خطة العلاج" : "إضافة خطة علاج جديدة"}
            </CardTitle>
            <Button
              onClick={handleCloseWithConfirm}
              variant="ghost"
              size="sm"
              aria-label="إغلاق نموذج الخطة"
            >
              <X className="h-5 w-5" />
            </Button>
          </div>
        </CardHeader>
        <CardContent className="p-4 sm:p-6 space-y-5 sm:space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              المرض المستهدف <span className="text-red-500">*</span>
            </label>
            <div className="relative">
              <select
                ref={firstFieldRef}
                value={planFormData.diseaseId}
                disabled={!!editingPlan && editingPlan.steps.length > 0}
                onChange={(e) => {
                  setPlanFormData({
                    ...planFormData,
                    diseaseId: e.target.value
                  });
                  setPlanErrors((pe) => {
                    const n = { ...pe };
                    delete n.diseaseId;
                    return n;
                  });
                }}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500 appearance-none disabled:bg-gray-100 disabled:cursor-not-allowed"
              >
                <option value="">اختر المرض</option>
                {diseases.map((disease) => {
                  const usedByAnotherPlan = treatmentPlans.some(
                    (p) => p.diseaseId === disease.id && p.id !== editingPlan?.id
                  );

                  return (
                    <option
                      key={disease.id}
                      value={disease.id}
                      disabled={usedByAnotherPlan}
                    >
                      {disease.name}
                      {usedByAnotherPlan ? " — مرتبط بخطة أخرى" : ""}
                    </option>
                  );
                })}
              </select>
              <ChevronDown className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400 pointer-events-none" />
            </div>
            {editingPlan && editingPlan.steps.length > 0 && (
              <p className="text-sm text-amber-600 mt-1">
                لا يمكن تغيير المرض لأن هذه الخطة تحتوي خطوات علاجية. لحماية
                البيانات يجب حذف الخطوات أولاً.
              </p>
            )}
            {planErrors.diseaseId && (
              <p className="text-sm text-red-600 mt-1">{planErrors.diseaseId}</p>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              اسم خطة العلاج <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              value={planFormData.name}
              onChange={(e) => {
                setPlanFormData({ ...planFormData, name: e.target.value });
                setPlanErrors((pe) => {
                  const n = { ...pe };
                  delete n.name;
                  return n;
                });
              }}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500"
              placeholder="مثال: خطة مكافحة البياض الدقيقي"
            />
            {planErrors.name && (
              <p className="text-sm text-red-600 mt-1">{planErrors.name}</p>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              الفاصل بين الجرعات (أيام) <span className="text-red-500">*</span>
            </label>
            <input
              type="number"
              min={1}
              value={planFormData.doseIntervalDays}
              onChange={(e) => {
                setPlanFormData({
                  ...planFormData,
                  doseIntervalDays: Number(e.target.value)
                });
                setPlanErrors((pe) => {
                  const n = { ...pe };
                  delete n.doseIntervalDays;
                  return n;
                });
              }}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500"
            />
            {planErrors.doseIntervalDays && (
              <p className="text-sm text-red-600 mt-1">
                {planErrors.doseIntervalDays}
              </p>
            )}
          </div>

          <div className="flex flex-col-reverse sm:flex-row gap-3 pt-4 border-t sticky bottom-0 bg-white pb-1">
            <Button
              onClick={handleSavePlan}
              disabled={!canSavePlan}
              title={Object.values(planErrors).find(Boolean) || ""}
              className={`flex-1 ${!canSavePlan ? "opacity-50 cursor-not-allowed" : "bg-green-600 hover:bg-green-700"} flex items-center justify-center gap-2`}
            >
              <Save className="h-4 w-4" />
              {isSavingPlan
                ? "جارٍ الحفظ..."
                : editingPlan
                  ? "حفظ التعديلات"
                  : "إضافة الخطة"}
            </Button>
            <Button
              onClick={handleCloseWithConfirm}
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
