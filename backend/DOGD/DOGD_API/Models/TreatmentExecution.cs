namespace DOGD_API.Models
{
    public class TreatmentExecution
    {
        public Guid Id { get; set; }
        public Guid DiagnosisId { get; set; }
        public int DoseNumber { get; set; }
        public DateTime ExecutedAt { get; set; }
        public DateTime? NextDoseAt { get; set; }

        public Diagnosis Diagnosis { get; set; }
    }

}
