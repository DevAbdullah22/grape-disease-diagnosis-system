import { act, renderHook } from "@testing-library/react";
import { useState } from "react";
import type { DragEvent } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { ToastType, TreatmentPlan } from "../../types";

const mocks = vi.hoisted(() => ({
  reorderSteps: vi.fn()
}));

vi.mock("../../services/treatmentService", () => ({
  reorderSteps: mocks.reorderSteps
}));

import { useStepReorder } from "./useStepReorder";

function createPlans(): TreatmentPlan[] {
  return [
    {
      id: "plan-1",
      diseaseId: "d1",
      diseaseName: "البياض",
      name: "خطة 1",
      doseIntervalDays: 7,
      steps: [
        {
          id: "step-1",
          stepOrder: 1,
          pesticideName: "مبيد 1",
          chemicalGroup: "A",
          pesticideImageUrl: "",
          dosageInstructions: "رش",
          mixQuantityAndType: "50 مل",
          safetyInfo: "احذر",
          importantNotes: ""
        },
        {
          id: "step-2",
          stepOrder: 2,
          pesticideName: "مبيد 2",
          chemicalGroup: "B",
          pesticideImageUrl: "",
          dosageInstructions: "رش",
          mixQuantityAndType: "60 مل",
          safetyInfo: "احذر",
          importantNotes: ""
        },
        {
          id: "step-3",
          stepOrder: 3,
          pesticideName: "مبيد 3",
          chemicalGroup: "C",
          pesticideImageUrl: "",
          dosageInstructions: "رش",
          mixQuantityAndType: "70 مل",
          safetyInfo: "احذر",
          importantNotes: ""
        }
      ]
    }
  ];
}

function useStepReorderHarness(
  initialPlans: TreatmentPlan[],
  addToast: (type: ToastType, message: string) => void,
  refreshAllRef: { current: () => Promise<void> }
) {
  const [plans, setPlans] = useState(initialPlans);
  const reorderState = useStepReorder({
    treatmentPlans: plans,
    setTreatmentPlans: setPlans,
    addToast,
    refreshAllRef
  });

  return {
    plans,
    ...reorderState
  };
}

function createDragEvent({
  payload = JSON.stringify({ planId: "plan-1", stepId: "step-1", index: 0 })
}: {
  payload?: string;
} = {}) {
  return {
    preventDefault: vi.fn(),
    dataTransfer: {
      effectAllowed: "",
      setData: vi.fn(),
      getData: vi.fn().mockReturnValue(payload)
    }
  };
}

describe("useStepReorder", () => {
  beforeEach(() => {
    mocks.reorderSteps.mockReset();
  });

  it("toggles expanded steps and reorders steps with move actions", () => {
    const addToast = vi.fn();
    const { result } = renderHook(() =>
      useStepReorderHarness(createPlans(), addToast, {
        current: vi.fn().mockResolvedValue(undefined)
      })
    );

    act(() => {
      result.current.toggleExpanded("step-2");
    });
    expect(result.current.expandedStepId).toBe("step-2");

    act(() => {
      result.current.toggleExpanded("step-2");
    });
    expect(result.current.expandedStepId).toBeNull();

    act(() => {
      result.current.handleMoveStep("plan-1", "step-2", "up");
    });

    expect(result.current.plans[0].steps.map((step) => step.id)).toEqual([
      "step-2",
      "step-1",
      "step-3"
    ]);
    expect(result.current.plans[0].steps.map((step) => step.stepOrder)).toEqual([
      1,
      2,
      3
    ]);
    expect(result.current.plansOrderDirty["plan-1"]).toBe(true);
    expect(addToast).toHaveBeenCalledWith(
      "warning",
      "تم تغيير ترتيب الخطوات ولم يتم الحفظ بعد"
    );
  });

  it("ignores impossible move operations", () => {
    const addToast = vi.fn();
    const { result } = renderHook(() =>
      useStepReorderHarness(createPlans(), addToast, {
        current: vi.fn().mockResolvedValue(undefined)
      })
    );

    act(() => {
      result.current.handleMoveStep("plan-1", "step-1", "up");
      result.current.handleMoveStep("plan-1", "missing-step", "down");
    });

    expect(result.current.plans[0].steps.map((step) => step.id)).toEqual([
      "step-1",
      "step-2",
      "step-3"
    ]);
    expect(addToast).not.toHaveBeenCalled();
  });

  it("tracks drag state and reorders steps on drop", () => {
    const addToast = vi.fn();
    const { result } = renderHook(() =>
      useStepReorderHarness(createPlans(), addToast, {
        current: vi.fn().mockResolvedValue(undefined)
      })
    );

    const startEvent = createDragEvent();

    act(() => {
      result.current.handleDragStart(
        startEvent as unknown as DragEvent,
        "plan-1",
        "step-1",
        0
      );
    });

    expect(startEvent.dataTransfer.effectAllowed).toBe("move");
    expect(startEvent.dataTransfer.setData).toHaveBeenCalledWith(
      "application/json",
      JSON.stringify({ planId: "plan-1", stepId: "step-1", index: 0 })
    );
    expect(result.current.dragInfo).toEqual({
      planId: "plan-1",
      stepId: "step-1",
      fromIndex: 0
    });

    const overEvent = createDragEvent();
    act(() => {
      result.current.handleDragOver(
        overEvent as unknown as DragEvent,
        "plan-1",
        2
      );
    });
    expect(overEvent.preventDefault).toHaveBeenCalledTimes(1);
    expect(result.current.dragOver).toEqual({
      planId: "plan-1",
      index: 2
    });

    const dropEvent = createDragEvent();
    act(() => {
      result.current.handleDrop(
        dropEvent as unknown as DragEvent,
        "plan-1",
        2
      );
    });

    expect(dropEvent.preventDefault).toHaveBeenCalledTimes(1);
    expect(result.current.plans[0].steps.map((step) => step.id)).toEqual([
      "step-2",
      "step-3",
      "step-1"
    ]);
    expect(result.current.dragInfo).toBeNull();
    expect(result.current.dragOver).toBeNull();
    expect(result.current.plansOrderDirty["plan-1"]).toBe(true);
    expect(addToast).toHaveBeenCalledWith(
      "warning",
      "تم تغيير ترتيب الخطوات ولم يتم الحفظ بعد"
    );
  });

  it("clears drag state when the payload is malformed", () => {
    const addToast = vi.fn();
    const { result } = renderHook(() =>
      useStepReorderHarness(createPlans(), addToast, {
        current: vi.fn().mockResolvedValue(undefined)
      })
    );

    act(() => {
      result.current.handleDragStart(
        createDragEvent() as unknown as DragEvent,
        "plan-1",
        "step-1",
        0
      );
    });

    act(() => {
      result.current.handleDrop(
        createDragEvent({ payload: "not-json" }) as unknown as DragEvent,
        "plan-1",
        1
      );
    });

    expect(result.current.plans[0].steps.map((step) => step.id)).toEqual([
      "step-1",
      "step-2",
      "step-3"
    ]);
    expect(result.current.dragInfo).toBeNull();
    expect(result.current.dragOver).toBeNull();
    expect(addToast).not.toHaveBeenCalled();
  });

  it("prevents saving duplicate step orders", async () => {
    const addToast = vi.fn();
    const { result } = renderHook(() =>
      useStepReorderHarness(
        [
          {
            ...createPlans()[0],
            steps: [
              { ...createPlans()[0].steps[0], stepOrder: 1 },
              { ...createPlans()[0].steps[1], stepOrder: 1 }
            ]
          }
        ],
        addToast,
        {
          current: vi.fn().mockResolvedValue(undefined)
        }
      )
    );

    await act(async () => {
      await result.current.handleSaveStepsOrder("plan-1");
    });

    expect(mocks.reorderSteps).not.toHaveBeenCalled();
    expect(addToast).toHaveBeenCalledWith(
      "error",
      "هناك أرقام ترتيب مكررة. تأكد أن كل خطوة لها ترتيب فريد قبل الحفظ."
    );
    expect(result.current.savingOrders["plan-1"]).toBe(false);
  });

  it("saves the reordered steps and refreshes all plans", async () => {
    const addToast = vi.fn();
    const refreshAllRef = {
      current: vi.fn().mockResolvedValue(undefined)
    };
    mocks.reorderSteps.mockResolvedValue(undefined);

    const { result } = renderHook(() =>
      useStepReorderHarness(createPlans(), addToast, refreshAllRef)
    );

    act(() => {
      result.current.handleMoveStep("plan-1", "step-2", "up");
    });

    await act(async () => {
      await result.current.handleSaveStepsOrder("plan-1");
    });

    expect(mocks.reorderSteps).toHaveBeenCalledWith("plan-1", [
      { id: "step-2", stepOrder: 1 },
      { id: "step-1", stepOrder: 2 },
      { id: "step-3", stepOrder: 3 }
    ]);
    expect(addToast).toHaveBeenCalledWith("success", "تم حفظ ترتيب الخطوات");
    expect(refreshAllRef.current).toHaveBeenCalledTimes(1);
    expect(result.current.plansOrderDirty["plan-1"]).toBe(false);
    expect(result.current.savingOrders["plan-1"]).toBe(false);
  });

  it("shows the extracted server error when saving step order fails", async () => {
    const addToast = vi.fn();
    mocks.reorderSteps.mockRejectedValue({
      response: {
        data: {
          message: "تعذر حفظ الترتيب"
        }
      }
    });

    const { result } = renderHook(() =>
      useStepReorderHarness(createPlans(), addToast, {
        current: vi.fn().mockResolvedValue(undefined)
      })
    );

    await act(async () => {
      await result.current.handleSaveStepsOrder("plan-1");
    });

    expect(addToast).toHaveBeenCalledWith(
      "error",
      "خطأ أثناء حفظ ترتيب الخطوات: تعذر حفظ الترتيب"
    );
    expect(result.current.savingOrders["plan-1"]).toBe(false);
  });
});
