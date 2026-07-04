
export interface TreatmentStepDto {
  id?: string;
  treatmentPlanId?: string;
  stepOrder: number;
  pesticideName?: string;
  chemicalGroup?: string;
  pesticideImageUrl?: string | null;
  dosageInstructions?: string;
  mixQuantityAndType?: string;
  safetyInfo?: string;
  importantNotes?: string | null;
  // intervalDays was moved to plan level (doseIntervalDays)
}

export interface TreatmentPlanDto {
  id?: string;
  diseaseId?: string;
  diseaseName?: string;
  name?: string;
  planName?: string;
  steps?: TreatmentStepDto[];
  doseIntervalDays?: number;
  disease?: { name?: string };
}
