using Backend.DTOs;
using Backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace Backend.Controllers;

[ApiController]
[Route("home")]
[Authorize]
public class HomeController : ControllerBase
{
    private readonly HomeAiService _service;

    public HomeController(HomeAiService service)
    {
        _service = service;
    }

    [HttpGet("ai")]
    public async Task<ActionResult<HomeAiResponse>> GetHomeAi(
        [FromQuery] bool refresh,
        CancellationToken ct)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        try
        {
            var response = await _service.GetHomeAiAsync(userId.Value, refresh, ct);
            return Ok(response);
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
}
