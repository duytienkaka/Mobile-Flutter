using Backend.Services;
using Backend.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using System.IdentityModel.Tokens.Jwt;

namespace Backend.Controllers.Notification;

[ApiController]
[Route("notifications")]
[Authorize]
public class NotificationController : ControllerBase
{
    private readonly NotificationService _service;

    public NotificationController(NotificationService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<List<NotificationDto>>> GetAll(CancellationToken ct = default)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();
        var list = await _service.GetNotificationsAsync(userId.Value, ct);
        return Ok(list);
    }

    [HttpGet("unread-count")]
    public async Task<ActionResult<int>> GetUnreadCount(CancellationToken ct = default)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();
        var count = await _service.GetUnreadCountAsync(userId.Value, ct);
        return Ok(count);
    }

    [HttpPost("read/{id}")]
    public async Task<IActionResult> MarkRead(Guid id, CancellationToken ct = default)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();
        await _service.MarkAsReadAsync(userId.Value, id, ct);
        return Ok();
    }

    // endpoint intended for server-side usage to create a notification for a user
    [HttpPost("")] // this could be used by admin or by internal services
    public async Task<IActionResult> Create([FromBody] NotificationDto dto, CancellationToken ct = default)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();
        if (string.IsNullOrWhiteSpace(dto.Title) || string.IsNullOrWhiteSpace(dto.Body))
            return BadRequest(new { message = "Title and body are required." });
        await _service.AddNotificationAsync(userId.Value, dto.Title, dto.Body, ct);
        return Ok();
    }

    // Test endpoint - only for development
    [HttpPost("test-create")]
    [AllowAnonymous]
    public async Task<IActionResult> TestCreate(
        [FromQuery] string userId,
        [FromBody] NotificationDto dto,
        CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(userId))
            return BadRequest(new { message = "userId query parameter is required." });
        if (!Guid.TryParse(userId, out var uid))
            return BadRequest(new { message = "Invalid userId format. Must be a valid GUID." });
        if (string.IsNullOrWhiteSpace(dto.Title) || string.IsNullOrWhiteSpace(dto.Body))
            return BadRequest(new { message = "Title and body are required." });

        await _service.AddNotificationAsync(uid, dto.Title, dto.Body, ct);
        return Ok(new { message = "Notification created successfully." });
    }

    private Guid? GetUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(JwtRegisteredClaimNames.Sub);
        if (Guid.TryParse(sub, out var userId)) return userId;
        return null;
    }
}