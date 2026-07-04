import { act, renderHook } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { ConfirmModalState, TreatmentPlan } from "../../types";

const mocks = vi.hoisted(() => ({
  createStep: vi.fn(),
  deleteStep: vi.fn(),
  updateStep: vi.fn()
}));

vi.mock("../../services/treatmentService", () => ({
  createStep: mocks.createStep,
  deleteStep: mocks.deleteStep,
  updateStep: mocks.updateStep
}));

import { useTreatmentSteps } from "./useTreatmentSteps";

const treatmentPlans: TreatmentPlan[] = [
  {
    id: "plan-1",
    diseaseId: "d1",
    diseaseName: "البياض",
    name: "الخطة الأولى",
    doseIntervalDays: 7,
    steps: []
  }
];

const treatmentPlansWithStep: TreatmentPlan[] = [
  {
    ...treatmentPlans[0],
    steps: [
      {
        id: "step-1",
        stepOrder: 1,
        pesticideName: "مبيد موجود",
        chemicalGroup: "Triazole",
        pesticideImageUrl: "/image.png",
        dosageInstructions: "رش كامل",
        mixQuantityAndType: "50 مل",
        safetyInfo: "ابتعد عن الأطفال",
        importantNotes: "ملاحظة"
      }
    ]
  }
];

describe("useTreatmentSteps", () => {
  beforeEach(() => {
    mocks.createStep.mockReset();
    mocks.deleteStep.mockReset();
    mocks.updateStep.mockReset();
  });

  it("allows saving a new step without important notes when the required fields are complete", () => {
    const addToast = vi.fn();
    const refreshAllRef = {
      current: vi.fn().mockResolvedValue(undefined)
    };
    const setConfirmModal = vi.fn();
    const { result } = renderHook(() =>
      useTreatmentSteps({
        treatmentPlans,
        addToast,
        refreshAllRef,
        setConfirmModal
      })
    );

    act(() => {
      result.current.handleOpenStepForm("plan-1");
    });

    act(() => {
      result.current.setStepFormData((current) => ({
        ...current,
        pesticideName: "مبيد",
        chemicalGroup: "Triazole",
        dosageInstructions: "رش كامل",
        mixQuantityAndType: "50 مل",
        safetyInfo: "ابتعد عن الأطفال",
        importantNotes: ""
      }));
    });

    act(() => {
      result.current.handleStepImageChange(
        new File(["image"], "step.png", { type: "image/png" })
      );
    });

    expect(result.current.canSaveStep).toBe(true);
  });

  it("clears transient image and validation state when the step form closes", () => {
    const refreshAllRef = {
      current: vi.fn().mockResolvedValue(undefined)
    };
    const { result } = renderHook(() =>
      useTreatmentSteps({
        treatmentPlans,
        addToast: vi.fn(),
        refreshAllRef,
        setConfirmModal: vi.fn()
      })
    );

    act(() => {
      result.current.handleOpenStepForm("plan-1");
      result.current.setStepErrors({ image: "ملف غير صالح" });
      result.current.handleStepImageChange(
        new File(["image"], "step.png", { type: "image/png" })
      );
    });

    expect(result.current.stepImageFile).not.toBeNull();
    expect(result.current.stepErrors.image).toBeUndefined();

    act(() => {
      result.current.setStepErrors({ pesticideName: "اسم مطلوب" });
      result.current.handleCloseStepForm();
    });

    expect(result.current.isStepFormOpen).toBe(false);
    expect(result.current.stepImageFile).toBeNull();
    expect(result.current.stepErrors).toEqual({});
    expect(result.current.stepFormData).toMatchObject({
      stepOrder: 1,
      pesticideName: "",
      chemicalGroup: ""
    });
  });

  it("starts a new step after the current maximum order", () => {
    const { result } = renderHook(() =>
      useTreatmentSteps({
        treatmentPlans: treatmentPlansWithStep,
        addToast: vi.fn(),
        refreshAllRef: {
          current: vi.fn().mockResolvedValue(undefined)
        },
        setConfirmModal: vi.fn()
      })
    );

    act(() => {
      result.current.handleOpenStepForm("plan-1");
    });

    expect(result.current.stepFormData.stepOrder).toBe(2);
    expect(result.current.editingStep).toBeNull();
  });

  it("rejects invalid image types and oversized files", () => {
    const { result } = renderHook(() =>
      useTreatmentSteps({
        treatmentPlans,
        addToast: vi.fn(),
        refreshAllRef: {
          current: vi.fn().mockResolvedValue(undefined)
        },
        setConfirmModal: vi.fn()
      })
    );

    act(() => {
      result.current.handleStepImageChange(
        new File(["file"], "step.txt", { type: "text/plain" })
      );
    });

    expect(result.current.stepErrors.image).toBe(
      "نوع الملف غير مدعوم. استخدم JPG/PNG/WebP/SVG"
    );
    expect(result.current.stepImageFile).toBeNull();

    const oversizedFile = new File(["image"], "big.png", { type: "image/png" });
    Object.defineProperty(oversizedFile, "size", {
      configurable: true,
      value: 3 * 1024 * 1024
    });

    act(() => {
      result.current.handleStepImageChange(oversizedFile);
    });

    expect(result.current.stepErrors.image).toBe("حجم الصورة كبير جداً (أقصى 2MB)");
    expect(result.current.stepImageFile).toBeNull();
  });

  it("blocks saving invalid or duplicate steps and shows a warning toast", async () => {
    const addToast = vi.fn();
    const { result } = renderHook(() =>
      useTreatmentSteps({
        treatmentPlans: treatmentPlansWithStep,
        addToast,
        refreshAllRef: {
          current: vi.fn().mockResolvedValue(undefined)
        },
        setConfirmModal: vi.fn()
      })
    );

    act(() => {
      result.current.handleOpenStepForm("plan-1");
      result.current.setStepFormData((current) => ({
        ...current,
        pesticideName: "مبيد موجود",
        chemicalGroup: "Triazole",
        dosageInstructions: "رش كامل",
        mixQuantityAndType: "50 مل",
        safetyInfo: "ابتعد عن الأطفال"
      }));
    });

    await act(async () => {
      await result.current.handleSaveStep();
    });

    expect(mocks.createStep).not.toHaveBeenCalled();
    expect(result.current.stepErrors.pesticideName).toBe(
      "يوجد بالفعل خطوة بنفس اسم المبيد في هذه الخطة"
    );
    expect(result.current.stepErrors.image).toBe("صورة المبيد مطلوبة");
    expect(addToast).toHaveBeenCalledWith(
      "warning",
      "الرجاء تصحيح أخطاء الخطوة قبل الحفظ"
    );
  });

  it("creates a new step and sends the expected form-data payload", async () => {
    const addToast = vi.fn();
    const refreshAllRef = {
      current: vi.fn().mockResolvedValue(undefined)
    };
    const imageFile = new File(["image"], "step.png", { type: "image/png" });

    mocks.createStep.mockImplementation(async (data: FormData) => {
      expect(data.get("TreatmentPlanId")).toBe("plan-1");
      expect(data.get("StepOrder")).toBe("2");
      expect(data.get("PesticideName")).toBe("مبيد جديد");
      expect(data.get("ChemicalGroup")).toBe("Copper");
      expect(data.get("DosageInstructions")).toBe("رش كامل");
      expect(data.get("MixQuantityAndType")).toBe("80 مل");
      expect(data.get("SafetyInfo")).toBe("قفازات");
      expect(data.has("ImportantNotes")).toBe(false);
      expect(data.get("pesticideImage")).toBe(imageFile);
    });

    const { result } = renderHook(() =>
      useTreatmentSteps({
        treatmentPlans: treatmentPlansWithStep,
        addToast,
        refreshAllRef,
        setConfirmModal: vi.fn()
      })
    );

    act(() => {
      result.current.handleOpenStepForm("plan-1");
      result.current.setStepFormData((current) => ({
        ...current,
        pesticideName: "مبيد جديد",
        chemicalGroup: "Copper",
        dosageInstructions: "رش كامل",
        mixQuantityAndType: "80 مل",
        safetyInfo: "قفازات",
        importantNotes: ""
      }));
      result.current.handleStepImageChange(imageFile);
    });

    await act(async () => {
      await result.current.handleSaveStep();
    });

    expect(mocks.createStep).toHaveBeenCalledTimes(1);
    expect(addToast).toHaveBeenCalledWith("success", "تم إنشاء الخطوة");
    expect(refreshAllRef.current).toHaveBeenCalledTimes(1);
    expect(result.current.isStepFormOpen).toBe(false);
  });

  it("updates an existing step without requiring a new image file", async () => {
    const addToast = vi.fn();
    const refreshAllRef = {
      current: vi.fn().mockResolvedValue(undefined)
    };

    mocks.updateStep.mockImplementation(async (data: FormData) => {
      expect(data.get("Id")).toBe("step-1");
      expect(data.get("TreatmentPlanId")).toBe("plan-1");
      expect(data.get("StepOrder")).toBe("1");
      expect(data.get("PesticideImageUrl")).toBe("/image.png");
      expect(data.get("ImportantNotes")).toBe("محدثة");
    });

    const { result } = renderHook(() =>
      useTreatmentSteps({
        treatmentPlans: treatmentPlansWithStep,
        addToast,
        refreshAllRef,
        setConfirmModal: vi.fn()
      })
    );

    act(() => {
      result.current.handleOpenStepForm(
        "plan-1",
        treatmentPlansWithStep[0].steps[0]
      );
      result.current.setStepFormData((current) => ({
        ...current,
        importantNotes: "محدثة"
      }));
    });

    await act(async () => {
      await result.current.handleSaveStep();
    });

    expect(mocks.updateStep).toHaveBeenCalledTimes(1);
    expect(addToast).toHaveBeenCalledWith("success", "تم تحديث الخطوة");
    expect(refreshAllRef.current).toHaveBeenCalledTimes(1);
  });

  it("shows an error toast when step saving fails", async () => {
    const addToast = vi.fn();
    mocks.createStep.mockRejectedValue(new Error("boom"));

    const { result } = renderHook(() =>
      useTreatmentSteps({
        treatmentPlans,
        addToast,
        refreshAllRef: {
          current: vi.fn().mockResolvedValue(undefined)
        },
        setConfirmModal: vi.fn()
      })
    );

    act(() => {
      result.current.handleOpenStepForm("plan-1");
      result.current.setStepFormData((current) => ({
        ...current,
        pesticideName: "مبيد",
        chemicalGroup: "Copper",
        dosageInstructions: "رش كامل",
        mixQuantityAndType: "50 مل",
        safetyInfo: "قفازات"
      }));
      result.current.handleStepImageChange(
        new File(["image"], "step.png", { type: "image/png" })
      );
    });

    await act(async () => {
      await result.current.handleSaveStep();
    });

    expect(addToast).toHaveBeenCalledWith(
      "error",
      "خطأ أثناء حفظ الخطوة: boom"
    );
    expect(result.current.isSavingStep).toBe(false);
    expect(result.current.isStepFormOpen).toBe(true);
  });

  it("opens a delete confirmation and handles confirm success and failure", async () => {
    const addToast = vi.fn();
    const refreshAllRef = {
      current: vi.fn().mockResolvedValue(undefined)
    };
    const setConfirmModal = vi.fn();
    mocks.deleteStep.mockResolvedValueOnce(undefined);
    mocks.deleteStep.mockRejectedValueOnce(new Error("boom"));

    const { result } = renderHook(() =>
      useTreatmentSteps({
        treatmentPlans: treatmentPlansWithStep,
        addToast,
        refreshAllRef,
        setConfirmModal
      })
    );

    act(() => {
      result.current.handleDeleteStep("plan-1", "step-1");
    });

    const firstModal = setConfirmModal.mock.calls[0][0] as ConfirmModalState;
    expect(firstModal).toMatchObject({
      open: true,
      title: "حذف خطوة"
    });

    await act(async () => {
      await firstModal.onConfirm?.();
    });

    expect(mocks.deleteStep).toHaveBeenCalledWith("step-1");
    expect(addToast).toHaveBeenCalledWith("success", "تم حذف الخطوة");
    expect(refreshAllRef.current).toHaveBeenCalledTimes(1);

    act(() => {
      result.current.handleDeleteStep("plan-1", "step-1");
    });

    const secondModal = setConfirmModal.mock.calls[1][0] as ConfirmModalState;
    await act(async () => {
      await secondModal.onConfirm?.();
    });

    expect(addToast).toHaveBeenCalledWith(
      "error",
      "خطأ أثناء حذف الخطوة: boom"
    );
  });
});
