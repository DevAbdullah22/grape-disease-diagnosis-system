import { act, renderHook } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { ConfirmModalState, Disease, TreatmentPlan } from "../../types";

const mocks = vi.hoisted(() => ({
  createPlan: vi.fn(),
  deletePlan: vi.fn(),
  getPlansByDisease: vi.fn(),
  updatePlan: vi.fn()
}));

vi.mock("../../services/treatmentService", () => ({
  createPlan: mocks.createPlan,
  deletePlan: mocks.deletePlan,
  getPlansByDisease: mocks.getPlansByDisease,
  updatePlan: mocks.updatePlan
}));

import { useTreatmentPlans } from "./useTreatmentPlans";

const diseases: Disease[] = [
  { id: "d1", name: "البياض" },
  { id: "d2", name: "اللفحة" }
];

const existingPlan: TreatmentPlan = {
  id: "plan-1",
  diseaseId: "d1",
  diseaseName: "البياض",
  name: "الخطة الحالية",
  doseIntervalDays: 7,
  steps: []
};

describe("useTreatmentPlans", () => {
  beforeEach(() => {
    mocks.createPlan.mockReset();
    mocks.deletePlan.mockReset();
    mocks.getPlansByDisease.mockReset();
    mocks.updatePlan.mockReset();
  });

  it("loads plans for all diseases and maps API fallbacks safely", async () => {
    mocks.getPlansByDisease.mockImplementation(async (diseaseId: string) => {
      if (diseaseId === "d1") {
        return [
          {
            id: "plan-1",
            planName: "خطة من planName",
            steps: [
              {
                stepOrder: 2,
                pesticideName: "مبيد",
                pesticideImageUrl: null,
                importantNotes: null
              }
            ]
          }
        ];
      }

      throw new Error("skip this disease");
    });

    const addToast = vi.fn();
    const { result } = renderHook(() =>
      useTreatmentPlans({
        addToast,
        refreshAllRef: {
          current: vi.fn().mockResolvedValue(undefined)
        },
        setConfirmModal: vi.fn()
      })
    );

    let plans: TreatmentPlan[] = [];
    await act(async () => {
      plans = await result.current.loadPlansByDiseases(diseases);
    });

    expect(mocks.getPlansByDisease).toHaveBeenCalledTimes(2);
    expect(plans).toEqual([
      {
        id: "plan-1",
        diseaseId: "d1",
        diseaseName: "البياض",
        name: "خطة من planName",
        doseIntervalDays: 7,
        steps: [
          {
            id: "plan-1-2",
            stepOrder: 2,
            pesticideName: "مبيد",
            chemicalGroup: "",
            pesticideImageUrl: "",
            dosageInstructions: "",
            mixQuantityAndType: "",
            safetyInfo: "",
            importantNotes: ""
          }
        ]
      }
    ]);
    expect(addToast).toHaveBeenCalledWith(
      "error",
      "تعذر تحميل خطط الأمراض التالية: اللفحة"
    );
  });

  it("validates the create form before saving", async () => {
    const { result } = renderHook(() =>
      useTreatmentPlans({
        addToast: vi.fn(),
        refreshAllRef: {
          current: vi.fn().mockResolvedValue(undefined)
        },
        setConfirmModal: vi.fn()
      })
    );

    await act(async () => {
      await result.current.handleSavePlan();
    });

    expect(mocks.createPlan).not.toHaveBeenCalled();
    expect(result.current.planErrors).toEqual({
      name: "اسم الخطة مطلوب",
      diseaseId: "يجب اختيار المرض"
    });
  });

  it("creates a new plan, trims values, and refreshes the aggregate list", async () => {
    const addToast = vi.fn();
    const refreshAllRef = {
      current: vi.fn().mockResolvedValue(undefined)
    };
    const { result } = renderHook(() =>
      useTreatmentPlans({
        addToast,
        refreshAllRef,
        setConfirmModal: vi.fn()
      })
    );

    act(() => {
      result.current.handleOpenPlanForm();
      result.current.setPlanFormData({
        name: "  خطة جديدة  ",
        diseaseId: "d1",
        doseIntervalDays: 10
      });
    });

    await act(async () => {
      await result.current.handleSavePlan();
    });

    expect(mocks.createPlan).toHaveBeenCalledWith({
      diseaseId: "d1",
      name: "خطة جديدة",
      doseIntervalDays: 10
    });
    expect(addToast).toHaveBeenCalledWith("success", "تم إضافة الخطة بنجاح");
    expect(refreshAllRef.current).toHaveBeenCalledTimes(1);
    expect(result.current.isFormOpen).toBe(false);
    expect(result.current.planFormData).toEqual(result.current.defaultPlanFormData);
  });

  it("updates an existing plan and tracks unsaved changes", async () => {
    const addToast = vi.fn();
    const refreshAllRef = {
      current: vi.fn().mockResolvedValue(undefined)
    };
    const { result } = renderHook(() =>
      useTreatmentPlans({
        addToast,
        refreshAllRef,
        setConfirmModal: vi.fn()
      })
    );

    act(() => {
      result.current.setTreatmentPlans([existingPlan]);
      result.current.handleOpenPlanForm(existingPlan);
    });

    expect(result.current.hasUnsavedChanges).toBe(false);

    act(() => {
      result.current.setPlanFormData({
        name: "  خطة معدلة  ",
        diseaseId: "d1",
        doseIntervalDays: 5
      });
    });

    expect(result.current.hasUnsavedChanges).toBe(true);

    await act(async () => {
      await result.current.handleSavePlan();
    });

    expect(mocks.updatePlan).toHaveBeenCalledWith({
      id: "plan-1",
      name: "خطة معدلة",
      doseIntervalDays: 5
    });
    expect(addToast).toHaveBeenCalledWith("success", "تم تعديل الخطة بنجاح");
    expect(refreshAllRef.current).toHaveBeenCalledTimes(1);
  });

  it("uses the server error message when saving a plan fails", async () => {
    const addToast = vi.fn();
    mocks.createPlan.mockRejectedValue({
      response: {
        data: {
          message: "فشل حفظ الخطة"
        }
      }
    });

    const { result } = renderHook(() =>
      useTreatmentPlans({
        addToast,
        refreshAllRef: {
          current: vi.fn().mockResolvedValue(undefined)
        },
        setConfirmModal: vi.fn()
      })
    );

    act(() => {
      result.current.setPlanFormData({
        name: "خطة جديدة",
        diseaseId: "d1",
        doseIntervalDays: 7
      });
    });

    await act(async () => {
      await result.current.handleSavePlan();
    });

    expect(addToast).toHaveBeenCalledWith("error", "فشل حفظ الخطة");
    expect(result.current.isSavingPlan).toBe(false);
  });

  it("opens a strong confirmation dialog when deleting a plan with steps", async () => {
    const addToast = vi.fn();
    const refreshAllRef = {
      current: vi.fn().mockResolvedValue(undefined)
    };
    const setConfirmModal = vi.fn();
    mocks.deletePlan.mockResolvedValue(undefined);

    const { result } = renderHook(() =>
      useTreatmentPlans({
        addToast,
        refreshAllRef,
        setConfirmModal
      })
    );

    act(() => {
      result.current.setTreatmentPlans([
        {
          ...existingPlan,
          steps: [
            {
              id: "step-1",
              stepOrder: 1,
              pesticideName: "مبيد",
              chemicalGroup: "A",
              pesticideImageUrl: "",
              dosageInstructions: "رش",
              mixQuantityAndType: "50 مل",
              safetyInfo: "احذر",
              importantNotes: ""
            }
          ]
        }
      ]);
    });

    act(() => {
      result.current.handleDeletePlan("plan-1");
    });

    const modalState = setConfirmModal.mock.calls[0][0] as ConfirmModalState;
    expect(modalState).toMatchObject({
      open: true,
      title: "حذف خطة العلاج (تأكيد قوي)",
      requiredConfirmText: "الخطة الحالية"
    });

    await act(async () => {
      await modalState.onConfirm?.();
    });

    expect(mocks.deletePlan).toHaveBeenCalledWith("plan-1");
    expect(addToast).toHaveBeenCalledWith("success", "تم حذف الخطة");
    expect(refreshAllRef.current).toHaveBeenCalledTimes(1);
  });

  it("shows a normal confirmation dialog and error toast when deleting fails", async () => {
    const addToast = vi.fn();
    const setConfirmModal = vi.fn();
    mocks.deletePlan.mockRejectedValue(new Error("boom"));

    const { result } = renderHook(() =>
      useTreatmentPlans({
        addToast,
        refreshAllRef: {
          current: vi.fn().mockResolvedValue(undefined)
        },
        setConfirmModal
      })
    );

    act(() => {
      result.current.setTreatmentPlans([existingPlan]);
      result.current.handleDeletePlan("plan-1");
    });

    const modalState = setConfirmModal.mock.calls[0][0] as ConfirmModalState;
    expect(modalState).toMatchObject({
      open: true,
      title: "حذف خطة العلاج"
    });
    expect(modalState.requiredConfirmText).toBeUndefined();

    await act(async () => {
      await modalState.onConfirm?.();
    });

    expect(addToast).toHaveBeenCalledWith(
      "error",
      "خطأ أثناء حذف الخطة: boom"
    );
  });
});
