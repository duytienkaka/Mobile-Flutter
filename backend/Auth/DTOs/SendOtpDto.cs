namespace Backend.Auth.DTOs;

public class SendOtpDto
{
    public string PhoneNumber { get; set; } = "";
    public bool IsRegister { get; set; } = true;
}
