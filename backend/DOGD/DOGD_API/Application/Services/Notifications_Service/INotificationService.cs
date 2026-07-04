

using DOGD_API.Application.DTOs.NotificationDtos;

namespace DOGD_API.Application.Services.Notifications_Service
{

    public interface INotificationService
    {
        Task<bool> RegisterTokenAsync(RegisterUserTokenDto dto);
        Task<bool> SendToUserAsync(SendNotificationDto dto);
        Task<bool> SendToAllAsync(string type, string title, string body);
        /// <summary>
        /// Sends a push notification to all users who are subscribed to the given type.
        /// This replaces the earlier farm‑only notification and covers any active user.
        /// </summary>
        Task<bool> SendToSubscribedUsersAsync(string type, string title, string body, System.Guid? relatedId = null);
        /// <summary>
        /// Sends a push notification to all users who own a farm and are subscribed to the given type.
        /// This method may still be used in contexts where we only care about farmers.
        /// </summary>
        Task<bool> SendToFarmersAsync(string type, string title, string body);
        Task<System.Collections.Generic.List<DOGD_API.Models.Notification>> GetNotificationsAsync(System.Guid? userId);
        Task<System.Collections.Generic.List<DOGD_API.Models.NotificationSubscription>> GetSubscriptionsForUserAsync(System.Guid userId);
        Task<DOGD_API.Models.NotificationSubscription> UpsertSubscriptionAsync(System.Guid userId, string type, bool isEnabled);
        Task<bool> MarkNotificationsReadAsync(System.Guid userId, System.Collections.Generic.List<System.Guid> ids);
        Task LogNotificationAsync(DOGD_API.Models.Notification notification);
        Task<bool> DeleteNotificationsAsync(System.Guid userId, System.Collections.Generic.List<System.Guid> ids);
        Task<int> GetUnreadNotificationsCountAsync(System.Guid userId);
    }

}
