using System;

namespace Backend.Models
{
    public class OtpCode
    {
        public int Id { get; set; }

        public string PhoneNumber { get; set; } = null!;

        public string Code { get; set; } = null!;

        public DateTime ExpiredAt { get; set; }

        public bool IsUsed { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
