public class User
{
    public Guid Id { get; set; }

    public string FullName { get; set; } = "";

    public string? Email { get; set; }
    public string? PhoneNumber { get; set; }

    public string? PasswordHash { get; set; }

    public bool IsEmailVerified { get; set; }
    public bool IsPhoneVerified { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
