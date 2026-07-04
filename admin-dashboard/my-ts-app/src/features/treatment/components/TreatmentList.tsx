import type { ComponentProps } from "react";
import { TreatmentPlanList } from "./TreatmentPlanList";

type TreatmentListProps = ComponentProps<typeof TreatmentPlanList>;

export function TreatmentList(props: TreatmentListProps) {
  return <TreatmentPlanList {...props} />;
}
