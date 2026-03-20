using Backend.DTOs;
using Backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace Backend.Controllers;

[ApiController]
[Route("api/notifications")]
[Authorize]
public class NotificationController : ControllerBase
{
    private readonly NotificationService _notificationService;

    public NotificationController(NotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    private Guid? GetUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(JwtRegisteredClaimNames.Sub);
        if (Guid.TryParse(sub, out var userId)) return userId;
        return null;
    }

    [HttpGet]
    public async Task<IActionResult> GetNotifications()
    {
        try
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();
            var notifications = await _notificationService.GetUserNotificationsAsync(userId.Value);

            var response = notifications.Select(n => new NotificationResponse
            {
                Id = n.Id,
                Title = n.Title,
                Body = n.Body,
                IsRead = n.IsRead,
                CreatedAt = n.CreatedAt
            });

            return Ok(response);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("unread-count")]
    public async Task<IActionResult> GetUnreadCount()
    {
        try
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();
            var count = await _notificationService.GetUnreadCountAsync(userId.Value);
            return Ok(new { count });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{id}/read")]
    public async Task<IActionResult> MarkAsRead(Guid id)
    {
        try
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();
            var success = await _notificationService.MarkAsReadAsync(id, userId.Value);
            if (!success)
                return NotFound(new { message = "Notification not found" });

            return Ok(new { message = "Notification marked as read" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteNotification(Guid id)
    {
        try
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();
            var success = await _notificationService.DeleteNotificationAsync(id, userId.Value);
            if (!success)
                return NotFound(new { message = "Notification not found" });

            return NoContent();
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete]
    public async Task<IActionResult> ClearAllNotifications()
    {
        try
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();
            var deletedCount = await _notificationService.ClearAllNotificationsAsync(userId.Value);
            return Ok(new { deletedCount });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("device-token")]
    public async Task<IActionResult> RegisterDeviceToken([FromBody] RegisterDeviceTokenRequest request)
    {
        try
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();

            var token = request.Token?.Trim() ?? string.Empty;
            if (string.IsNullOrWhiteSpace(token))
            {
                return BadRequest(new { message = "Token is required." });
            }

            await _notificationService.RegisterDeviceTokenAsync(
                userId.Value,
                token,
                request.TimeZoneId,
                request.UtcOffsetMinutes
            );

            return Ok(new { message = "Device token registered." });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

}