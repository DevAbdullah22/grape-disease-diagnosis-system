

using DOGD_API.Application.DTOs.NotificationDtos;
using DOGD_API.Application.Services.Notifications_Service;
using Microsoft.AspNetCore.Mvc;
using DOGD_API.Models;

// DTO for logging notifications is LogNotificationDto in Application.DTOs.NotificationDtos

namespace DOGD_API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class NotificationController : ControllerBase
    {
        private readonly INotificationService _service;

        public NotificationController(INotificationService service)
        {
            _service = service;
        }

        // GET api/notifications
        [HttpGet("/api/notifications")]
        public async Task<IActionResult> GetAllNotifications()
        {
            var list = await _service.GetNotificationsAsync(null);
            return Ok(list);
        }

        // GET api/notifications/{userId}
        [HttpGet("/api/notifications/{userId:guid}")]
        public async Task<IActionResult> GetNotificationsForUser([FromRoute] System.Guid userId)
        {
            var list = await _service.GetNotificationsAsync(userId);
            return Ok(list);
        }

        // GET api/notifications/unread-count?userId={guid}
        [HttpGet("/api/notifications/unread-count")]
        public async Task<IActionResult> GetUnreadCount([FromQuery] System.Guid userId)
        {
            if (userId == System.Guid.Empty) return BadRequest("Invalid userId");
            var count = await _service.GetUnreadNotificationsCountAsync(userId);
            return Ok(new { unreadCount = count });
        }

        [HttpPost("register-token")]
        public async Task<IActionResult> RegisterDevice([FromBody] RegisterUserTokenDto dto)
        {
            await _service.RegisterTokenAsync(dto);
            return Ok("Device token registered.");
        }

        [HttpPost("send-user")]
        public async Task<IActionResult> SendToUser([FromBody] SendNotificationDto dto)
        {
            var result = await _service.SendToUserAsync(dto);
            return result ? Ok("Sent") : BadRequest("Subscription disabled or token missing");
        }

        [HttpPost("send-all")]
        public async Task<IActionResult> SendToAll([FromBody] SendNotificationDto dto)
        {
            var result = await _service.SendToAllAsync(dto.Type, dto.Title, dto.Body);
            return result ? Ok("Sent to all") : BadRequest("No tokens found");
        }

        // POST api/notifications/send-farmers
        [HttpPost("send-farmers")]
        public async Task<IActionResult> SendToFarmers([FromBody] SendNotificationDto dto)
        {
            var result = await _service.SendToFarmersAsync(dto.Type, dto.Title, dto.Body);
            return result ? Ok("Sent to farmers") : BadRequest("No farmer tokens or none subscribed");
        }

        // POST api/notifications/send-subscribed
        [HttpPost("send-subscribed")]
        public async Task<IActionResult> SendToSubscribedUsers([FromBody] SendNotificationDto dto)
        {
            var result = await _service.SendToSubscribedUsersAsync(dto.Type, dto.Title, dto.Body, dto.RelatedId);
            return result ? Ok("Sent to subscribed users") : BadRequest("No tokens or none subscribed");
        }

        // POST api/notifications/log
        [HttpPost("log")]
        public async Task<IActionResult> LogNotification([FromBody] LogNotificationDto dto)
        {
            if (dto == null) return BadRequest("Invalid payload");

            var notification = new Notification
            {
                Id = Guid.NewGuid(),
                UserId = dto.UserId,
                Title = dto.Title ?? string.Empty,
                Body = dto.Body ?? string.Empty,
                Type = dto.Type ?? string.Empty,
                RelatedId = dto.RelatedId,
                CreatedAt = dto.ScheduledAt ?? DateTime.UtcNow,
                IsSent = false
            };

            await _service.LogNotificationAsync(notification);
            return Ok(new { success = true, id = notification.Id });
        }

        // GET api/Notification/subscriptions?userId={guid}
        [HttpGet("subscriptions")]
        public async Task<IActionResult> GetSubscriptions([FromQuery] System.Guid userId)
        {
            var subs = await _service.GetSubscriptionsForUserAsync(userId);
            return Ok(subs);
        }

        // PUT api/Notification/subscriptions
        [HttpPut("subscriptions")]
        public async Task<IActionResult> UpsertSubscription([FromBody] UpdateSubscriptionDto dto)
        {
            var sub = await _service.UpsertSubscriptionAsync(dto.UserId, dto.Type, dto.IsEnabled);
            return Ok(sub);
        }

        // PUT api/notifications/mark-read
        [HttpPut("/api/notifications/mark-read")]
        public async Task<IActionResult> MarkNotificationsRead([FromBody] MarkNotificationsReadDto dto)
        {
            if (dto == null || dto.Ids == null) return BadRequest("Invalid payload");
            var result = await _service.MarkNotificationsReadAsync(dto.UserId, dto.Ids);
            return Ok(new { success = result });
        }

        // POST api/notifications/delete
        [HttpPost("/api/notifications/delete")]
        public async Task<IActionResult> DeleteNotifications([FromBody] MarkNotificationsReadDto dto)
        {
            if (dto == null || dto.Ids == null) return BadRequest("Invalid payload");
            var result = await _service.DeleteNotificationsAsync(dto.UserId, dto.Ids);
            return Ok(new { success = result });
        }
    }

}
