using Backend.Data;
using Backend.DTOs;
using Backend.Models;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services;

public class NotificationService
{
    private readonly AppDbContext _db;
    public NotificationService(AppDbContext db)
    {
        _db = db;
    }

    public async Task<List<NotificationDto>> GetNotificationsAsync(Guid userId, CancellationToken ct)
    {
        return await _db.Set<Notification>()
            .Where(n => n.UserId == userId)
            .OrderByDescending(n => n.CreatedAt)
            .Select(n => new NotificationDto
            {
                Id = n.Id,
                Title = n.Title,
                Body = n.Body,
                IsRead = n.IsRead,
                CreatedAt = n.CreatedAt
            })
            .ToListAsync(ct);
    }

    public async Task<int> GetUnreadCountAsync(Guid userId, CancellationToken ct)
    {
        return await _db.Set<Notification>()
            .Where(n => n.UserId == userId && !n.IsRead)
            .CountAsync(ct);
    }

    public async Task MarkAsReadAsync(Guid userId, Guid notificationId, CancellationToken ct)
    {
        var notif = await _db.Set<Notification>()
            .FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == userId, ct);
        if (notif == null) return;
        if (!notif.IsRead)
        {
            notif.IsRead = true;
            await _db.SaveChangesAsync(ct);
        }
    }

    public async Task AddNotificationAsync(Guid userId, string title, string body, CancellationToken ct)
    {
        var entity = new Notification
        {
            UserId = userId,
            Title = title,
            Body = body,
            CreatedAt = DateTime.UtcNow,
            IsRead = false
        };
        _db.Set<Notification>().Add(entity);
        await _db.SaveChangesAsync(ct);
    }
}
