using Backend.Data;
using Backend.DTOs;
using Backend.Models;
using Backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Globalization;
using System.Text;

namespace Backend.Controllers;

[ApiController]
[Route("planner")]
[Authorize]
public class PlannerController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly NotificationService _notificationService;
    private readonly WeeklyMealPlanService _weeklyMealPlanService;
    private readonly GeminiService _geminiService;

    public PlannerController(
        AppDbContext db,
        NotificationService notificationService,
        WeeklyMealPlanService weeklyMealPlanService,
        GeminiService geminiService)
    {
        _db = db;
        _notificationService = notificationService;
        _weeklyMealPlanService = weeklyMealPlanService;
        _geminiService = geminiService;
    }

    [HttpPost("weekly/ensure")]
    public async Task<ActionResult<WeeklyPlanEnsureResponse>> EnsureWeeklyPlan(
        [FromBody] WeeklyPlanEnsureRequest? request,
        CancellationToken ct)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var result = await _weeklyMealPlanService.EnsureCurrentWeekAsync(
            userId.Value,
            request ?? new WeeklyPlanEnsureRequest(),
            ct);

        return Ok(result);
    }

    [HttpGet]
    public async Task<ActionResult<List<MealPlanResponse>>> GetPlans([FromQuery] DateTime? from, [FromQuery] DateTime? to)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var query = _db.MealPlans.AsNoTracking().Where(x => x.UserId == userId);

        if (from.HasValue)
        {
            var start = DateTime.SpecifyKind(from.Value.Date, DateTimeKind.Utc);
            query = query.Where(x => x.Date >= start);
        }

        if (to.HasValue)
        {
            var end = DateTime.SpecifyKind(
                to.Value.Date.AddDays(1).AddTicks(-1),
                DateTimeKind.Utc
            );
            query = query.Where(x => x.Date <= end);
        }

        var data = await query
            .OrderBy(x => x.Date)
            .ToListAsync();

        return data.Select(Map).ToList();
    }

    [HttpGet("weekly/ingredients")]
    public async Task<ActionResult<WeeklyPlannerIngredientsResponse>> GetWeeklyIngredients(
        [FromQuery] DateTime? weekStart,
        CancellationToken ct)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var todayUtc = DateTime.UtcNow.Date;
        var start = StartOfWeek(DateTime.SpecifyKind((weekStart ?? todayUtc).Date, DateTimeKind.Utc));
        var endExclusive = start.AddDays(7);

        var plans = await _db.MealPlans
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .Where(x => x.Date >= start && x.Date < endExclusive)
            .Where(x => x.MealType == "breakfast" || x.MealType == "lunch" || x.MealType == "dinner")
            .OrderBy(x => x.Date)
            .ThenBy(x => x.MealType)
            .ToListAsync(ct);

        var response = new WeeklyPlannerIngredientsResponse
        {
            WeekStart = start,
            WeekEnd = endExclusive.AddDays(-1),
            Days = Enumerable.Range(0, 7)
                .Select(offset => new DailyPlannerIngredientsResponse
                {
                    Date = start.AddDays(offset),
                    Ingredients = new List<PlannerIngredientAggregateDto>()
                })
                .ToList()
        };

        if (plans.Count == 0)
        {
            return Ok(response);
        }

        var pantrySnapshot = await _db.Ingredients
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .Where(x => x.Quantity > 0)
            .Where(x => x.ExpiredAt == null || x.ExpiredAt >= todayUtc)
            .Select(x => new GeminiIngredient
            {
                Name = x.Name,
                Quantity = x.Quantity,
                Unit = x.Unit
            })
            .ToListAsync(ct);

        var recipeNames = plans
            .Select(x => x.RecipeName.Trim())
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (recipeNames.Count == 0)
        {
            return Ok(response);
        }

        List<GeminiRecipe> recipeDetails;
        try
        {
            recipeDetails = await _geminiService.GenerateRecipesByNamesAsync(recipeNames, pantrySnapshot, ct);
        }
        catch
        {
            recipeDetails = new List<GeminiRecipe>();
        }

        var recipeByName = recipeDetails
            .Where(x => !string.IsNullOrWhiteSpace(x.Name))
            .GroupBy(x => NormalizeName(x.Name))
            .ToDictionary(g => g.Key, g => g.First(), StringComparer.OrdinalIgnoreCase);

        var dayMap = response.Days.ToDictionary(
            x => x.Date.Date,
            x => new Dictionary<string, PlannerIngredientAggregateDto>(StringComparer.OrdinalIgnoreCase));

        foreach (var plan in plans)
        {
            if (!recipeByName.TryGetValue(NormalizeName(plan.RecipeName), out var recipe))
            {
                continue;
            }

            if (!dayMap.TryGetValue(plan.Date.Date, out var dayIngredients))
            {
                continue;
            }

            var servings = plan.Servings <= 0 ? 1 : plan.Servings;
            foreach (var ing in recipe.Ingredients)
            {
                var name = (ing.Name ?? string.Empty).Trim();
                if (string.IsNullOrWhiteSpace(name)) continue;

                var unit = (ing.Unit ?? string.Empty).Trim();
                var baseQuantity = ing.Quantity <= 0 ? 1 : ing.Quantity;
                var quantity = baseQuantity * servings;
                var key = $"{NormalizeName(name)}|{unit.ToLowerInvariant()}";

                if (dayIngredients.TryGetValue(key, out var existing))
                {
                    existing.Quantity += quantity;
                }
                else
                {
                    dayIngredients[key] = new PlannerIngredientAggregateDto
                    {
                        Name = name,
                        Quantity = quantity,
                        Unit = unit
                    };
                }
            }
        }

        foreach (var day in response.Days)
        {
            if (!dayMap.TryGetValue(day.Date.Date, out var map)) continue;
            day.Ingredients = map.Values
                .OrderBy(x => x.Name)
                .ToList();
        }

        return Ok(response);
    }

    [HttpPost]
    public async Task<ActionResult<MealPlanResponse>> CreatePlan(MealPlanCreateRequest request)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var entity = new MealPlan
        {
            UserId = userId.Value,
            Date = DateTime.SpecifyKind(request.Date.Date, DateTimeKind.Utc),
            MealType = request.MealType,
            RecipeName = request.RecipeName,
            Servings = request.Servings <= 0 ? 1 : request.Servings,
            Note = request.Note
        };

        _db.MealPlans.Add(entity);
        await _db.SaveChangesAsync();

        // Create notification for new meal plan
        await _notificationService.CreateNotificationAsync(
            userId.Value,
            "Kế hoạch bữa ăn mới",
            $"Đã thêm {entity.RecipeName} cho bữa {entity.MealType} vào ngày {entity.Date:dd/MM/yyyy}"
        );

        return CreatedAtAction(nameof(GetPlanById), new { id = entity.Id }, Map(entity));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<MealPlanResponse>> GetPlanById(Guid id)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var entity = await _db.MealPlans.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId);

        if (entity == null) return NotFound();

        return Map(entity);
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<MealPlanResponse>> UpdatePlan(Guid id, MealPlanUpdateRequest request)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var entity = await _db.MealPlans.FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId);
        if (entity == null) return NotFound();

        entity.Date = DateTime.SpecifyKind(request.Date.Date, DateTimeKind.Utc);
        entity.MealType = request.MealType;
        entity.RecipeName = request.RecipeName;
        entity.Servings = request.Servings <= 0 ? 1 : request.Servings;
        var incomingNote = request.Note;
        var wasAuto = WeeklyMealPlanService.IsAutoWeeklyNote(entity.Note);
        if (wasAuto)
        {
            // User has edited this auto-generated slot, treat it as user-managed from now on.
            entity.Note = string.IsNullOrWhiteSpace(incomingNote) ? null : incomingNote;
        }
        else
        {
            entity.Note = incomingNote;
        }

        await _db.SaveChangesAsync();

        return Map(entity);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeletePlan(Guid id)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var entity = await _db.MealPlans.FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId);
        if (entity == null) return NotFound();

        _db.MealPlans.Remove(entity);
        await _db.SaveChangesAsync();

        return NoContent();
    }

    private Guid? GetUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(JwtRegisteredClaimNames.Sub);
        if (Guid.TryParse(sub, out var userId)) return userId;
        return null;
    }

    private static DateTime StartOfWeek(DateTime date)
    {
        var diff = (int)date.DayOfWeek - (int)DayOfWeek.Monday;
        if (diff < 0) diff += 7;
        return date.AddDays(-diff).Date;
    }

    private static string NormalizeName(string? input)
    {
        var text = (input ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(text)) return string.Empty;

        var normalized = text.Normalize(NormalizationForm.FormD);
        var builder = new StringBuilder(normalized.Length);
        foreach (var c in normalized)
        {
            if (CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark)
            {
                builder.Append(c);
            }
        }

        return builder
            .ToString()
            .Replace('đ', 'd')
            .Replace('Đ', 'D')
            .ToLowerInvariant();
    }

    private static MealPlanResponse Map(MealPlan entity) => new MealPlanResponse
    {
        Id = entity.Id,
        Date = entity.Date,
        MealType = entity.MealType,
        RecipeName = entity.RecipeName,
        Servings = entity.Servings,
        IsAutoGenerated = WeeklyMealPlanService.IsAutoWeeklyNote(entity.Note),
        Note = WeeklyMealPlanService.IsAutoWeeklyNote(entity.Note)
            ? null
            : entity.Note
    };
}
