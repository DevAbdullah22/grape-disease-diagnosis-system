import type { ComponentProps } from "react";
import { TreatmentPlanModal } from "./TreatmentPlanModal";
import { TreatmentStepModal } from "./TreatmentStepsSection";

interface TreatmentEditorDialogProps {
  planModalProps: ComponentProps<typeof TreatmentPlanModal>;
  stepModalProps: ComponentProps<typeof TreatmentStepModal>;
}

export function TreatmentEditorDialog({
  planModalProps,
  stepModalProps
}: TreatmentEditorDialogProps) {
  return (
    <>
      <TreatmentPlanModal {...planModalProps} />
      <TreatmentStepModal {...stepModalProps} />
    </>
  );
}
