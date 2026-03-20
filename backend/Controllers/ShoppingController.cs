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
[Route("shopping")]
[Authorize]
public class ShoppingController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly NotificationService _notificationService;

    public ShoppingController(AppDbContext db, NotificationService notificationService)
    {
        _db = db;
        _notificationService = notificationService;
    }

    [HttpGet]
    public async Task<ActionResult<ShoppingListResponse>> GetCurrentList()
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var list = await GetOrCreateList(userId.Value);
        return MapList(list);
    }

    [HttpGet("lists")]
    public async Task<ActionResult<List<ShoppingListSummaryResponse>>> GetLists()
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var lists = await _db.ShoppingLists
            .Where(l => l.UserId == userId)
            .OrderByDescending(l => l.PlanDate)
            .ThenByDescending(l => l.CreatedAt)
            .Select(l => new ShoppingListSummaryResponse
            {
                Id = l.Id,
                Name = l.Name,
                PlanDate = l.PlanDate,
                IsCompleted = l.IsCompleted,
                ItemCount = l.Items.Count,
                CompletedCount = l.Items.Count(i => i.IsChecked)
            })
            .ToListAsync();

        return lists;
    }

    [HttpGet("lists/{id:guid}")]
    public async Task<ActionResult<ShoppingListResponse>> GetList(Guid id)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var list = await _db.ShoppingLists
            .Include(l => l.Items)
            .FirstOrDefaultAsync(l => l.Id == id && l.UserId == userId);

        if (list == null) return NotFound();

        return MapList(list);
    }

    [HttpPost("lists")]
    public async Task<ActionResult<ShoppingListSummaryResponse>> CreateList(ShoppingListCreateRequest request)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var name = (request.Name ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(name))
        {
            return BadRequest(new { message = "Tên danh sách không được để trống." });
        }

        var planDate = request.PlanDate == default
            ? DateTime.UtcNow.Date
            : request.PlanDate;

        var list = new ShoppingList
        {
            UserId = userId.Value,
            Name = name,
            PlanDate = planDate,
            IsCompleted = false
        };

        _db.ShoppingLists.Add(list);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetList), new { id = list.Id }, new ShoppingListSummaryResponse
        {
            Id = list.Id,
            Name = list.Name,
            PlanDate = list.PlanDate,
            IsCompleted = list.IsCompleted,
            ItemCount = 0,
            CompletedCount = 0
        });
    }

    [HttpPost("lists/{id:guid}/items")]
    public async Task<ActionResult<ShoppingItemResponse>> CreateItemInList(Guid id, ShoppingItemCreateRequest request)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var name = (request.Name ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(name))
        {
            return BadRequest(new { message = "Tên món không được để trống." });
        }

        var list = await _db.ShoppingLists
            .FirstOrDefaultAsync(l => l.Id == id && l.UserId == userId);

        if (list == null) return NotFound();

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

        // Create notification for new shopping item
        await _notificationService.CreateNotificationAsync(
            userId.Value,
            "Món mới trong danh sách",
            $"Đã thêm {item.Name} ({item.Quantity} {item.Unit}) vào danh sách {list.Name}"
        );

        return CreatedAtAction(nameof(GetList), new { id = list.Id }, MapItem(item));
    }

    [HttpPost("lists/{id:guid}/items/batch")]
    public async Task<ActionResult<ShoppingItemsBatchCreateResponse>> CreateItemsInListBatch(
        Guid id,
        ShoppingItemsBatchCreateRequest request)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var list = await _db.ShoppingLists
            .FirstOrDefaultAsync(l => l.Id == id && l.UserId == userId);

        if (list == null) return NotFound();

        var incoming = request.Items ?? new List<ShoppingItemCreateRequest>();
        if (incoming.Count == 0)
        {
            return Ok(new ShoppingItemsBatchCreateResponse { CreatedCount = 0 });
        }

        var aggregated = incoming
            .Where(x => !string.IsNullOrWhiteSpace(x.Name))
            .GroupBy(
                x => $"{x.Name.Trim().ToLowerInvariant()}|{(x.Unit ?? string.Empty).Trim().ToLowerInvariant()}",
                StringComparer.OrdinalIgnoreCase)
            .Select(group =>
            {
                var first = group.First();
                var quantity = group.Sum(item => item.Quantity <= 0 ? 1 : item.Quantity);
                return new ShoppingItem
                {
                    ShoppingListId = list.Id,
                    Name = first.Name.Trim(),
                    Quantity = quantity,
                    Unit = (first.Unit ?? string.Empty).Trim(),
                    IsChecked = false
                };
            })
            .ToList();

        if (aggregated.Count == 0)
        {
            return Ok(new ShoppingItemsBatchCreateResponse { CreatedCount = 0 });
        }

        _db.ShoppingItems.AddRange(aggregated);
        await _db.SaveChangesAsync();

        return Ok(new ShoppingItemsBatchCreateResponse
        {
            CreatedCount = aggregated.Count
        });
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

        // Create notification for new shopping item
        await _notificationService.CreateNotificationAsync(
            userId.Value,
            "Món mới trong danh sách mua sắm",
            $"Đã thêm {item.Name} ({item.Quantity} {item.Unit}) vào danh sách hiện tại"
        );

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

    [HttpDelete("lists/{id:guid}")]
    public async Task<IActionResult> DeleteList(Guid id)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var list = await _db.ShoppingLists
            .Include(l => l.Items)
            .FirstOrDefaultAsync(l => l.Id == id && l.UserId == userId);

        if (list == null) return NotFound();

        if (list.Items.Count > 0)
        {
            _db.ShoppingItems.RemoveRange(list.Items);
        }

        _db.ShoppingLists.Remove(list);
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
            Name = "Danh sách mặc định",
            PlanDate = DateTime.UtcNow.Date,
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
            Name = list.Name,
            PlanDate = list.PlanDate,
            IsCompleted = list.IsCompleted,
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