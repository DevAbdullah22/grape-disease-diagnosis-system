namespace DOGD_API.Application.DTOs.NotificationDtos
{
    public class UpdateSubscriptionDto
    {
        public System.Guid UserId { get; set; }
        public string Type { get; set; }
        public bool IsEnabled { get; set; }
    }
}
