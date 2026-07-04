namespace DOGD_API.Application.DTOs.User
{
    public class FirebaseRegisterRequestDto
    {
        public string IdToken { get; set; }
        public string? FullName { get; set; }
        public string? PhotoUrl { get; set; }
    }
}