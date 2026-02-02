using Backend.Auth.DTOs;
using Backend.Auth.Services;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Controllers;

[ApiController]
[Route("auth")]
public class AuthController : ControllerBase
{
    private readonly AuthService _auth;
    private readonly OtpService _otp;
    private readonly JwtService _jwt;

    public AuthController(AuthService auth, OtpService otp, JwtService jwt)
    {
        _auth = auth;
        _otp = otp;
        _jwt = jwt;
    }

    [HttpPost("register-email")]
    public async Task<IActionResult> RegisterEmail(RegisterEmailDto dto)
    {
        try
        {
            var user = await _auth.RegisterByEmail(dto.FullName, dto.Email, dto.Password);
            var token = _jwt.GenerateToken(user);
            return Ok(new { token });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("login-email")]
    public async Task<IActionResult> LoginEmail(LoginEmailDto dto)
    {
        try
        {
            var user = await _auth.LoginByEmail(dto.Email, dto.Password);
            var token = _jwt.GenerateToken(user);
            return Ok(new { token });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("send-otp")]
    public async Task<IActionResult> SendOtp(SendOtpDto dto)
    {
        try
        {
            await _otp.SendOtp(dto.PhoneNumber, dto.IsRegister);
            return Ok("OTP sent");
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("register-phone")]
    public async Task<IActionResult> RegisterPhone(RegisterPhoneDto dto)
    {
        try
        {
            var user = await _auth.RegisterByPhone(
                dto.FullName,
                dto.PhoneNumber,
                dto.OtpCode
            );

            var token = _jwt.GenerateToken(user);
            return Ok(new { token });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("login-phone")]
    public async Task<IActionResult> LoginPhone(LoginPhoneDto dto)
    {
        try
        {
            var user = await _auth.LoginByPhone(dto.PhoneNumber, dto.OtpCode);
            var token = _jwt.GenerateToken(user);
            return Ok(new { token });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
