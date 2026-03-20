namespace Backend.Auth.DTOs;

public class SendEmailOtpDto
{
    public string Email { get; set; } = "";
    public bool IsRegister { get; set; } = true;
}
