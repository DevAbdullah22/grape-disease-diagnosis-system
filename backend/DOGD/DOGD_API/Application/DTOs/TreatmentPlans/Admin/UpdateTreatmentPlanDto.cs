namespace DOGD_API.Application.DTOs.TreatmentPlans.Admin
{
    public class UpdateTreatmentPlanDto
    {
        public Guid Id { get; set; }
        public string Name { get; set; }

        // keep interval in sync when editing plan
        public int DoseIntervalDays { get; set; }
    }
}
