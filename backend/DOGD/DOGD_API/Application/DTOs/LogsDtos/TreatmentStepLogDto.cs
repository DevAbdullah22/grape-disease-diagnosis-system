namespace DOGD_API.Application.DTOs.LogsDtos
{
    public class TreatmentStepLogDto
    {
        public int StepOrder { get; set; }
        public string PesticideName { get; set; }
        public string? PesticideImageUrl { get; set; }
        public string DosageInstructions { get; set; }
        public string? MixQuantityAndType { get; set; }
        public string SafetyInfo { get; set; }
        public string? ImportantNotes { get; set; }
    }
}
