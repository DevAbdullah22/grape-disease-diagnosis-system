import { Card, CardContent } from "../../../components/ui/card";
import { Button } from "../../../components/ui/button";
import { Info } from "lucide-react";

interface Disease {
  id: string;
  name: string;
}

interface EmptyStateProps {
  diseases: Disease[];
  fetchAll: (options?: { force?: boolean }) => Promise<void>;
  handleOpenPlanForm: () => void;
}

// يعرض حالة فارغة عند عدم وجود خطط علاج.
// يتكيف مع حالتين:
// - لا توجد أمراض مسجلة بعد.
// - توجد أمراض لكن لا توجد خطط للعلاج.
export function EmptyState({
  diseases,
  fetchAll,
  handleOpenPlanForm
}: EmptyStateProps) {
  return (
    <Card>
      <CardContent className="p-12 text-center">
        {diseases.length === 0 ? (
          <>
            <Info className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <p className="text-gray-600">لا توجد أمراض مسجلة. أضف مرضًا أولًا.</p>
          </>
        ) : (
          <>
            <Info className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <p className="text-gray-600">
              لا توجد خطط علاج (عدد الأمراض: {diseases.length}).
            </p>
            <div className="mt-4 flex justify-center gap-3">
              {/* زر لإعادة تحميل البيانات من الخادم بقوة */}
              <Button
                onClick={() => fetchAll({ force: true })}
                className="bg-yellow-500 hover:bg-yellow-600"
              >
                إعادة المحاولة
              </Button>

              {/* زر لفتح نموذج إنشاء خطة علاج جديدة */}
              <Button
                onClick={() => handleOpenPlanForm()}
                className="bg-green-600 hover:bg-green-700"
              >
                إضافة خطة
              </Button>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}
