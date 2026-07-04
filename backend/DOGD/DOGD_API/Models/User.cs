namespace DOGD_API.Models
{
    public class User
    {
        public Guid Id { get; set; }

        public string FirebaseUid { get; set; }

        public string FullName { get; set; }

        public string Email { get; set; }

        public bool EmailVerified { get; set; }

        public DateTime CreatedAt { get; set; }

        public DateTime? LastLogin { get; set; }

        public string? PhotoUrl { get; set; }

        public string? FcmToken { get; set; }

        public ICollection<Diagnosis> Diagnoses { get; set; }
    }
}