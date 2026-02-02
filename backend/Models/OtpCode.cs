using System.ComponentModel.DataAnnotations;

namespace Backend.Models;

public class OtpCode
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required, MaxLength(20)]
    public string PhoneNumber { get; set; } = "";

    [Required, MaxLength(10)]
    public string Code { get; set; } = "";

    // Register | Login | ResetPassword
    [Required, MaxLength(20)]
    public string Purpose { get; set; } = "Register";

    public DateTime ExpiredAt { get; set; }

    public bool IsUsed { get; set; } = false;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
