namespace DOGD_API.Application.DTOs.User
{
    public class UpdateFcmTokenRequestDto
    {
        public string FirebaseUid { get; set; }
        public string Token { get; set; }
    }
}
