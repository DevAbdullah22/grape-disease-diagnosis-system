

using DOGD_API.Application.Services.Notifications;
using DOGD_API.Data;
using Microsoft.EntityFrameworkCore;

namespace DOGD_API.Application.BackgroundJobs
{
    public class TreatmentReminderJob
    {
        private readonly IFcmService _fcmService;
        private readonly AppDbContext _db;

        public TreatmentReminderJob(IFcmService fcmService, AppDbContext db)
        {
            _fcmService = fcmService;
            _db = db;
        }

        public async Task SendReminder(Guid userId, Guid diagnosisId)
        {
            bool sent = false;
            try
            {
                sent = await _fcmService.SendAsync(
                    userId: userId,
                    type: "TreatmentReminder",
                    title: "⏰ تذكير جرعة العلاج",
                    body: "حان موعد الجرعة العلاجية التالية.",
                    data: new
                    {
                        DiagnosisId = diagnosisId.ToString(),
                        Screen = "notifications"
                    }
                );
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[TreatmentReminderJob] ERROR sending FCM: {ex.Message}");
            }

            try
            {
                var notif = await _db.Notifications
                    .Where(n => n.UserId == userId && n.RelatedId == diagnosisId && n.Type == "TreatmentReminder" && !n.IsSent)
                    .OrderBy(n => n.CreatedAt)
                    .FirstOrDefaultAsync();

                if (notif != null)
                {
                    notif.IsSent = sent;
                    notif.SentAt = sent ? DateTime.UtcNow : (DateTime?)null;
                    await _db.SaveChangesAsync();
                    Console.WriteLine($"[TreatmentReminderJob] Updated Notification {notif.Id} IsSent={notif.IsSent}");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[TreatmentReminderJob] ERROR updating notification record: {ex.Message}");
            }
        }
    }
}

