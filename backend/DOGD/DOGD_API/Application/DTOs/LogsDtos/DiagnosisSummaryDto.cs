namespace DOGD_API.Application.DTOs.LogsDtos
{
    public class DiagnosisSummaryDto
    {
        public Guid DiagnosisId { get; set; }
        public string DiseaseName { get; set; }
        public DateTime DiagnosisDate { get; set; }
        public DateTime Date { get; set; } // إضافة خاصية التاريخ
        public string ImageUrl { get; set; } // إضافة خاصية صورة التشخيص
        public string Status { get; set; }
    }
}
