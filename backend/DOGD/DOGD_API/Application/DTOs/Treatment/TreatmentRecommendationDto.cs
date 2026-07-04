namespace DOGD_API.Application.DTOs.Treatment
{
    public class TreatmentRecommendationDto
    {
        public Guid DiagnosisId { get; set; }
        public Guid DiseaseId { get; set; }
        public string DiseaseName { get; set; }
        // Min/Max severity expressed as percent (0..100)
        public double MinPercent { get; set; }
        public double MaxPercent { get; set; }
        public string PesticideName { get; set; }
        public string PesticideImageUrl { get; set; }
        public string DosageInstructions { get; set; }
        // ملاحظات مهمة مرتبطة بهذه التوصية
        public string? ImportantNotes { get; set; }
        // مثال : 75-50 مل / 100 لتر ماء
        public string? MixQuantityAndType { get; set; }
        public string SafetyInfo { get; set; }
        public int TotalDoses { get; set; }
        public int DoseIntervalDays { get; set; }
    }
}