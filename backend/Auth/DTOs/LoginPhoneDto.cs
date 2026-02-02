namespace Backend.Auth.DTOs;

public class LoginPhoneDto
{
    public string PhoneNumber { get; set; } = "";
    public string OtpCode { get; set; } = "";
}
