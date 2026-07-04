using DOGD_API.Application.DTOs.Treatment;
using DOGD_API.Application.DTOs.TreatmentPlans;

namespace DOGD_API.Application.Services.Treatment_Services
{
    public interface ITreatmentService
    {
      
        // =========================
        // NEW (Step-based)
        // =========================
        Task<TreatmentPlanDto> GetTreatmentPlanAsync(Guid diagnosisId);
        // Allow optional stepOrder to execute a specific step (manual override)
        Task<StartTreatmentResultDto> ExecuteTreatmentStepAsync(Guid diagnosisId, int? stepOrder = null);
        Task<TtsResultDto> GenerateTreatmentPlanAudioAsync(Guid diagnosisId);
    }
}
