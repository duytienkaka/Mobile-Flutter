using Backend.Hubs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;

namespace Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class NotificationsController : ControllerBase
{
    private readonly IHubContext<NotificationHub> _hub;

    public NotificationsController(IHubContext<NotificationHub> hub)
    {
        _hub = hub;
    }

    // Test endpoint to broadcast a notification to all connected clients
    [HttpPost("send-test")]
    public async Task<IActionResult> SendTestNotification([FromBody] TestNotificationRequest req)
    {
        var payload = new {
            id = Guid.NewGuid().ToString(),
            title = req.Title ?? "Thông báo mới",
            body = req.Body ?? "Nội dung thông báo",
            createdAt = DateTime.UtcNow.ToString("o")
        };

        await _hub.Clients.All.SendAsync("ReceiveNotification", payload);
        return Ok(new { sent = true });
    }
}

public class TestNotificationRequest
{
    public string? Title { get; set; }
    public string? Body { get; set; }
}
