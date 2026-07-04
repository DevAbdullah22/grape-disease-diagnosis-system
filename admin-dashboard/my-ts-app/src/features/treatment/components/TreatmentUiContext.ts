import { createContext, useContext } from "react";
import type {
  Dispatch,
  DragEvent,
  ReactNode,
  SetStateAction
} from "react";
import type {
  DragInfo,
  DragOver,
  StepMoveDirection,
  TreatmentPlan,
  TreatmentStep
} from "../types";

export interface TreatmentUiContextValue {
  searchTerm: string;
  highlightMatch: (text: string, term: string) => ReactNode;
  renderTruncated: (
    text: string | undefined,
    id: string,
    limit?: number
  ) => ReactNode;
  isTouchDevice: boolean;
  plansOrderDirty: Record<string, boolean>;
  savingOrders: Record<string, boolean>;
  dragInfo: DragInfo | null;
  dragOver: DragOver | null;
  setDragOver: Dispatch<SetStateAction<DragOver | null>>;
  expandedStepId: string | null;
  handleSaveStepsOrder: (planId: string) => void;
  handleOpenStepForm: (planId: string, step?: TreatmentStep) => void;
  handleDragStart: (
    e: DragEvent,
    planId: string,
    stepId: string,
    index: number
  ) => void;
  handleDragOver: (e: DragEvent, planId: string, index: number) => void;
  handleDrop: (e: DragEvent, planId: string, toIndex: number) => void;
  handleDragEnd: () => void;
  toggleExpanded: (id: string) => void;
  handleDeleteStep: (planId: string, stepId: string) => void;
  handleMoveStep: (
    planId: string,
    stepId: string,
    direction: StepMoveDirection
  ) => void;
  handleOpenPlanForm: (plan?: TreatmentPlan) => void;
  handleDeletePlan: (id: string) => void;
  resolveImageUrl: (path?: string | null) => string | undefined;
}

export const TreatmentUiContext =
  createContext<TreatmentUiContextValue | null>(null);

export function useTreatmentUi() {
  const context = useContext(TreatmentUiContext);
  if (!context) {
    throw new Error("useTreatmentUi must be used within TreatmentUiProvider");
  }
  return context;
}
