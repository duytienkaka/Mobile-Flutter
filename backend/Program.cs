using Backend.Auth.Services;
using Backend.Data;
using Backend.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.StaticFiles;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Npgsql;
using System.Text;

public partial class Program
{
    private static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        var port = Environment.GetEnvironmentVariable("PORT");
        if (!string.IsNullOrWhiteSpace(port))
        {
            builder.WebHost.UseUrls($"http://0.0.0.0:{port}");
        }
        else
        {
            builder.WebHost.UseUrls("http://0.0.0.0:5075", "http://localhost:5075");
        }

        builder.Services.AddControllers();

        var rawConnectionString =
            builder.Configuration.GetConnectionString("DefaultConnection")
            ?? Environment.GetEnvironmentVariable("DATABASE_URL");
        var normalizedConnectionString = NormalizePostgresConnectionString(rawConnectionString);

        builder.Services.AddDbContext<AppDbContext>(options =>
        {
            options.UseNpgsql(normalizedConnectionString);
        });

        builder.Services.AddScoped<AuthService>();
        builder.Services.AddScoped<EmailSenderService>();
        builder.Services.AddScoped<Backend.Auth.Services.OtpService>();
        builder.Services.AddScoped<Backend.Auth.Services.JwtService>();
        builder.Services.AddHttpClient<GeminiService>();
        builder.Services.AddScoped<RecipeSuggestionService>();
        builder.Services.AddScoped<WeeklyMealPlanService>();
        builder.Services.AddScoped<HomeAiService>();
        builder.Services.AddScoped<NotificationService>();
        builder.Services.AddSingleton<PushNotificationService>();
        builder.Services.AddHostedService<ExpiredIngredientsCheckerService>();

        var allowedOrigins = builder.Configuration
            .GetSection("Cors:AllowedOrigins")
            .Get<string[]>()
            ?.Where(origin => !string.IsNullOrWhiteSpace(origin))
            .ToArray();

        // In production, use explicit allowed origins from config.
        // In development, allow any origin for quick local iteration.
        builder.Services.AddCors(options =>
        {
            options.AddPolicy("AppCors", policy =>
            {
                if (allowedOrigins is { Length: > 0 })
                {
                    policy
                        .WithOrigins(allowedOrigins)
                        .AllowAnyHeader()
                        .AllowAnyMethod();
                }
                else if (builder.Environment.IsDevelopment())
                {
                    policy
                        .AllowAnyOrigin()
                        .AllowAnyHeader()
                        .AllowAnyMethod();
                }
            });
        });

        builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    ValidIssuer = builder.Configuration["Jwt:Issuer"],
                    ValidAudience = builder.Configuration["Jwt:Audience"],
                    IssuerSigningKey = new SymmetricSecurityKey(
                        Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!)
                    )
                };
            });

        builder.Services.AddAuthorization();


        var app = builder.Build();

        // CORS should run before auth so preflight passes
        app.UseCors("AppCors");

        app.UseDefaultFiles();
        var contentTypeProvider = new FileExtensionContentTypeProvider();
        contentTypeProvider.Mappings[".apk"] = "application/vnd.android.package-archive";
        app.UseStaticFiles(new StaticFileOptions
        {
            ContentTypeProvider = contentTypeProvider
        });

        app.UseAuthentication();
        app.UseAuthorization();

        app.MapControllers();

        // Seed test user and ingredients
        using (var scope = app.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Database.Migrate();

            // Ensure Notifications table exists (guarded raw SQL) to avoid startup errors
            var ensureNotificationsSql = @"CREATE TABLE IF NOT EXISTS ""Notifications"" (
    ""Id"" uuid NOT NULL,
    ""UserId"" uuid NOT NULL,
    ""Title"" character varying(100) NOT NULL,
    ""Body"" character varying(500) NOT NULL,
    ""IsRead"" boolean NOT NULL DEFAULT false,
    ""CreatedAt"" timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT ""PK_Notifications"" PRIMARY KEY (""Id""),
    CONSTRAINT ""FK_Notifications_Users_UserId"" FOREIGN KEY (""UserId"") REFERENCES ""Users"" (""Id"") ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS ""IX_Notifications_UserId"" ON ""Notifications"" (""UserId"");";

            db.Database.ExecuteSqlRaw(ensureNotificationsSql);

            var ensureUserPushColumnsSql = @"ALTER TABLE ""Users"" ADD COLUMN IF NOT EXISTS ""FcmToken"" character varying(512);
ALTER TABLE ""Users"" ADD COLUMN IF NOT EXISTS ""TimeZoneId"" character varying(100);
ALTER TABLE ""Users"" ADD COLUMN IF NOT EXISTS ""UtcOffsetMinutes"" integer;";
            db.Database.ExecuteSqlRaw(ensureUserPushColumnsSql);

            app.Run();
        }
    }

    private static string NormalizePostgresConnectionString(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            throw new InvalidOperationException(
                "Database connection string is missing. Set ConnectionStrings__DefaultConnection or DATABASE_URL.");
        }

        // Render and many PaaS providers expose DB URL in URI format:
        // postgres://user:pass@host:port/database
        if (raw.StartsWith("postgres://", StringComparison.OrdinalIgnoreCase)
            || raw.StartsWith("postgresql://", StringComparison.OrdinalIgnoreCase))
        {
            var uri = new Uri(raw);
            var userInfo = uri.UserInfo.Split(':', 2);

            var builder = new NpgsqlConnectionStringBuilder
            {
                Host = uri.Host,
                Port = uri.Port > 0 ? uri.Port : 5432,
                Database = uri.AbsolutePath.Trim('/'),
                Username = Uri.UnescapeDataString(userInfo[0]),
                Password = userInfo.Length > 1 ? Uri.UnescapeDataString(userInfo[1]) : string.Empty,
                SslMode = SslMode.Require,
                TrustServerCertificate = true
            };

            return builder.ConnectionString;
        }

        return raw;
    }
}