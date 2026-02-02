using Backend.Data;
using Backend.Models;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using System.Text;

namespace Backend.Auth.Services;

public class AuthService
{
    private readonly AppDbContext _db;

    public AuthService(AppDbContext db)
    {
        _db = db;
    }

    // ===== REGISTER EMAIL =====
    public async Task<User> RegisterByEmail(string fullName, string email, string password)
    {
        if (await _db.Users.AnyAsync(x => x.Email == email))
            throw new Exception("Email already exists");

        var user = new User
        {
            FullName = fullName,
            Email = email,
            PasswordHash = HashPassword(password),
            IsEmailVerified = true
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        return user;
    }

    // ===== LOGIN EMAIL =====
    public async Task<User> LoginByEmail(string email, string password)
    {
        var user = await _db.Users.FirstOrDefaultAsync(x => x.Email == email);
        if (user == null)
            throw new Exception("Invalid email or password");

        if (user.PasswordHash != HashPassword(password))
            throw new Exception("Invalid email or password");

        return user;
    }

    // ===== REGISTER PHONE =====
    public async Task<User> RegisterByPhone(string fullName, string phone, string otpCode)
    {
        var otp = _db.OtpCodes
            .Where(x =>
                x.PhoneNumber == phone &&
                x.Code == otpCode &&
                x.Purpose == "Register" &&
                !x.IsUsed &&
                x.ExpiredAt > DateTime.UtcNow)
            .OrderByDescending(x => x.CreatedAt)
            .FirstOrDefault();

        if (otp == null)
            throw new Exception("Invalid or expired OTP");

        otp.IsUsed = true;

        if (await _db.Users.AnyAsync(x => x.PhoneNumber == phone))
            throw new Exception("Phone already registered");

        var user = new User
        {
            FullName = fullName,
            PhoneNumber = phone,
            IsPhoneVerified = true
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        return user;
    }

    // ===== LOGIN PHONE WITH OTP =====
    public async Task<User> LoginByPhone(string phone, string otpCode)
    {
        var otp = _db.OtpCodes
            .Where(x =>
                x.PhoneNumber == phone &&
                x.Code == otpCode &&
                x.Purpose == "Login" &&
                !x.IsUsed &&
                x.ExpiredAt > DateTime.UtcNow)
            .OrderByDescending(x => x.CreatedAt)
            .FirstOrDefault();

        if (otp == null)
            throw new Exception("Invalid or expired OTP");

        otp.IsUsed = true;

        var user = await _db.Users.FirstOrDefaultAsync(x => x.PhoneNumber == phone);
        if (user == null)
            throw new Exception("Phone not registered");

        await _db.SaveChangesAsync();
        return user;
    }

    private static string HashPassword(string password)
    {
        using var sha = SHA256.Create();
        var bytes = sha.ComputeHash(Encoding.UTF8.GetBytes(password));
        return Convert.ToBase64String(bytes);
    }
}
