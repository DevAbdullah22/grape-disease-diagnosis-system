import { useState } from "react";
import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { TreatmentStepsSection } from "./TreatmentStepsSection";
import { TreatmentUiProvider } from "./TreatmentUiProvider";
import type { DragOver, TreatmentPlan } from "../types";

const basePlan: TreatmentPlan = {
  id: "plan-1",
  diseaseId: "disease-1",
  diseaseName: "البياض الدقيقي",
  name: "خطة علاج",
  doseIntervalDays: 7,
  steps: [
    {
      id: "step-1",
      stepOrder: 1,
      pesticideName: "مبيد 1",
      chemicalGroup: "Copper",
      pesticideImageUrl: "",
      dosageInstructions: "رش كامل",
      mixQuantityAndType: "50 مل",
      safetyInfo: "قفازات",
      importantNotes: ""
    }
  ]
};

function renderWithState({
  onEdit = vi.fn(),
  onDelete = vi.fn(),
  plan = basePlan
}: {
  onEdit?: (planId: string, step?: unknown) => void;
  onDelete?: (planId: string, stepId: string) => void;
  plan?: TreatmentPlan;
} = {}) {
  function Wrapper() {
    const [expandedStepId, setExpandedStepId] = useState<string | null>(null);
    const [dragOver, setDragOver] = useState<DragOver | null>(null);

    return (
      <TreatmentUiProvider
        value={{
          searchTerm: "",
          highlightMatch: (text) => <>{text}</>,
          renderTruncated: (text) => <>{text}</>,
          isTouchDevice: false,
          plansOrderDirty: {},
          savingOrders: {},
          dragInfo: null,
          dragOver,
          setDragOver,
          expandedStepId,
          handleSaveStepsOrder: vi.fn(),
          handleOpenStepForm: onEdit,
          handleDragStart: vi.fn(),
          handleDragOver: vi.fn(),
          handleDrop: vi.fn(),
          handleDragEnd: vi.fn(),
          toggleExpanded: (id) =>
            setExpandedStepId((prev) => (prev === id ? null : id)),
          handleDeleteStep: onDelete,
          handleMoveStep: vi.fn(),
          handleOpenPlanForm: vi.fn(),
          handleDeletePlan: vi.fn(),
          resolveImageUrl: () => undefined
        }}
      >
        <TreatmentStepsSection plan={plan} />
      </TreatmentUiProvider>
    );
  }

  return render(<Wrapper />);
}

describe("TreatmentStepsSection", () => {
  it("toggles expansion when the step header is clicked", () => {
    renderWithState();

    const headerButton = screen.getByRole("button", { name: /مبيد 1/i });
    expect(headerButton).toHaveAttribute("aria-expanded", "false");

    fireEvent.click(headerButton);
    expect(headerButton).toHaveAttribute("aria-expanded", "true");

    fireEvent.click(headerButton);
    expect(headerButton).toHaveAttribute("aria-expanded", "false");
  });

  it("does not toggle when clicking edit or delete buttons", () => {
    const handleOpenStepForm = vi.fn();
    const handleDeleteStep = vi.fn();

    renderWithState({
      onEdit: handleOpenStepForm,
      onDelete: handleDeleteStep
    });

    const headerButton = screen.getByRole("button", { name: /مبيد 1/i });
    expect(headerButton).toHaveAttribute("aria-expanded", "false");

    fireEvent.click(
      screen.getByRole("button", { name: /تعديل الخطوة 1/i })
    );
    expect(handleOpenStepForm).toHaveBeenCalledWith(
      "plan-1",
      expect.objectContaining({ id: "step-1" })
    );
    expect(headerButton).toHaveAttribute("aria-expanded", "false");

    fireEvent.click(screen.getByRole("button", { name: /حذف الخطوة 1/i }));
    expect(handleDeleteStep).toHaveBeenCalledWith("plan-1", "step-1");
    expect(headerButton).toHaveAttribute("aria-expanded", "false");
  });
});
