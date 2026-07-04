namespace DOGD_API.Application.DTOs.Diagnosis
{
    public class DiagnosisRequestDto
    {
        public IFormFile Image { get; set; }
        public Guid UserId { get; set; }
    }

}
