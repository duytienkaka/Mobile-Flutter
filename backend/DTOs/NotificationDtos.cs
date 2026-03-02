using System;

namespace Backend.DTOs;

public class NotificationDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = "";
    public string Body { get; set; } = "";
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class MarkNotificationReadDto
{
    public Guid Id { get; set; }
}