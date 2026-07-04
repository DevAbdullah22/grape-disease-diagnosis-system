namespace DOGD_API.Application.DTOs.LogsDtos
{
    public class TreatmentExecutionDto
    {
        public int DoseNumber { get; set; }
        public DateTime ExecutedAt { get; set; }
        public DateTime? NextDoseAt { get; set; }
    }

}
