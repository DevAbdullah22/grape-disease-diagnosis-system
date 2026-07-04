using DOGD_API.Application.DTOs.TreatmentPlans.Admin;
using DOGD_API.Models;
using Microsoft.AspNetCore.Http;

namespace DOGD_API.Application.Services.Treatment_Services
{
    public interface IAdminTreatmentPlanService
    {
        // ===== Treatment Plan =====
        Task<TreatmentPlan> CreatePlanAsync(CreateTreatmentPlanDto dto);
        Task<TreatmentPlan> UpdatePlanAsync(UpdateTreatmentPlanDto dto);
        Task DeletePlanAsync(Guid planId);
        Task<TreatmentPlan?> GetPlanByIdAsync(Guid planId);
        Task<List<TreatmentPlan>> GetPlansByDiseaseAsync(Guid diseaseId);

        // ===== Treatment Steps =====
        Task<TreatmentStep> CreateStepAsync(
         CreateTreatmentStepDto dto,
         IFormFile? pesticideImage);

        Task<TreatmentStep> UpdateStepAsync(
            UpdateTreatmentStepDto dto,
            IFormFile? pesticideImage);

        // adjust order of multiple steps in a single operation
        Task UpdateStepsOrderAsync(Guid planId, List<UpdateStepOrderDto> orders);

        // retrieve steps belonging to a specific plan
        Task<List<TreatmentStep>> GetStepsByPlanAsync(Guid planId);

        Task DeleteStepAsync(Guid stepId);

        // Debug helper
        Task<List<TreatmentPlan>> GetAllPlansAsync();
    }
}
