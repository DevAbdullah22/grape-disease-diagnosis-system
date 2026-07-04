namespace DOGD_API.Models
{
    public class Diagnosis
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid DiseaseId { get; set; }
        public string ImageUrl { get; set; }
        public float Confidence { get; set; }
        // DamagePercentage removed — severity not tracked
        public DateTime DiagnosisDate { get; set; }
        public string Status { get; set; } // Not_Treated | In_Progress | Treated

        public User User { get; set; }
        public Disease Disease { get; set; }
        public ICollection<TreatmentExecution> Executions { get; set; }
    }

}
