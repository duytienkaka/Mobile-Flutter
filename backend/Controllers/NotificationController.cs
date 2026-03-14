using Backend.DTOs;
using Backend.Services;
using Backend.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
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
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier);
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

    [HttpGet("test-ingredients")]
    [AllowAnonymous]
    public async Task<IActionResult> GetTestIngredients([FromServices] AppDbContext dbContext)
    {
        try
        {
            var user = await dbContext.Users.FirstOrDefaultAsync(u => u.Email == "test@gmail.com");
            if (user == null) return NotFound(new { message = "Test user not found" });

            var ingredients = await dbContext.Ingredients
                .Where(x => x.UserId == user.Id)
                .Select(x => new
                {
                    x.Id,
                    x.Name,
                    x.Quantity,
                    x.Unit,
                    x.ExpiredAt,
                    x.Category,
                    DaysLeft = x.ExpiredAt.HasValue ? (x.ExpiredAt.Value - DateTime.UtcNow).Days : (int?)null
                })
                .ToListAsync();

            return Ok(ingredients);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("check-expired")]
    [AllowAnonymous]
    public async Task<IActionResult> CheckExpiredIngredients([FromServices] AppDbContext dbContext)
    {
        try
        {
            var now = DateTime.UtcNow;
            var warningDate = now.AddDays(3);

            // Get all users with ingredients expiring soon
            var usersWithExpiringIngredients = await dbContext.Ingredients
                .Where(x => x.ExpiredAt.HasValue && x.ExpiredAt <= warningDate)
                .Select(x => x.UserId)
                .Distinct()
                .ToListAsync();

            var createdCount = 0;

            foreach (var userId in usersWithExpiringIngredients)
            {
                var expiringIngredients = await dbContext.Ingredients
                    .Where(x => x.UserId == userId && x.ExpiredAt.HasValue && x.ExpiredAt <= warningDate)
                    .ToListAsync();

                foreach (var ingredient in expiringIngredients)
                {
                    var daysLeft = (ingredient.ExpiredAt!.Value - now).Days;

                    string title, body;
                    if (daysLeft <= 0)
                    {
                        title = "Nguyên liệu đã hết hạn";
                        body = $"{ingredient.Name} đã hết hạn sử dụng. Vui lòng kiểm tra và xử lý.";
                    }
                    else
                    {
                        title = "Nguyên liệu sắp hết hạn";
                        body = $"{ingredient.Name} sẽ hết hạn trong {daysLeft} ngày. Hãy sử dụng sớm.";
                    }

                    // Check if we already sent a notification for this ingredient recently
                    var recentNotification = await dbContext.Notifications
                        .Where(n => n.UserId == userId &&
                                   n.Title == title &&
                                   n.Body.Contains(ingredient.Name) &&
                                   n.CreatedAt > now.AddHours(-24))
                        .FirstOrDefaultAsync();

                    if (recentNotification == null)
                    {
                        await _notificationService.CreateNotificationAsync(userId, title, body);
                        createdCount++;
                    }
                }
            }

            return Ok(new { message = $"Checked expired ingredients. Created {createdCount} notifications." });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("test-fetch")]
    [AllowAnonymous]
    public async Task<IActionResult> GetTestNotifications([FromServices] AppDbContext dbContext)
    {
        try
        {
            var user = await dbContext.Users.FirstOrDefaultAsync(u => u.Email == "test@gmail.com");
            if (user == null) return NotFound(new { message = "Test user not found" });

            var notifications = await dbContext.Notifications
                .Where(n => n.UserId == user.Id)
                .OrderByDescending(n => n.CreatedAt)
                .ToListAsync();

            var response = notifications.Select(n => new
            {
                n.Id,
                n.Title,
                n.Body,
                n.IsRead,
                n.CreatedAt
            });

            return Ok(response);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}