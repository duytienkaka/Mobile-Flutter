using Backend.Data;
using Backend.Models;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services;

public class NotificationService
{
    private readonly AppDbContext _context;

    public NotificationService(AppDbContext context)
    {
        _context = context;
    }

    public async Task RegisterDeviceTokenAsync(
        Guid userId,
        string token,
        string? timeZoneId,
        int? utcOffsetMinutes)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null)
        {
            throw new Exception("User not found.");
        }

        user.FcmToken = token;
        user.TimeZoneId = string.IsNullOrWhiteSpace(timeZoneId) ? null : timeZoneId.Trim();
        user.UtcOffsetMinutes = utcOffsetMinutes;

        await _context.SaveChangesAsync();
    }

    public async Task<User?> GetUserPushInfoAsync(Guid userId)
    {
        return await _context.Users
            .FirstOrDefaultAsync(u => u.Id == userId);
    }

    public async Task<Notification> CreateNotificationAsync(Guid userId, string title, string body)
    {
        var notification = new Notification
        {
            UserId = userId,
            Title = title,
            Body = body,
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };

        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();

        return notification;
    }

    public async Task<List<Notification>> GetUserNotificationsAsync(Guid userId)
    {
        return await _context.Notifications
            .Where(n => n.UserId == userId)
            .OrderByDescending(n => n.CreatedAt)
            .ToListAsync();
    }

    public async Task<bool> MarkAsReadAsync(Guid notificationId, Guid userId)
    {
        var notification = await _context.Notifications
            .FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == userId);

        if (notification == null)
            return false;

        notification.IsRead = true;
        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<int> GetUnreadCountAsync(Guid userId)
    {
        return await _context.Notifications
            .Where(n => n.UserId == userId && !n.IsRead)
            .CountAsync();
    }

    public async Task<bool> DeleteNotificationAsync(Guid notificationId, Guid userId)
    {
        var notification = await _context.Notifications
            .FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == userId);

        if (notification == null)
            return false;

        _context.Notifications.Remove(notification);
        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<int> ClearAllNotificationsAsync(Guid userId)
    {
        var notifications = await _context.Notifications
            .Where(n => n.UserId == userId)
            .ToListAsync();

        if (notifications.Count == 0)
            return 0;

        _context.Notifications.RemoveRange(notifications);
        await _context.SaveChangesAsync();
        return notifications.Count;
    }

    public async Task<User> GetTestUserAsync()
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == "test@gmail.com");
        if (user == null)
        {
            throw new Exception("Test user not found. Please run seed first.");
        }
        return user;
    }
}