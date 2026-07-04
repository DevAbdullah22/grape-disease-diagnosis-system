import { act, renderHook, waitFor } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  getDiseases: vi.fn(),
  toast: {
    error: vi.fn(),
    success: vi.fn(),
    warning: vi.fn()
  }
}));

vi.mock("../../services/treatmentService", () => ({
  getDiseases: mocks.getDiseases
}));

vi.mock("sonner", () => ({
  toast: mocks.toast
}));

import { useDiseases } from "./useDiseases";

function setTouchEnvironment({
  matches = false,
  maxTouchPoints = 0
}: {
  matches?: boolean;
  maxTouchPoints?: number;
}) {
  Object.defineProperty(window, "matchMedia", {
    configurable: true,
    value: vi.fn().mockReturnValue({
      matches,
      media: "(pointer: coarse)",
      onchange: null,
      addListener: vi.fn(),
      removeListener: vi.fn(),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      dispatchEvent: vi.fn()
    })
  });

  Object.defineProperty(window.navigator, "maxTouchPoints", {
    configurable: true,
    value: maxTouchPoints
  });
}

describe("useDiseases", () => {
  beforeEach(() => {
    mocks.getDiseases.mockReset();
    mocks.toast.error.mockReset();
    mocks.toast.success.mockReset();
    mocks.toast.warning.mockReset();
    setTouchEnvironment({ matches: false, maxTouchPoints: 0 });
  });

  it("detects touch devices and loads related treatment data", async () => {
    setTouchEnvironment({ matches: true, maxTouchPoints: 0 });
    mocks.getDiseases.mockResolvedValue([{ id: "d1", name: "البياض" }]);
    const loadRelated = vi.fn().mockResolvedValue(["plan-1"]);
    const onRelatedLoaded = vi.fn();

    const { result } = renderHook(() => useDiseases());

    await waitFor(() => {
      expect(result.current.isTouchDevice).toBe(true);
    });

    await act(async () => {
      await result.current.fetchAllData(loadRelated, onRelatedLoaded);
    });

    expect(result.current.diseases).toEqual([{ id: "d1", name: "البياض" }]);
    expect(loadRelated).toHaveBeenCalledWith([{ id: "d1", name: "البياض" }]);
    expect(onRelatedLoaded).toHaveBeenCalledWith(["plan-1"]);
    expect(result.current.isLoading).toBe(false);
  });

  it("shows a toast when loading diseases fails", async () => {
    mocks.getDiseases.mockRejectedValue(new Error("تعذر التحميل"));
    const loadRelated = vi.fn();
    const onRelatedLoaded = vi.fn();

    const { result } = renderHook(() => useDiseases());

    await act(async () => {
      await result.current.fetchAllData(loadRelated, onRelatedLoaded);
    });

    expect(loadRelated).not.toHaveBeenCalled();
    expect(onRelatedLoaded).not.toHaveBeenCalled();
    expect(mocks.toast.error).toHaveBeenCalledWith("تعذر التحميل");
    expect(result.current.error).toBe("تعذر التحميل");
    expect(result.current.isLoading).toBe(false);
  });
});
