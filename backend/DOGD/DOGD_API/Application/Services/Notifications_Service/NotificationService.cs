using DOGD_API.Application.DTOs.NotificationDtos;
using DOGD_API.Application.Services.Notifications_Service;
using DOGD_API.Data;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.EntityFrameworkCore;
using System.Linq;
// Add alias for FirebaseAdmin.Messaging.Notification
using FcmNotification = FirebaseAdmin.Messaging.Notification;

namespace DOGD_API.Application.Services.Notifications
{
    public class NotificationService : INotificationService
    {
        private readonly AppDbContext _db;
        private readonly ILogger<NotificationService> _logger;

        public NotificationService(AppDbContext db, ILogger<NotificationService> logger)
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

        // ----------------------------------------------------------------------
        // Get notifications (optionally filtered by user)
        // ----------------------------------------------------------------------
        public async Task<System.Collections.Generic.List<DOGD_API.Models.Notification>> GetNotificationsAsync(System.Guid? userId)
        {
            var query = _db.Notifications.AsQueryable();
            if (userId.HasValue && userId.Value != System.Guid.Empty)
            {
                query = query.Where(n => n.UserId == userId.Value || n.UserId == System.Guid.Empty);
            }

            // Server-side filtering: return only sent notifications.
            query = query.Where(n => n.IsSent);

            return await query.OrderByDescending(n => n.CreatedAt).ToListAsync();
        }

        // ----------------------------------------------------------------------
        // Register FCM Token
        // ----------------------------------------------------------------------
        public async Task<bool> RegisterTokenAsync(RegisterUserTokenDto dto)
        {
            // We no longer rely on UserNotificationTokens table; store token directly
            // on the Users record.  This keeps things simple and matches the mobile
            // client which updates the user profile.
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == dto.UserId);
            if (user != null)
            {
                user.FcmToken = dto.DeviceToken;
                await _db.SaveChangesAsync();
            }

            return true;
        }

        // ----------------------------------------------------------------------
        // Send Notification to ONE USER
        // ----------------------------------------------------------------------
        public async Task<bool> SendToUserAsync(SendNotificationDto dto)
        {

            // Check subscription (normalize and map aliases)
            var normalized = (dto.Type ?? string.Empty).Trim();
            var mapped = normalized;
            if (string.Equals(normalized, "TreatmentReminder", StringComparison.OrdinalIgnoreCase))
                mapped = "Treatment";

            var mappedLower = mapped.ToLowerInvariant();

            bool allowed = await _db.NotificationSubscriptions
                .AnyAsync(s => s.UserId == dto.UserId && s.IsEnabled && s.Type != null && s.Type.ToLower() == mappedLower);
            Console.WriteLine($"[SendToUserAsync] UserId: {dto.UserId}, Type: {dto.Type}, MappedType: {mapped}, Subscription Allowed: {allowed}");

            if (!allowed)
            {
                Console.WriteLine($"[SendToUserAsync] Notification not sent: user not subscribed to {dto.Type}");
                return false;
            }

            var token = await _db.Users
                .Where(u => u.Id == dto.UserId)
                .Select(u => u.FcmToken)
                .FirstOrDefaultAsync();
            Console.WriteLine($"[SendToUserAsync] UserId: {dto.UserId}, FCM Token: {(token ?? "NULL")} ");

            if (string.IsNullOrEmpty(token))
            {
                Console.WriteLine($"[SendToUserAsync] Notification not sent: no FCM token for user");
                return false;
            }

            var message = new Message
            {
                Token = token,
                Notification = new FcmNotification
                {
                    Title = dto.Title,
                    Body = dto.Body
                }
            };

            bool sent = false;
            try
            {
                await FirebaseMessaging.DefaultInstance.SendAsync(message);
                sent = true;
            }
            catch (FirebaseMessagingException ex)
            {
                // If token is invalid/unregistered, clear it on the user record
                try
                {
                    var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == dto.UserId);
                    if (user != null && user.FcmToken == token)
                    {
                        user.FcmToken = null;
                        await _db.SaveChangesAsync();
                        Console.WriteLine($"Cleared invalid FCM token for user {dto.UserId}");
                    }
                }
                catch
                {
                    // ignore any DB cleanup errors
                }
            }
            catch
            {
                // generic failure - leave sent = false
            }

            // Log the notification (mark IsSent only when actually sent)
            _db.Notifications.Add(new DOGD_API.Models.Notification
            {
                Id = Guid.NewGuid(),
                UserId = dto.UserId,
                Title = dto.Title,
                Body = dto.Body,
                Type = dto.Type,
                RelatedId = dto.RelatedId,
                IsSent = sent,
                SentAt = sent ? DateTime.UtcNow : (DateTime?)null,
                CreatedAt = DateTime.UtcNow
            });

            await _db.SaveChangesAsync();

            return sent;
        }
        // ----------------------------------------------------------------------
        // Send Notification To ALL USERS
        // ----------------------------------------------------------------------
        public async Task<bool> SendToAllAsync(string type, string title, string body)
        {
            // Disabled: sending to ALL users is no longer allowed.
            // Use SendToSubscribedUsersAsync or SendToFarmersAsync instead.
            _logger.LogWarning("[SendToAllAsync] disabled - bulk send to all users is not permitted.");
            return false;
        }

        /// <summary>
        /// Send a push notification to all farmers (users that have a farm record) who are
        /// subscribed to the supplied type.  The method will record a notification row for
        /// each user and return false if no tokens were found.
        /// </summary>
        public async Task<bool> SendToSubscribedUsersAsync(string type, string title, string body, System.Guid? relatedId = null)
        {
            var normalizedType = (type ?? string.Empty).Trim().ToLowerInvariant();

            // select all users who have a non-empty FcmToken
            // and who have explicitly enabled subscription for this type.
            // NOTE: change of policy: absence of a subscription row is now treated
            // as NOT subscribed. Only users with an explicit IsEnabled==true row
            // will receive these notifications.
            var query = from user in _db.Users
                        where !string.IsNullOrEmpty(user.FcmToken)
                            && _db.NotificationSubscriptions.Any(s =>
                                 s.UserId == user.Id &&
                                 s.Type != null &&
                                 s.Type.ToLower() == normalizedType &&
                                 s.IsEnabled)
                        select new { Token = user.FcmToken, UserId = user.Id };

            var list = await query.ToListAsync();
            var tokens = list.Select(x => x.Token).Distinct().ToList();

            _logger.LogInformation("[SendToSubscribedUsersAsync] Found {TokenCount} tokens for {UserCount} users", tokens.Count, list.Select(l => l.UserId).Distinct().Count());

            if (!tokens.Any())
            {
                _logger.LogInformation("[SendToSubscribedUsersAsync] no tokens; aborting");
                return false;
            }

            var message = new MulticastMessage
            {
                Tokens = tokens,
                Notification = new FcmNotification
                {
                    Title = title,
                    Body = body
                },
                Data = relatedId.HasValue ? new Dictionary<string, string>
                {
                    { "relatedId", relatedId.Value.ToString() },
                    { "screen", "library" }
                } : null
            };

            bool overallSuccess = true;
            // Map of token -> success flag produced by the multicast response
            var tokenSuccess = new Dictionary<string, bool>(StringComparer.Ordinal);
            try
            {
                var response = await FirebaseMessaging.DefaultInstance.SendEachForMulticastAsync(message);
                _logger.LogInformation("[SendToSubscribedUsersAsync] multicast sent. Success count={Success}, Failure count={Failure}", response.SuccessCount, response.FailureCount);

                // Build token->success map. Responses are in the same order as the tokens list.
                for (int i = 0; i < response.Responses.Count && i < tokens.Count; i++)
                {
                    var resp = response.Responses[i];
                    var tok = tokens[i];
                    tokenSuccess[tok] = resp.IsSuccess;
                    if (!resp.IsSuccess)
                    {
                        overallSuccess = false;
                        _logger.LogWarning(resp.Exception, "[SendToSubscribedUsersAsync] token failed: {Token}", tok);
                        if (resp.Exception is FirebaseMessagingException fex)
                        {
                            var msg = fex.Message ?? string.Empty;
                            if (msg.Contains("not registered") || msg.Contains("Invalid") || msg.Contains("NotFound"))
                            {
                                var badUsers = await _db.Users
                                    .Where(u => u.FcmToken == tok)
                                    .ToListAsync();
                                foreach (var bad in badUsers)
                                {
                                    bad.FcmToken = null;
                                }
                                await _db.SaveChangesAsync();
                                _logger.LogInformation("[SendToSubscribedUsersAsync] cleared invalid tokens from users");
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                overallSuccess = false;
                _logger.LogError(ex, "[SendToSubscribedUsersAsync] multicast exception");
            }

            // For each user entry, record the notification and set IsSent per-token
            foreach (var entry in list)
            {
                var sentForThis = false;
                if (!string.IsNullOrEmpty(entry.Token) && tokenSuccess.ContainsKey(entry.Token))
                    sentForThis = tokenSuccess[entry.Token];

                _db.Notifications.Add(new DOGD_API.Models.Notification
                {
                    Id = Guid.NewGuid(),
                    UserId = entry.UserId,
                    Title = title,
                    Body = body,
                    Type = type,
                    RelatedId = relatedId,
                    CreatedAt = DateTime.UtcNow,
                    IsSent = sentForThis,
                    SentAt = sentForThis ? DateTime.UtcNow : (DateTime?)null
                });
            }

            await _db.SaveChangesAsync();
            return overallSuccess;
        }

        public async Task<bool> SendToFarmersAsync(string type, string title, string body)
        {
            // Require explicit subscription for farmers (absence = not subscribed)
            var normalizedType = (type ?? string.Empty).Trim().ToLowerInvariant();

            var farmerIds = await _db.Farms
                .Select(f => f.UserId)
                .Distinct()
                .ToListAsync();

            var query = from user in _db.Users
                        join farm in _db.Farms on user.Id equals farm.UserId
                        where farmerIds.Contains(user.Id)
                              && !string.IsNullOrEmpty(user.FcmToken)
                              && _db.NotificationSubscriptions.Any(s =>
                                     s.UserId == user.Id &&
                                     s.Type != null &&
                                     s.Type.ToLower() == normalizedType &&
                                     s.IsEnabled)
                        select new { Token = user.FcmToken, UserId = user.Id };

            var list = await query.ToListAsync();
            var tokens = list.Select(x => x.Token).Distinct().ToList();

            _logger.LogInformation("[SendToFarmersAsync] Found {TokenCount} tokens for {UserCount} users", tokens.Count, list.Select(l => l.UserId).Distinct().Count());

            if (!tokens.Any())
            {
                _logger.LogInformation("[SendToFarmersAsync] no tokens; aborting");
                return false;
            }

            var message = new MulticastMessage
            {
                Tokens = tokens,
                Notification = new FcmNotification
                {
                    Title = title,
                    Body = body
                }
            };

            bool overallSuccess = true;
            var tokenSuccess = new Dictionary<string, bool>(StringComparer.Ordinal);
            try
            {
                var response = await FirebaseMessaging.DefaultInstance.SendEachForMulticastAsync(message);
                _logger.LogInformation("[SendToFarmersAsync] multicast sent. Success count={Success}, Failure count={Failure}", response.SuccessCount, response.FailureCount);
                for (int i = 0; i < response.Responses.Count && i < tokens.Count; i++)
                {
                    var resp = response.Responses[i];
                    var tok = tokens[i];
                    tokenSuccess[tok] = resp.IsSuccess;
                    if (!resp.IsSuccess)
                    {
                        overallSuccess = false;
                        _logger.LogWarning(resp.Exception, "[SendToFarmersAsync] token failed: {Token}", tok);
                        if (resp.Exception is FirebaseMessagingException fex)
                        {
                            var msg = fex.Message ?? string.Empty;
                            if (msg.Contains("not registered") || msg.Contains("Invalid") || msg.Contains("NotFound"))
                            {
                                var badUsers = await _db.Users
                                    .Where(u => u.FcmToken == tok)
                                    .ToListAsync();
                                foreach (var bad in badUsers)
                                {
                                    bad.FcmToken = null;
                                }
                                await _db.SaveChangesAsync();
                                _logger.LogInformation("[SendToFarmersAsync] cleared invalid tokens from users");
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                overallSuccess = false;
                _logger.LogError(ex, "[SendToFarmersAsync] multicast exception");
            }

            foreach (var entry in list)
            {
                var sentForThis = false;
                if (!string.IsNullOrEmpty(entry.Token) && tokenSuccess.ContainsKey(entry.Token))
                    sentForThis = tokenSuccess[entry.Token];

                _db.Notifications.Add(new DOGD_API.Models.Notification
                {
                    Id = Guid.NewGuid(),
                    UserId = entry.UserId,
                    Title = title,
                    Body = body,
                    Type = type,
                    CreatedAt = DateTime.UtcNow,
                    IsSent = sentForThis,
                    SentAt = sentForThis ? DateTime.UtcNow : (DateTime?)null
                });
            }

            await _db.SaveChangesAsync();
            return overallSuccess;
        }

        // ----------------------------------------------------------------------
        // Get user's subscriptions
        // ----------------------------------------------------------------------
        public async Task<System.Collections.Generic.List<DOGD_API.Models.NotificationSubscription>> GetSubscriptionsForUserAsync(System.Guid userId)
        {
            return await _db.NotificationSubscriptions
                .Where(s => s.UserId == userId)
                .ToListAsync();
        }

        // ----------------------------------------------------------------------
        // Log a notification record (without sending)
        // ----------------------------------------------------------------------
        public async Task LogNotificationAsync(DOGD_API.Models.Notification notification)
        {
            if (notification == null) return;
            _db.Notifications.Add(notification);
            await _db.SaveChangesAsync();
        }

        // ----------------------------------------------------------------------
        // Upsert a subscription
        // ----------------------------------------------------------------------
        public async Task<DOGD_API.Models.NotificationSubscription> UpsertSubscriptionAsync(System.Guid userId, string type, bool isEnabled)
        {
            var sub = await _db.NotificationSubscriptions
                .FirstOrDefaultAsync(s => s.UserId == userId && s.Type == type);

            if (sub == null)
            {
                sub = new DOGD_API.Models.NotificationSubscription
                {
                    Id = System.Guid.NewGuid(),
                    UserId = userId,
                    Type = type,
                    IsEnabled = isEnabled
                };
                _db.NotificationSubscriptions.Add(sub);
            }
            else
            {
                sub.IsEnabled = isEnabled;
            }

            await _db.SaveChangesAsync();
            return sub;
        }

        // ----------------------------------------------------------------------
        // Mark notifications as read for a user
        // ----------------------------------------------------------------------
        public async Task<bool> MarkNotificationsReadAsync(System.Guid userId, System.Collections.Generic.List<System.Guid> ids)
        {
            if (ids == null || !ids.Any()) return true;

            var guids = ids.Distinct().ToList();

            var notifications = await _db.Notifications
                .Where(n => guids.Contains(n.Id) && (n.UserId == userId || n.UserId == System.Guid.Empty))
                .ToListAsync();

            if (!notifications.Any()) return true;

            foreach (var notif in notifications)
            {
                notif.IsRead = true;
            }

            await _db.SaveChangesAsync();
            return true;
        }

        // ----------------------------------------------------------------------
        // Delete notifications for a user (or global notifications with empty UserId)
        // ----------------------------------------------------------------------
        public async Task<bool> DeleteNotificationsAsync(System.Guid userId, System.Collections.Generic.List<System.Guid> ids)
        {
            if (ids == null || !ids.Any()) return true;

            var guids = ids.Distinct().ToList();

            var notifications = await _db.Notifications
                .Where(n => guids.Contains(n.Id) && (n.UserId == userId || n.UserId == System.Guid.Empty))
                .ToListAsync();

            if (!notifications.Any()) return true;

            _db.Notifications.RemoveRange(notifications);
            await _db.SaveChangesAsync();
            return true;
        }

        public async Task<int> GetUnreadNotificationsCountAsync(System.Guid userId)
        {
            if (userId == System.Guid.Empty) return 0;

            return await _db.Notifications
                .Where(n =>
                    (n.UserId == userId || n.UserId == System.Guid.Empty) &&
                    n.IsSent &&
                    !n.IsRead)
                .CountAsync();
        }
    }
}
