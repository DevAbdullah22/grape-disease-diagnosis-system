namespace DOGD_API.Application.DTOs.NotificationDtos
{
    public class RegisterUserTokenDto
    {
        public Guid UserId { get; set; }
        public string DeviceToken { get; set; }
    }

}
