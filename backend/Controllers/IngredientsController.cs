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
            Quantity = entity.Quantity,
            Unit = entity.Unit,
            ExpiredAt = entity.ExpiredAt
        };
    }
}