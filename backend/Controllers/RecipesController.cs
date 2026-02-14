using Backend.Data;
using Backend.DTOs;
using Backend.Models;
using Backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace Backend.Controllers;

[ApiController]
[Route("recipes")]
[Authorize]
public class RecipesController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly RecipeSuggestionService _service;
    private readonly GeminiService _gemini;

    public RecipesController(
        AppDbContext db,
        RecipeSuggestionService service,
        GeminiService gemini)
    {
        _db = db;
        _service = service;
        _gemini = gemini;
    }

    [HttpGet("today")]
    public async Task<ActionResult<RecipeSuggestionsResponse>> GetToday(
        [FromQuery] bool refresh,
        [FromQuery] string? tab,
        CancellationToken ct)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        try
        {
            var response = await _service.GetTodaySuggestions(userId.Value, refresh, tab, ct);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("today/stream")]
    public async Task<IActionResult> GetTodayStream(
        [FromQuery] bool refresh,
        [FromQuery] string? tab,
        CancellationToken ct)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        try
        {
            var response = await _service.GetTodaySuggestions(userId.Value, refresh, tab, ct);

            Response.Headers.CacheControl = "no-cache";
            Response.ContentType = "application/x-ndjson";

            var jsonOptions = new System.Text.Json.JsonSerializerOptions
            {
                PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
            };

            if (response.FullRecipes.Count > 0)
            {
                await WriteStreamItems("full", response.FullRecipes, jsonOptions, ct);
            }
            if (response.NearRecipes.Count > 0)
            {
                await WriteStreamItems("near", response.NearRecipes, jsonOptions, ct);
            }

            var done = System.Text.Json.JsonSerializer.Serialize(
                new { type = "done" },
                jsonOptions
            );
            await Response.WriteAsync(done + "\n", ct);
            await Response.Body.FlushAsync(ct);

            return new EmptyResult();
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("cook")]
    public async Task<IActionResult> Cook(RecipeCookRequest request, CancellationToken ct)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var name = (request.RecipeName ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(name))
        {
            return BadRequest(new { message = "Tên món ăn không được để trống." });
        }

        var entity = new CookingHistory
        {
            UserId = userId.Value,
            RecipeName = name,
            RecipeSource = string.IsNullOrWhiteSpace(request.RecipeSource)
                ? "AI"
                : request.RecipeSource.Trim(),
            CookedAt = DateTime.UtcNow
        };

        _db.CookingHistories.Add(entity);
        await _db.SaveChangesAsync(ct);

        return Ok();
    }

    [HttpPost("instructions")]
    public async Task<ActionResult<RecipeInstructionsResponse>> Instructions(
        RecipeInstructionsRequest request,
        CancellationToken ct)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var name = (request.RecipeName ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(name))
        {
            return BadRequest(new { message = "Tên món ăn không được để trống." });
        }

        var ingredients = request.Ingredients
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Select(x => x.Trim())
            .ToList();

        try
        {
            var payload = await _gemini.GenerateInstructionDetailsAsync(
                name,
                ingredients,
                request.StepCount,
                ct
            );

            return Ok(new RecipeInstructionsResponse
            {
                SummarySteps = payload.SummarySteps,
                DetailedSteps = payload.DetailedSteps
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    private Guid? GetUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(JwtRegisteredClaimNames.Sub);
        if (Guid.TryParse(sub, out var userId)) return userId;
        return null;
    }

    private async Task WriteStreamItems(
        string type,
        List<RecipeSuggestionDto> items,
        System.Text.Json.JsonSerializerOptions jsonOptions,
        CancellationToken ct)
    {
        foreach (var item in items)
        {
            var payload = System.Text.Json.JsonSerializer.Serialize(
                new { type, item },
                jsonOptions
            );
            await Response.WriteAsync(payload + "\n", ct);
            await Response.Body.FlushAsync(ct);
        }
    }
}
