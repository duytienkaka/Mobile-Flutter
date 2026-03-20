using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using System.Net.Http;
using System.Text;
using System.Text.Json;

namespace Backend.Auth.Services;

public class EmailSenderService
{
    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;

    public EmailSenderService(IConfiguration configuration, IHttpClientFactory httpClientFactory)
    {
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
    }

    public async Task SendOtpEmailAsync(string toEmail, string otpCode)
    {
        var brevoApiKey = _configuration["Brevo:ApiKey"];
        if (!string.IsNullOrWhiteSpace(brevoApiKey))
        {
            await SendViaBrevoApiAsync(toEmail, otpCode, brevoApiKey);
            return;
        }

        var host = _configuration["Smtp:Host"];
        var port = int.TryParse(_configuration["Smtp:Port"], out var parsedPort) ? parsedPort : 587;
        var username = _configuration["Smtp:Username"];
        var password = _configuration["Smtp:Password"];
        var fromEmail = _configuration["Smtp:FromEmail"];
        var fromName = _configuration["Smtp:FromName"] ?? "Fridge Manager";
        var secureSocketOptions = ParseSecureSocketOptions(_configuration["Smtp:SecureSocketOptions"]);
        var requireAuthentication = ParseBooleanOrDefault(_configuration["Smtp:RequireAuthentication"], true);

        if (string.IsNullOrWhiteSpace(host)
            || string.IsNullOrWhiteSpace(fromEmail)
            || (requireAuthentication && string.IsNullOrWhiteSpace(username))
            || (requireAuthentication && string.IsNullOrWhiteSpace(password)))
        {
            throw new InvalidOperationException(
                "SMTP is not configured. Set Smtp:Host, Smtp:Port, Smtp:Username, Smtp:Password, and Smtp:FromEmail.");
        }

        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(fromName, fromEmail));
        message.To.Add(MailboxAddress.Parse(toEmail));
        message.Subject = "Ma xac thuc dang ky Fridge Manager";

        message.Body = new TextPart("plain")
        {
            Text =
                $"Xin chao,\n\n" +
                $"Ma OTP dang ky cua ban la: {otpCode}\n" +
                "Ma co hieu luc trong 5 phut.\n\n" +
                "Neu ban khong thuc hien thao tac nay, vui long bo qua email nay."
        };

        using var smtp = new SmtpClient();
        await smtp.ConnectAsync(host, port, secureSocketOptions);
        if (requireAuthentication)
        {
            await smtp.AuthenticateAsync(username, password);
        }
        await smtp.SendAsync(message);
        await smtp.DisconnectAsync(true);
    }

    private async Task SendViaBrevoApiAsync(string toEmail, string otpCode, string apiKey)
    {
        var fromEmail = _configuration["Smtp:FromEmail"];
        var fromName = _configuration["Smtp:FromName"] ?? "Fridge Manager";

        if (string.IsNullOrWhiteSpace(fromEmail))
        {
            throw new InvalidOperationException(
                "Brevo is configured but sender is missing. Set Smtp:FromEmail (verified sender on Brevo)."
            );
        }

        var payload = new
        {
            sender = new { name = fromName, email = fromEmail },
            to = new[] { new { email = toEmail } },
            subject = "Ma xac thuc dang ky Fridge Manager",
            textContent =
                "Xin chao,\n\n" +
                $"Ma OTP dang ky cua ban la: {otpCode}\n" +
                "Ma co hieu luc trong 5 phut.\n\n" +
                "Neu ban khong thuc hien thao tac nay, vui long bo qua email nay."
        };

        var requestJson = JsonSerializer.Serialize(payload);
        using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.brevo.com/v3/smtp/email")
        {
            Content = new StringContent(requestJson, Encoding.UTF8, "application/json")
        };

        request.Headers.TryAddWithoutValidation("api-key", apiKey);

        using var client = _httpClientFactory.CreateClient();
        client.Timeout = TimeSpan.FromSeconds(20);

        using var response = await client.SendAsync(request);
        if (!response.IsSuccessStatusCode)
        {
            var responseBody = await response.Content.ReadAsStringAsync();
            throw new InvalidOperationException(
                $"Brevo API send failed ({(int)response.StatusCode}): {responseBody}"
            );
        }
    }

    private static SecureSocketOptions ParseSecureSocketOptions(string? value)
    {
        // Keep StartTls as default for production safety while allowing local SMTP testing.
        if (string.IsNullOrWhiteSpace(value))
            return SecureSocketOptions.StartTls;

        return value.Trim().ToLowerInvariant() switch
        {
            "none" => SecureSocketOptions.None,
            "ssl" or "sslonconnect" => SecureSocketOptions.SslOnConnect,
            "starttls" => SecureSocketOptions.StartTls,
            "starttlswhenavailable" => SecureSocketOptions.StartTlsWhenAvailable,
            "auto" => SecureSocketOptions.Auto,
            _ => SecureSocketOptions.StartTls
        };
    }

    private static bool ParseBooleanOrDefault(string? value, bool defaultValue)
    {
        return bool.TryParse(value, out var parsed) ? parsed : defaultValue;
    }
}
