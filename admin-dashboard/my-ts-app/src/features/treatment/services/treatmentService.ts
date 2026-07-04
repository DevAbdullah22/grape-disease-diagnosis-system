import {
  createPlan as createPlanApi,
  createStep as createStepApi,
  deletePlan as deletePlanApi,
  deleteStep as deleteStepApi,
  getDiseases as getDiseasesApi,
  getPlansByDisease as getPlansByDiseaseApi,
  reorderSteps as reorderStepsApi,
  updatePlan as updatePlanApi,
  updateStep as updateStepApi
} from "../../../services/api";

export async function getDiseases() {
  return getDiseasesApi();
}

export async function getPlansByDisease(
  diseaseId: Parameters<typeof getPlansByDiseaseApi>[0]
) {
  return getPlansByDiseaseApi(diseaseId);
}

export async function createPlan(
  dto: Parameters<typeof createPlanApi>[0]
) {
  return createPlanApi(dto);
}

export async function updatePlan(
  dto: Parameters<typeof updatePlanApi>[0]
) {
  return updatePlanApi(dto);
}

export async function deletePlan(
  planId: Parameters<typeof deletePlanApi>[0]
) {
  return deletePlanApi(planId);
}

export async function createStep(
  formData: Parameters<typeof createStepApi>[0]
) {
  return createStepApi(formData);
}

export async function updateStep(
  formData: Parameters<typeof updateStepApi>[0]
) {
  return updateStepApi(formData);
}

export async function deleteStep(
  stepId: Parameters<typeof deleteStepApi>[0]
) {
  return deleteStepApi(stepId);
}

export async function reorderSteps(
  planId: Parameters<typeof reorderStepsApi>[0],
  steps: Parameters<typeof reorderStepsApi>[1]
) {
  return reorderStepsApi(planId, steps);
}
