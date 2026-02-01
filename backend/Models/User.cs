using System;
using System.ComponentModel.DataAnnotations;

namespace Backend.Models
{
    public class User
    {
        public int Id { get; set; }

        [EmailAddress]
        public string? Email { get; set; }

        public string? PasswordHash { get; set; }

        public string? PhoneNumber { get; set; }

        public bool IsEmailVerified { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
