namespace DOGD_API.Application.DTOs.TreatmentPlans.Admin
{
    public class CreateTreatmentPlanDto
    {
        public Guid DiseaseId { get; set; }
        public string Name { get; set; }
        // global interval (days) to apply between every step in the plan
        public int DoseIntervalDays { get; set; }
    }
}
