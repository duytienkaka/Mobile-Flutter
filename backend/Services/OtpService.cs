using Backend.Data;
using Backend.Models;

namespace Backend.Services
{
    public class OtpService
    {
        private readonly AppDbContext _context;

        public OtpService(AppDbContext context)
        {
            _context = context;
        }

        public string GenerateOtp(string phone)
        {
            var code = new Random().Next(100000, 999999).ToString();

            var otp = new OtpCode
            {
                PhoneNumber = phone,
                Code = code,
                ExpiredAt = DateTime.UtcNow.AddSeconds(30)
            };

            _context.OtpCodes.Add(otp);
            _context.SaveChanges();

            Console.WriteLine($"OTP for {phone}: {code}");

            return code;
        }

        public bool VerifyOtp(string phone, string code)
        {
            var otp = _context.OtpCodes
                .Where(x =>
                    x.PhoneNumber == phone &&
                    x.Code == code &&
                    !x.IsUsed &&
                    x.ExpiredAt > DateTime.UtcNow)
                .OrderByDescending(x => x.CreatedAt)
                .FirstOrDefault();

            if (otp == null) return false;

            otp.IsUsed = true;
            _context.SaveChanges();
            return true;
        }
    }
}
