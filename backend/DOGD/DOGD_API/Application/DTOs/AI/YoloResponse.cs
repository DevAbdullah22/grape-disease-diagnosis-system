//namespace DOGD_API.Application.DTOs.AI
//{
//    public class YoloResponse
//    {
//        public string Status { get; set; } = "";
//        public string? Class { get; set; } = "";
//        public float? Confidence { get; set; }
//    }
//}


namespace DOGD_API.Application.DTOs.AI
{
    public class YoloResponse
    {
        // Unified status coming from FastAPI (not_grape / disease_detected / disease_not_detected / uncertain)
        public string Status { get; set; } = "";
        public string? Class { get; set; } = "";
        public float? Confidence { get; set; }
        // Optional safe message from AI service
        public string? Message { get; set; }
    }
}
