namespace Backend.DTOs
{
    public class VerifyOtpRequest
    {
        public string PhoneNumber { get; set; } = null!;
        public string Code { get; set; } = null!;
    }
}
