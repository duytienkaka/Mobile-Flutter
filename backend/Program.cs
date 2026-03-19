using Backend.Auth.Services;
using Backend.Data;
using Backend.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;

public partial class Program
{
    private static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        builder.WebHost.UseUrls("http://0.0.0.0:5075", "http://localhost:5075");

        builder.Services.AddControllers();
        builder.Services.AddEndpointsApiExplorer();
        builder.Services.AddSwaggerGen();

        builder.Services.AddDbContext<AppDbContext>(options =>
        {
            options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"));
        });

        builder.Services.AddScoped<AuthService>();
        builder.Services.AddScoped<Backend.Auth.Services.OtpService>();
        builder.Services.AddScoped<Backend.Auth.Services.JwtService>();
        builder.Services.AddHttpClient<GeminiService>();
        builder.Services.AddScoped<RecipeSuggestionService>();
        builder.Services.AddScoped<WeeklyMealPlanService>();
        builder.Services.AddScoped<HomeAiService>();
        builder.Services.AddScoped<NotificationService>();
        builder.Services.AddHostedService<ExpiredIngredientsCheckerService>();

        // Allow the Flutter web app (any localhost port) to call the API during dev
        builder.Services.AddCors(options =>
        {
            options.AddPolicy("DevCors", policy =>
            {
                policy
                    .AllowAnyOrigin()
                    .AllowAnyHeader()
                    .AllowAnyMethod();
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
        app.UseCors("DevCors");

        app.UseDefaultFiles();
        app.UseStaticFiles();

        app.UseAuthentication();
        app.UseAuthorization();

        // Swagger only in Development
        if (app.Environment.IsDevelopment())
        {
            app.UseSwagger();
            app.UseSwaggerUI();
        }

        app.MapControllers();

        // Seed test user and ingredients
        using (var scope = app.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
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

            app.Run();
        }
    }
}