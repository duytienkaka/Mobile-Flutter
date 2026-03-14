using Backend.Data;
using Backend.Services;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services;

public class ExpiredIngredientsCheckerService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<ExpiredIngredientsCheckerService> _logger;
    private readonly TimeSpan _checkInterval = TimeSpan.FromHours(24); // Check daily

    public ExpiredIngredientsCheckerService(
        IServiceProvider serviceProvider,
        ILogger<ExpiredIngredientsCheckerService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("ExpiredIngredientsCheckerService is starting.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await CheckExpiredIngredientsAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred while checking expired ingredients.");
            }

            await Task.Delay(_checkInterval, stoppingToken);
        }

        _logger.LogInformation("ExpiredIngredientsCheckerService is stopping.");
    }

    private async Task CheckExpiredIngredientsAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var notificationService = scope.ServiceProvider.GetRequiredService<NotificationService>();

        var now = DateTime.UtcNow;
        var warningDate = now.AddDays(3); // Warning 3 days before expiry

        // Get all users with ingredients expiring soon
        var usersWithExpiringIngredients = await dbContext.Ingredients
            .Where(x => x.ExpiredAt.HasValue && x.ExpiredAt <= warningDate)
            .Select(x => x.UserId)
            .Distinct()
            .ToListAsync();

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
                               n.CreatedAt > now.AddHours(-24)) // Within last 24 hours
                    .FirstOrDefaultAsync();

                if (recentNotification == null)
                {
                    await notificationService.CreateNotificationAsync(userId, title, body);
                    _logger.LogInformation($"Created expiration notification for user {userId}: {ingredient.Name}");
                }
            }
        }
    }
}