using Backend.Data;
using Backend.DTOs;
using Backend.Models;
using Backend.Services;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Controllers
{
    [ApiController]
    [Route("auth")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly JwtService _jwt;
        private readonly OtpService _otp;

        public AuthController(
            AppDbContext context,
            JwtService jwt,
            OtpService otp)
        {
            _context = context;
            _jwt = jwt;
            _otp = otp;
        }

        // ================= EMAIL LOGIN =================
        [HttpPost("login-email")]
        public IActionResult LoginEmail(LoginEmailRequest request)
        {
            var user = _context.Users
                .FirstOrDefault(x => x.Email == request.Email);

            if (user == null)
                return BadRequest("Email không tồn tại");

            if (!PasswordService.Verify(request.Password, user.PasswordHash!))
                return BadRequest("Sai mật khẩu");

            if (!user.IsEmailVerified)
                return BadRequest("Email chưa được xác thực");

            var token = _jwt.GenerateToken(user);

            return Ok(new
            {
                token,
                user.Id,
                user.Email
            });
        }

        // ================= SEND OTP =================
        [HttpPost("send-otp")]
        public IActionResult SendOtp(SendOtpRequest request)
        {
            Console.WriteLine(">>> SEND OTP API CALLED <<<");
            Console.WriteLine("Phone: " + request.PhoneNumber);

            _otp.GenerateOtp(request.PhoneNumber);

            return Ok("OTP đã được gửi");
        }

        // ================= VERIFY OTP =================
        [HttpPost("verify-otp")]
        public IActionResult VerifyOtp(VerifyOtpRequest request)
        {
            var valid = _otp.VerifyOtp(
                request.PhoneNumber,
                request.Code
            );

            if (!valid)
                return BadRequest("OTP không hợp lệ hoặc đã hết hạn");

            var user = _context.Users
                .FirstOrDefault(x => x.PhoneNumber == request.PhoneNumber);

            if (user == null)
            {
                user = new User
                {
                    PhoneNumber = request.PhoneNumber
                };
                _context.Users.Add(user);
                _context.SaveChanges();
            }

            var token = _jwt.GenerateToken(user);

            return Ok(new
            {
                token,
                user.Id,
                user.PhoneNumber
            });
        }
    }
}
