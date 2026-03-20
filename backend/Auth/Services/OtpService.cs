using Backend.Data;
using Backend.Models;
using Microsoft.EntityFrameworkCore;

namespace Backend.Auth.Services;

public class OtpService
{
    private readonly AppDbContext _db;
    private readonly EmailSenderService _emailSender;

    public OtpService(AppDbContext db, EmailSenderService emailSender)
    {
        _db = db;
        _emailSender = emailSender;
    }

    public async Task SendOtp(string phone, bool isRegister)
    {
        // Registration: phone must NOT exist. Login: phone MUST exist.
        var userExists = await _db.Users.AnyAsync(u => u.PhoneNumber == phone);

        if (isRegister && userExists)
            throw new Exception("Số điện thoại đã được đăng ký.");

        if (!isRegister && !userExists)
            throw new Exception("Số điện thoại chưa có tài khoản. Vui lòng đăng ký.");

        var code = new Random().Next(100000, 999999).ToString();

        var otp = new OtpCode
        {
            PhoneNumber = phone,
            Code = code,
            Purpose = isRegister ? "Register" : "Login",
            ExpiredAt = DateTime.UtcNow.AddMinutes(5)
        };

        _db.OtpCodes.Add(otp);
        await _db.SaveChangesAsync();

        // DEV MODE
        Console.WriteLine($"[OTP DEV] {phone} -> {code}");
    }

    public async Task SendEmailOtp(string email, bool isRegister)
    {
        var normalizedEmail = email.Trim().ToLowerInvariant();

        var userExists = await _db.Users.AnyAsync(u => u.Email == normalizedEmail);

        if (isRegister && userExists)
            throw new Exception("Email đã được đăng ký.");

        if (!isRegister && !userExists)
            throw new Exception("Email chưa có tài khoản. Vui lòng đăng ký.");

        var code = new Random().Next(100000, 999999).ToString();

        var otp = new OtpCode
        {
            PhoneNumber = normalizedEmail,
            Code = code,
            Purpose = isRegister ? "RegisterEmail" : "LoginEmail",
            ExpiredAt = DateTime.UtcNow.AddMinutes(5)
        };

        _db.OtpCodes.Add(otp);
        await _db.SaveChangesAsync();

        await _emailSender.SendOtpEmailAsync(normalizedEmail, code);
    }
}
