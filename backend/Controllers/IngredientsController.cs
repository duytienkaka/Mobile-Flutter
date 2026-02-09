using Backend.Data;
using Backend.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace Backend.Controllers;

[ApiController]
[Route("ingredients")]
[Authorize]
public class IngredientsController : ControllerBase
{
    private readonly AppDbContext _db;

    public IngredientsController(AppDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<List<IngredientResponse>>> GetIngredients()
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var items = await _db.Ingredients
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .OrderBy(x => x.ExpiredAt)
            .ToListAsync();

        return items.Select(Map).ToList();
    }

    [HttpPost]
    public async Task<ActionResult<IngredientResponse>> CreateIngredient(
        IngredientCreateRequest dto)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();
        if (string.IsNullOrWhiteSpace(dto.Name))
            return BadRequest(new { message = "Name is required" });

        var entity = new Backend.Models.Ingredient
        {
            UserId = userId.Value,
            Name = dto.Name.Trim(),
            Category = dto.Category?.Trim() ?? "",
            Quantity = dto.Quantity,
            Unit = dto.Unit?.Trim() ?? "",
            ExpiredAt = dto.ExpiredAt == null
                ? null
                : DateTime.SpecifyKind(dto.ExpiredAt.Value, DateTimeKind.Utc)
        };

        _db.Ingredients.Add(entity);
        await _db.SaveChangesAsync();

        return Ok(Map(entity));
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<IngredientResponse>> UpdateIngredient(
        Guid id,
        IngredientUpdateRequest dto)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();
        if (string.IsNullOrWhiteSpace(dto.Name))
            return BadRequest(new { message = "Name is required" });

        var entity = await _db.Ingredients
            .FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId);
        if (entity == null) return NotFound();

        entity.Name = dto.Name.Trim();
        entity.Category = dto.Category?.Trim() ?? "";
        entity.Quantity = dto.Quantity;
        entity.Unit = dto.Unit?.Trim() ?? "";
        entity.ExpiredAt = dto.ExpiredAt == null
            ? null
            : DateTime.SpecifyKind(dto.ExpiredAt.Value, DateTimeKind.Utc);

        await _db.SaveChangesAsync();
        return Ok(Map(entity));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteIngredient(Guid id)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var entity = await _db.Ingredients
            .FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId);
        if (entity == null) return NotFound();

        _db.Ingredients.Remove(entity);
        await _db.SaveChangesAsync();
        return Ok();
    }

    private Guid? GetUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(JwtRegisteredClaimNames.Sub);
        if (Guid.TryParse(sub, out var userId)) return userId;
        return null;
    }

    private static IngredientResponse Map(Backend.Models.Ingredient entity)
    {
        return new IngredientResponse
        {
            Id = entity.Id,
            Name = entity.Name,
            Category = entity.Category,
            Quantity = entity.Quantity,
            Unit = entity.Unit,
            ExpiredAt = entity.ExpiredAt
        };
    }
}