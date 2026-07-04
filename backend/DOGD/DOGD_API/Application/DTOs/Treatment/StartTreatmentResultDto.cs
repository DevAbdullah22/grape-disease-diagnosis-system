namespace DOGD_API.Application.DTOs.Treatment
{
    // Application/DTOs/Treatment
    

    public class StartTreatmentResultDto
    {
        public Guid ExecutionId { get; set; }
        public int DoseNumber { get; set; }
        public DateTime ExecutedAt { get; set; }
        public DateTime? NextDoseAt { get; set; }
        public string Message { get; set; } // رسالة توضيحية للحالة
    }

    

}
