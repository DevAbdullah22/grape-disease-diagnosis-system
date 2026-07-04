import { TreatmentCard } from "./TreatmentCard";
import { EmptyState } from "./EmptyState";
import { useTreatmentUi } from "./TreatmentUiContext";
import type {
  Disease,
  TreatmentPlan
} from "../types";

interface TreatmentPlanListProps {
  filteredPlans: TreatmentPlan[];
  isLoading: boolean;
  diseases: Disease[];
  fetchAll: (options?: { force?: boolean }) => Promise<void>;
}

// مكون يعرض قائمة الخطط العلاجية المفلترة.
// يستخدم الـ filter / search الذي يوفره hook الإدارة ويعرض كل خطة بداخل بطاقة.
export function TreatmentPlanList({
  filteredPlans,
  isLoading,
  diseases,
  fetchAll
}: TreatmentPlanListProps) {
  // يستخدم سياق واجهة المستخدم لفتح نافذة إنشاء/تعديل خطة.
  const { handleOpenPlanForm } = useTreatmentUi();

  return (
    <div className="space-y-6">
      {/* عرض كل خطة كـ TreatmentCard واحدة */}
      {filteredPlans.map((plan) => (
        <TreatmentCard key={plan.id} plan={plan} />
      ))}

      {/* إذا لم توجد خطط بعد انتهاء التحميل، نعرض الحالة الفارغة مع زر إنشائها */}
      {filteredPlans.length === 0 && !isLoading && (
        <EmptyState
          diseases={diseases}
          fetchAll={fetchAll}
          handleOpenPlanForm={() => handleOpenPlanForm()}
        />
      )}
    </div>
  );
}
