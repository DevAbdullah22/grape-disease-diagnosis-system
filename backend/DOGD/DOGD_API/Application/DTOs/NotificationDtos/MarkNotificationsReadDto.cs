namespace DOGD_API.Application.DTOs.NotificationDtos
{
    public class MarkNotificationsReadDto
    {
        public System.Guid UserId { get; set; }
        public System.Collections.Generic.List<System.Guid> Ids { get; set; } = new System.Collections.Generic.List<System.Guid>();
    }
}
