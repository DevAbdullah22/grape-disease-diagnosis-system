import type { ReactNode } from "react";
import {
  TreatmentUiContext,
  type TreatmentUiContextValue
} from "./TreatmentUiContext";

export function TreatmentUiProvider({
  value,
  children
}: {
  value: TreatmentUiContextValue;
  children: ReactNode;
}) {
  return (
    <TreatmentUiContext.Provider value={value}>
      {children}
    </TreatmentUiContext.Provider>
  );
}
