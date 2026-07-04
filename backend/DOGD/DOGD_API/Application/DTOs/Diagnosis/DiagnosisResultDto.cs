//namespace DOGD_API.Application.DTOs.Diagnosis
//{
//    public class DiagnosisResultDto
//    {
//        public Guid DiagnosisId { get; set; }
//        // Id of the detected disease (from Diseases table)
//        public Guid DiseaseId { get; set; }
//        public string DiseaseName { get; set; }
//        public string Description { get; set; } // وصف المرض

//        public float Confidence { get; set; }
//        // DamagePercentage removed
//        public string ImageUrl { get; set; }
//        // Status: "ok" or "invalid"
//        public string Status { get; set; } = "ok";
//        // Optional message for errors or warnings
//        public string Message { get; set; } = string.Empty;
//    }

//}



namespace DOGD_API.Application.DTOs.Diagnosis
{
    public class DiagnosisResultDto
    {
        public Guid DiagnosisId { get; set; }
        // Id of the detected disease (from Diseases table)
        public Guid DiseaseId { get; set; }
        public string DiseaseName { get; set; }
        public string Description { get; set; } // وصف المرض

        public float Confidence { get; set; }
        // DamagePercentage removed
        public string ImageUrl { get; set; }
        // Status: "ok", "not_grape", "unknown_disease", or "error"
        public string Status { get; set; } = "ok";
        // Optional message for errors or warnings
        public string Message { get; set; } = string.Empty;
    }

}
