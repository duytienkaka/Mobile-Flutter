using Backend.Data;
using Backend.DTOs;
using Backend.Models;
using Backend.Services;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.IdentityModel.Tokens.Jwt;
using System.IO;
using System.Security.Claims;

namespace Backend.Controllers;

[ApiController]
[Route("users")]
[Authorize]
public class UserController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IWebHostEnvironment _env;

    public UserController(AppDbContext db, IWebHostEnvironment env)
    {
        _db = db;
        _env = env;
    }

    [HttpGet("me")]
    public async Task<ActionResult<UserProfileResponse>> GetMe()
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var user = await _db.Users.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == userId);

        if (user == null) return NotFound();

        return Map(user);
    }

    [HttpPut("me")]
    public async Task<ActionResult<UserProfileResponse>> UpdateProfile(UpdateProfileRequest request)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var name = (request.FullName ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(name))
        {
            return BadRequest(new { message = "Họ và tên không được để trống." });
        }

        var user = await _db.Users.FirstOrDefaultAsync(x => x.Id == userId);
        if (user == null) return NotFound();

        user.FullName = name;
        await _db.SaveChangesAsync();

        return Map(user);
    }

    [HttpPut("me/password")]
    public async Task<IActionResult> ChangePassword(ChangePasswordRequest request)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var current = (request.CurrentPassword ?? string.Empty).Trim();
        var next = (request.NewPassword ?? string.Empty).Trim();

        if (string.IsNullOrWhiteSpace(current) || string.IsNullOrWhiteSpace(next))
        {
            return BadRequest(new { message = "Vui lòng nhập đầy đủ thông tin." });
        }

        if (next.Length < 6)
        {
            return BadRequest(new { message = "Mật khẩu mới tối thiểu 6 ký tự." });
        }

        var user = await _db.Users.FirstOrDefaultAsync(x => x.Id == userId);
        if (user == null) return NotFound();

        if (string.IsNullOrWhiteSpace(user.PasswordHash))
        {
            return BadRequest(new { message = "Tài khoản này chưa thiết lập mật khẩu." });
        }

        if (!PasswordService.Verify(current, user.PasswordHash))
        {
            return BadRequest(new { message = "Mật khẩu hiện tại không đúng." });
        }

        user.PasswordHash = PasswordService.Hash(next);
        await _db.SaveChangesAsync();

        return Ok(new { message = "Đổi mật khẩu thành công." });
    }

    [HttpPost("me/avatar")]
    [RequestSizeLimit(5 * 1024 * 1024)]
    public async Task<ActionResult<UserProfileResponse>> UploadAvatar([FromForm] IFormFile avatar)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        if (avatar == null || avatar.Length == 0)
        {
            return BadRequest(new { message = "Không có ảnh được chọn." });
        }

        var ext = Path.GetExtension(avatar.FileName).ToLowerInvariant();
        var allowed = new HashSet<string> { ".jpg", ".jpeg", ".png", ".webp" };
        if (!allowed.Contains(ext))
        {
            return BadRequest(new { message = "Định dạng ảnh không hợp lệ." });
        }

        var user = await _db.Users.FirstOrDefaultAsync(x => x.Id == userId);
        if (user == null) return NotFound();

        var webRoot = _env.WebRootPath ?? Path.Combine(_env.ContentRootPath, "wwwroot");
        var folder = Path.Combine(webRoot, "uploads", "avatars");
        Directory.CreateDirectory(folder);

        var fileName = $"{user.Id:N}_{DateTime.UtcNow:yyyyMMddHHmmss}{ext}";
        var filePath = Path.Combine(folder, fileName);
        await using (var stream = System.IO.File.Create(filePath))
        {
            await avatar.CopyToAsync(stream);
        }

        if (!string.IsNullOrWhiteSpace(user.AvatarUrl))
        {
            var oldPath = user.AvatarUrl.Replace("/", Path.DirectorySeparatorChar.ToString()).TrimStart(Path.DirectorySeparatorChar);
            var fullOldPath = Path.Combine(webRoot, oldPath);
            if (System.IO.File.Exists(fullOldPath))
            {
                System.IO.File.Delete(fullOldPath);
            }
        }

        user.AvatarUrl = $"/uploads/avatars/{fileName}";
        await _db.SaveChangesAsync();

        return Map(user);
    }

    private Guid? GetUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(JwtRegisteredClaimNames.Sub);
        if (Guid.TryParse(sub, out var userId)) return userId;
        return null;
    }

    private static UserProfileResponse Map(User user) => new UserProfileResponse
    {
        Id = user.Id,
        FullName = user.FullName,
        Email = user.Email,
        PhoneNumber = user.PhoneNumber,
        AvatarUrl = user.AvatarUrl
    };
}
