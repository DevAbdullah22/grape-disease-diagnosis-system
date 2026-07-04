using DOGD_API.Application.DTOs.LogsDtos;

namespace DOGD_API.Application.DTOs.TreatmentPlans
{
    public class TreatmentPlanDto
    {
        public Guid DiagnosisId { get; set; }

        public Guid DiseaseId { get; set; }
        public string DiseaseName { get; set; }

        public string PlanName { get; set; }

        // global interval value stored on the plan
        public int DoseIntervalDays { get; set; }

        public List<TreatmentStepDto> Steps { get; set; }

        // Executions for this diagnosis (used to compute per-step status)
        public List<TreatmentExecutionDto> Executions { get; set; }
    }
}
