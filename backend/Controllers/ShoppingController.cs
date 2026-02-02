using Backend.Data;
using Backend.DTOs;
using Backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace Backend.Controllers;

[ApiController]
[Route("shopping")]
[Authorize]
public class ShoppingController : ControllerBase
{
    private readonly AppDbContext _db;

    public ShoppingController(AppDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<ShoppingListResponse>> GetCurrentList()
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var list = await GetOrCreateList(userId.Value);
        return MapList(list);
    }

    [HttpPost("items")]
    public async Task<ActionResult<ShoppingItemResponse>> CreateItem(ShoppingItemCreateRequest request)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var name = (request.Name ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(name))
        {
            return BadRequest(new { message = "Tên món không được để trống." });
        }

        var list = await GetOrCreateList(userId.Value);

        var item = new ShoppingItem
        {
            ShoppingListId = list.Id,
            Name = name,
            Quantity = request.Quantity <= 0 ? 1 : request.Quantity,
            Unit = request.Unit ?? string.Empty,
            IsChecked = false
        };

        _db.ShoppingItems.Add(item);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetCurrentList), new { id = list.Id }, MapItem(item));
    }

    [HttpPut("items/{id:guid}")]
    public async Task<ActionResult<ShoppingItemResponse>> UpdateItem(Guid id, ShoppingItemUpdateRequest request)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var item = await _db.ShoppingItems
            .Include(i => i.ShoppingList)
            .FirstOrDefaultAsync(i => i.Id == id && i.ShoppingList.UserId == userId);

        if (item == null) return NotFound();

        var name = (request.Name ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(name))
        {
            return BadRequest(new { message = "Tên món không được để trống." });
        }

        item.Name = name;
        item.Quantity = request.Quantity <= 0 ? 1 : request.Quantity;
        item.Unit = request.Unit ?? string.Empty;
        item.IsChecked = request.IsChecked;

        await _db.SaveChangesAsync();

        return MapItem(item);
    }

    [HttpDelete("items/{id:guid}")]
    public async Task<IActionResult> DeleteItem(Guid id)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var item = await _db.ShoppingItems
            .Include(i => i.ShoppingList)
            .FirstOrDefaultAsync(i => i.Id == id && i.ShoppingList.UserId == userId);

        if (item == null) return NotFound();

        _db.ShoppingItems.Remove(item);
        await _db.SaveChangesAsync();

        return NoContent();
    }

    private async Task<ShoppingList> GetOrCreateList(Guid userId)
    {
        var list = await _db.ShoppingLists
            .Include(l => l.Items)
            .FirstOrDefaultAsync(l => l.UserId == userId && !l.IsCompleted);

        if (list != null) return list;

        list = new ShoppingList
        {
            UserId = userId,
            IsCompleted = false
        };

        _db.ShoppingLists.Add(list);
        await _db.SaveChangesAsync();

        list = await _db.ShoppingLists
            .Include(l => l.Items)
            .FirstAsync(l => l.Id == list.Id);

        return list;
    }

    private Guid? GetUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(JwtRegisteredClaimNames.Sub);
        if (Guid.TryParse(sub, out var userId)) return userId;
        return null;
    }

    private static ShoppingListResponse MapList(ShoppingList list)
    {
        var items = list.Items
            .OrderBy(x => x.Name)
            .Select(MapItem)
            .ToList();

        return new ShoppingListResponse
        {
            Id = list.Id,
            Items = items
        };
    }

    private static ShoppingItemResponse MapItem(ShoppingItem item)
    {
        return new ShoppingItemResponse
        {
            Id = item.Id,
            Name = item.Name,
            Quantity = item.Quantity,
            Unit = item.Unit,
            IsChecked = item.IsChecked
        };
    }
}