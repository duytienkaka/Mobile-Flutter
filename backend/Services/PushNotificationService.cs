using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using System.Text;

namespace Backend.Services;

public class PushNotificationService
{
    private static readonly object InitLock = new();
    private static bool _initialized;
    private readonly string _credentialsPath;
    private readonly string _credentialsJson;

    public PushNotificationService(IConfiguration configuration, IWebHostEnvironment environment)
    {
        var processEnvPath = Environment.GetEnvironmentVariable("FIREBASE_CREDENTIALS_PATH", EnvironmentVariableTarget.Process);
        var userEnvPath = Environment.GetEnvironmentVariable("FIREBASE_CREDENTIALS_PATH", EnvironmentVariableTarget.User);
        var machineEnvPath = Environment.GetEnvironmentVariable("FIREBASE_CREDENTIALS_PATH", EnvironmentVariableTarget.Machine);
        var processGooglePath = Environment.GetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", EnvironmentVariableTarget.Process);
        var userGooglePath = Environment.GetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", EnvironmentVariableTarget.User);
        var machineGooglePath = Environment.GetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", EnvironmentVariableTarget.Machine);

        var configuredPath =
            processEnvPath
            ?? userEnvPath
            ?? machineEnvPath
            ?? processGooglePath
            ?? userGooglePath
            ?? machineGooglePath
            ?? configuration["Firebase:CredentialsPath"];

        var configuredJson =
            Environment.GetEnvironmentVariable("FIREBASE_CREDENTIALS_JSON", EnvironmentVariableTarget.Process)
            ?? Environment.GetEnvironmentVariable("FIREBASE_CREDENTIALS_JSON", EnvironmentVariableTarget.User)
            ?? Environment.GetEnvironmentVariable("FIREBASE_CREDENTIALS_JSON", EnvironmentVariableTarget.Machine)
            ?? configuration["Firebase:CredentialsJson"];

        if (!string.IsNullOrWhiteSpace(configuredPath) && !Path.IsPathRooted(configuredPath))
        {
            configuredPath = Path.Combine(environment.ContentRootPath, configuredPath);
        }

        _credentialsPath = configuredPath ?? string.Empty;
        _credentialsJson = configuredJson ?? string.Empty;
    }

    private void EnsureInitialized()
    {
        if (_initialized) return;

        lock (InitLock)
        {
            if (_initialized) return;

            var hasPath = !string.IsNullOrWhiteSpace(_credentialsPath);
            var hasJson = !string.IsNullOrWhiteSpace(_credentialsJson);

            if (!hasPath && !hasJson)
            {
                throw new InvalidOperationException(
                    "Firebase credentials are missing. Set FIREBASE_CREDENTIALS_PATH/GOOGLE_APPLICATION_CREDENTIALS, FIREBASE_CREDENTIALS_JSON, or Firebase:CredentialsPath/Firebase:CredentialsJson in appsettings.");
            }

            if (hasPath && !File.Exists(_credentialsPath))
            {
                throw new FileNotFoundException(
                    "Firebase service account JSON file was not found.",
                    _credentialsPath);
            }

            if (FirebaseApp.DefaultInstance == null)
            {
                using Stream credentialsStream = hasPath
                    ? File.OpenRead(_credentialsPath)
                    : new MemoryStream(Encoding.UTF8.GetBytes(_credentialsJson));

                FirebaseApp.Create(new AppOptions
                {
                    Credential = GoogleCredential.FromStream(credentialsStream)
                });
            }

            _initialized = true;
        }
    }

    public async Task<string> SendToTokenAsync(
        string token,
        string title,
        string body,
        Dictionary<string, string>? data = null)
    {
        EnsureInitialized();

        var message = new Message
        {
            Token = token,
            Notification = new Notification
            {
                Title = title,
                Body = body
            },
            Data = data ?? new Dictionary<string, string>()
        };

        return await FirebaseMessaging.DefaultInstance.SendAsync(message);
    }
}
