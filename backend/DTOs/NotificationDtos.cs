namespace Backend.DTOs;

public class NotificationResponse
{
    public Guid Id { get; set; }
    public string Title { get; set; } = "";
    public string Body { get; set; } = "";
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class NotificationCreateRequest
{
    public string Title { get; set; } = "";
    public string Body { get; set; } = "";
}