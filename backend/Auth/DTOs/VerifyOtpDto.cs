namespace Backend.Auth.DTOs;

public class VerifyOtpDto
{
    public string PhoneNumber { get; set; } = "";
    public string Code { get; set; } = "";
}
