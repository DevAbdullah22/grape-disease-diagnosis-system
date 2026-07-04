namespace DOGD_API.Application.DTOs.TreatmentPlans.Admin
{
    public class CreateTreatmentStepDto
    {
        public Guid TreatmentPlanId { get; set; }

        public int StepOrder { get; set; }
        public string PesticideName { get; set; }
        public string ChemicalGroup { get; set; }

        public string? PesticideImageUrl { get; set; }

        public string DosageInstructions { get; set; }
        public string MixQuantityAndType { get; set; }
        public string SafetyInfo { get; set; }
        public string? ImportantNotes { get; set; }

    }
}
