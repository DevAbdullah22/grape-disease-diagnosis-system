namespace DOGD_API.Models
{
    public class Notification
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string Title { get; set; }
        public string Body { get; set; }
        public string Type { get; set; }   // TreatmentReminder, WeatherAlert, etc.
        public Guid? RelatedId { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsSent { get; set; }
        public DateTime? SentAt { get; set; }

        public User User { get; set; }
        public bool IsRead { get; set; } // <-- Add this property
    }

}
