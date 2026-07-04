using DOGD_API.Application.DTOs.DiseaseDtos;

namespace DOGD_API.Application.DTOs.LogsDtos
{
    public class DiagnosisDetailsDto
    {
        public Guid DiagnosisId { get; set; }
        // expose the disease identifier so clients can request related data (eg. reference images)
        public Guid DiseaseId { get; set; }

        public string DiseaseName { get; set; }
        public string DiseaseDescription { get; set; }
        public float Confidence { get; set; }
        public string ImageUrl { get; set; }
        public DateTime DiagnosisDate { get; set; }
        public string Status { get; set; }
        public List<ReferenceImageDto> ReferenceImages { get; set; } = new List<ReferenceImageDto>();



        public List<TreatmentExecutionDto> Executions { get; set; }
        public TreatmentPlanLogDto? TreatmentPlan { get; set; }
    }

}
