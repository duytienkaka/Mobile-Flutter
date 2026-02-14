using Backend.Services.History;
using Backend.DTOs.History;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using System.IdentityModel.Tokens.Jwt;

namespace Backend.Controllers.History;

[ApiController]
[Route("recipes/history")]
[Authorize]
public class HistoryController : ControllerBase
{
	private readonly HistoryService _service;

	public HistoryController(HistoryService service)
	{
		_service = service;
	}

	[HttpPost]
	public async Task<IActionResult> AddHistory([FromBody] CookingHistoryDto dto, CancellationToken ct)
	{
		var userId = GetUserId();
		if (userId == null) return Unauthorized();
		if (string.IsNullOrWhiteSpace(dto.RecipeName))
			return BadRequest(new { message = "Tên món ăn không được để trống." });

		await _service.AddHistoryAsync(userId.Value, dto.RecipeName, dto.RecipeSource ?? "AI", ct);
		return Ok();
	}

	[HttpGet("recent")]
	public async Task<ActionResult<List<CookingHistoryDto>>> GetRecentHistory([FromQuery] int days = 7, CancellationToken ct = default)
	{
		var userId = GetUserId();
		if (userId == null) return Unauthorized();
		var result = await _service.GetRecentHistoryAsync(userId.Value, days, ct);
		return Ok(result);
	}

	private Guid? GetUserId()
	{
		var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
			?? User.FindFirstValue(JwtRegisteredClaimNames.Sub);
		if (Guid.TryParse(sub, out var userId)) return userId;
		return null;
	}
}
