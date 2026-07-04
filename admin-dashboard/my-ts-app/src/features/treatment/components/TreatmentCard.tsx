import { Card, CardContent, CardHeader, CardTitle } from "../../../components/ui/card";
import { Button } from "../../../components/ui/button";
import { Badge } from "../../../components/ui/badge";
import { Edit2, Trash2 } from "lucide-react";
import { TreatmentStepsSection } from "./TreatmentStepsSection";
import { useTreatmentUi } from "./TreatmentUiContext";
import type { TreatmentPlan } from "../types";

interface TreatmentCardProps {
  plan: TreatmentPlan;
}

// بطاقة عرض خطة العلاج الفردية.
// تحتوي على العنوان، معلومات المرض، عدد الخطوات، والفاصل الزمني.
// كما توفر أزرار التعديل والحذف لكل خطة.
export function TreatmentCard({ plan }: TreatmentCardProps) {
  const {
    searchTerm,
    highlightMatch,
    handleOpenPlanForm,
    handleDeletePlan
  } = useTreatmentUi();

  return (
    <Card className="hover:shadow-lg transition-shadow">
      <CardHeader className="border-b bg-gradient-to-r from-green-50 to-emerald-50">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div className="flex-1">
            <div className="flex flex-wrap items-center gap-2 sm:gap-3 mb-2">
              {/* اسم الخطة مع إبراز الكلمات المطابقة لبحث المستخدم */}
              <CardTitle className="text-xl sm:text-2xl text-green-800">
                {highlightMatch(plan.name, searchTerm)}
              </CardTitle>

              {/* اسم المرض المرتبط بالخطة */}
              <Badge className="bg-green-600 text-white">
                {highlightMatch(plan.diseaseName, searchTerm)}
              </Badge>

              {/* عدد الخطوات في الخطة */}
              <Badge
                variant="outline"
                className="text-blue-600 border-blue-300"
              >
                {plan.steps.length} خطوات
              </Badge>

              {/* الفاصل الزمني بين الجرعات */}
              <Badge
                variant="outline"
                className="text-orange-600 border-orange-300 text-sm"
              >
                فاصل {plan.doseIntervalDays} يوم
              </Badge>
            </div>
          </div>

          {/* أزرار تعديل وحذف الخطة */}
          <div className="flex gap-2 self-end sm:self-auto">
            <Button
              onClick={() => handleOpenPlanForm(plan)}
              variant="outline"
              size="sm"
              className="text-blue-600 hover:text-blue-700"
              aria-label={`تعديل الخطة ${plan.name}`}
            >
              <Edit2 className="h-4 w-4" />
            </Button>
            <Button
              onClick={() => handleDeletePlan(plan.id)}
              variant="outline"
              size="sm"
              className="text-red-600 hover:text-red-700"
              aria-label={`حذف الخطة ${plan.name}`}
            >
              <Trash2 className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </CardHeader>

      {/* جزء عرض خطوات الخطة وتفاعل المستخدم معها */}
      <CardContent className="p-6">
        <TreatmentStepsSection plan={plan} />
      </CardContent>
    </Card>
  );
}
