namespace Backend.Auth.DTOs;

public class RegisterEmailDto
{
    public string FullName { get; set; } = "";
    public string Email { get; set; } = "";
    public string Password { get; set; } = "";
    public string OtpCode { get; set; } = "";
}
