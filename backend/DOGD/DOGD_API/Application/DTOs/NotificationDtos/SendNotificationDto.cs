namespace DOGD_API.Application.DTOs.NotificationDtos
{
    public class SendNotificationDto
    {
        public Guid UserId { get; set; }
        public string Title { get; set; }
        public string Body { get; set; }
        public string Type { get; set; }
        public Guid? RelatedId { get; set; }
    }

}
