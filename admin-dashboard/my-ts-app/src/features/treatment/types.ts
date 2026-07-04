export interface TreatmentStep {
  id: string;
  stepOrder: number;
  pesticideName: string;
  chemicalGroup: string;
  pesticideImageUrl: string;
  dosageInstructions: string;
  mixQuantityAndType: string;
  safetyInfo: string;
  importantNotes: string;
}

export interface TreatmentPlan {
  id: string;
  diseaseId: string;
  diseaseName: string;
  name: string;
  doseIntervalDays: number;
  steps: TreatmentStep[];
}

export interface Disease {
  id: string;
  name: string;
}

export interface DragInfo {
  planId: string;
  stepId: string;
  fromIndex: number;
}

export interface DragOver {
  planId: string;
  index: number;
}

export interface PlanErrors {
  name?: string;
  diseaseId?: string;
  doseIntervalDays?: string;
}

export interface StepErrors {
  pesticideName?: string;
  chemicalGroup?: string;
  dosageInstructions?: string;
  mixQuantityAndType?: string;
  safetyInfo?: string;
  image?: string;
}

export interface PlanFormData {
  name: string;
  diseaseId: string;
  doseIntervalDays: number;
}

export type StepFormData = Partial<TreatmentStep>;

export interface ConfirmModalState {
  open: boolean;
  title?: string;
  description?: string;
  onConfirm?: () => Promise<void> | void;
  requiredConfirmText?: string;
}

export type ToastType = "success" | "error" | "warning";
export type StepTab = "general" | "dosage" | "safety" | "notes";
export type StepMoveDirection = "up" | "down";
