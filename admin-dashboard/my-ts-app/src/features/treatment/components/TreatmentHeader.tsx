import { Button } from "../../../components/ui/button";
import { Plus } from "lucide-react";
import { TreatmentSearchBar } from "./TreatmentSearchBar";

interface Disease {
  id: string;
  name: string;
}

interface TreatmentHeaderProps {
  diseases: Disease[];
  searchTerm: string;
  setSearchTerm: (value: string) => void;
  diseaseFilter: string;
  setDiseaseFilter: (value: string) => void;
  handleOpenPlanForm: () => void;
}

export function TreatmentHeader({
  diseases,
  searchTerm,
  setSearchTerm,
  diseaseFilter,
  setDiseaseFilter,
  handleOpenPlanForm
}: TreatmentHeaderProps) {
  return (
    <>
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl sm:text-3xl font-semibold text-gray-900">
            إدارة خطط العلاج
          </h1>
          <p className="text-gray-600 mt-1">
            إنشاء وتعديل خطط العلاج المتكاملة للأمراض
          </p>
        </div>
        <div className="flex w-full sm:w-auto gap-3">
          <Button
            onClick={() => handleOpenPlanForm()}
            className="w-full sm:w-auto flex items-center justify-center gap-2 bg-green-600 hover:bg-green-700"
          >
            <Plus className="h-4 w-4" />
            إضافة خطة علاج جديدة
          </Button>
        </div>
      </div>

      <TreatmentSearchBar
        diseases={diseases}
        searchTerm={searchTerm}
        setSearchTerm={setSearchTerm}
        diseaseFilter={diseaseFilter}
        setDiseaseFilter={setDiseaseFilter}
      />
    </>
  );
}
