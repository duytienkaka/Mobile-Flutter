using Microsoft.AspNetCore.SignalR;

namespace Backend.Hubs;

public class NotificationHub : Hub
{
    // Hub left intentionally simple; server will call Clients.All.SendAsync("ReceiveNotification", payload)
}
