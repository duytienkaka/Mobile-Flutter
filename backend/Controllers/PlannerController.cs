using Backend.Data;
using Backend.DTOs;
using Backend.Models;
using Backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace Backend.Controllers;

[ApiController]
[Route("planner")]
[Authorize]
public class PlannerController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly NotificationService _notificationService;
    private readonly WeeklyMealPlanService _weeklyMealPlanService;

    public PlannerController(
        AppDbContext db,
        NotificationService notificationService,
        WeeklyMealPlanService weeklyMealPlanService)
    {
        _db = db;
        _notificationService = notificationService;
        _weeklyMealPlanService = weeklyMealPlanService;
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
