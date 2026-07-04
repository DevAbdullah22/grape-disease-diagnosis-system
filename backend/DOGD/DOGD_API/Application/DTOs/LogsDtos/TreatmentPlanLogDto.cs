namespace DOGD_API.Application.DTOs.LogsDtos
{
    public class TreatmentPlanLogDto
    {
        public string Name { get; set; }
        public int DoseIntervalDays { get; set; }
        public List<TreatmentStepLogDto> Steps { get; set; }
    }
}
