
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using DOGD_API.Data;
using Microsoft.EntityFrameworkCore;
namespace DOGD_API.Application.Services.Notifications
{
    public interface IFcmService
    {
        Task<bool> SendAsync(Guid userId, string type, string title, string body, object data = null);
    }

    public class UnifiedFcmService : IFcmService
    {
        private readonly AppDbContext _db;
        private readonly ILogger<UnifiedFcmService> _logger;

        public UnifiedFcmService(AppDbContext db, ILogger<UnifiedFcmService> logger)
        {
            _db = db;
            _logger = logger;

            if (FirebaseApp.DefaultInstance == null)
            {
                FirebaseApp.Create(new AppOptions
                {
                    Credential = GoogleCredential.FromFile("firebase-key.json")
                });
            }
        }

        public async Task<bool> SendAsync(Guid userId, string type, string title, string body, object data = null)
        {
            // 1️⃣ تحقق من الاشتراك
            // Normalize and map known aliases (e.g. TreatmentReminder -> Treatment)
            var normalizedType = (type ?? string.Empty).Trim();
            string mappedType = normalizedType;
            if (string.Equals(normalizedType, "TreatmentReminder", StringComparison.OrdinalIgnoreCase))
            {
                mappedType = "Treatment";
            }

            var mappedTypeLower = mappedType.ToLowerInvariant();

            bool subscribed = await _db.NotificationSubscriptions
                .AnyAsync(s => s.UserId == userId && s.IsEnabled && s.Type != null && s.Type.ToLower() == mappedTypeLower);

            if (!subscribed)
            {
                _logger.LogWarning("🚫 User {UserId} not subscribed to {Type}", userId, type);
                return false;
            }

            // 2️⃣ جلب توكن المستخدم - مع fallback إلى UserNotificationTokens
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId);

            string? token = user?.FcmToken;

            

                if (!string.IsNullOrEmpty(token) && user != null)
                {
                    // backfill user's FcmToken for future quick reads
                    try
                    {
                        user.FcmToken = token;
                        await _db.SaveChangesAsync();
                        _logger.LogInformation("ℹ️ Backfilled FcmToken for user {UserId}", userId);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "⚠ Failed to backfill FcmToken for user {UserId}", userId);
                    }
                }
            

            if (string.IsNullOrEmpty(token))
            {
                _logger.LogWarning("⚠ User {UserId} has no FCM token", userId);
                return false;
            }

            // 3️⃣ تجهيز البيانات الإضافية
            Dictionary<string, string>? dataDict = null;
            if (data != null)
            {
                dataDict = data.GetType()
                    .GetProperties()
                    .ToDictionary(
                        p => p.Name,
                        p => p.GetValue(data)?.ToString() ?? ""
                    );
            }

            var message = new Message
            {
                Token = token,
                Notification = new Notification
                {
                    Title = title,
                    Body = body
                },
                Data = dataDict
            };

            try
            {
                await FirebaseMessaging.DefaultInstance.SendAsync(message);
                _logger.LogInformation("✅ FCM sent to user {UserId}", userId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "🔥 FCM failed for user {UserId}", userId);
                return false;
            }
        }
    }
}
