import { Card, CardContent } from "../../../components/ui/card";
import { Search } from "lucide-react";

interface Disease {
  id: string;
  name: string;
}

interface TreatmentSearchBarProps {
  diseases: Disease[];
  searchTerm: string;
  setSearchTerm: (value: string) => void;
  diseaseFilter: string;
  setDiseaseFilter: (value: string) => void;
}

export function TreatmentSearchBar({
  diseases,
  searchTerm,
  setSearchTerm,
  diseaseFilter,
  setDiseaseFilter
}: TreatmentSearchBarProps) {
  return (
    <Card>
      <CardContent className="p-4">
        <div className="grid md:grid-cols-2 gap-3 items-center">
          <div className="relative">
            <Search className="absolute right-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input
              type="text"
              placeholder="ابحث عن خطة أو مرض أو مبيد..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pr-10 pl-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500"
            />
          </div>

          <div className="flex gap-2">
            <select
              value={diseaseFilter}
              onChange={(e) => setDiseaseFilter(e.target.value)}
              className="px-3 py-2 border rounded-lg bg-white"
            >
              <option value="all">كل الأمراض</option>
              {diseases.map((d) => (
                <option key={d.id} value={d.id}>
                  {d.name}
                </option>
              ))}
            </select>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
