namespace DOGD_API.Models
{
    public class NotificationSubscription
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string Type { get; set; } // Treatment, Weather, Library
        public bool IsEnabled { get; set; }

        public User User { get; set; }
    }

}
