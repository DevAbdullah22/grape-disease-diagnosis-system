using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using DOGD_API.Application.BackgroundJobs;
using DOGD_API.Application.Services.AI;
using DOGD_API.Application.Services.Auth;
using DOGD_API.Application.Services.Diagnosis;
using DOGD_API.Application.Services.Disease;
using DOGD_API.Application.Services.Library;
using DOGD_API.Application.Services.Logs_Services;
using DOGD_API.Application.Services.Notifications;
using DOGD_API.Application.Services.Notifications_Service;
using DOGD_API.Application.Services.Treatment_Services;
using DOGD_API.Application.Services.Weather;
using DOGD_API.Data;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Hangfire;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// ===============================
// Database
// ===============================
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(connectionString));

// ===============================
// CORS
// ===============================
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins("http://localhost:5173")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

// ===============================
// JWT Authentication
// ===============================
var jwtKey = builder.Configuration["Jwt:Key"];

if (string.IsNullOrWhiteSpace(jwtKey))
{
    throw new Exception("Add Jwt:Key to appsettings.json before running the API.");
}

var keyBytes = Encoding.UTF8.GetBytes(jwtKey);
if (keyBytes.Length < 32)
{
    keyBytes = System.Security.Cryptography.SHA256.HashData(keyBytes);
}

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(keyBytes),
        ValidateIssuer = false,
        ValidateAudience = false,
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddSingleton<IJwtService, JwtService>();

// ===============================
// Controllers & JSON
// ===============================
builder.Services.AddControllers()
    .AddJsonOptions(opts =>
    {
        opts.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
        opts.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
    });

builder.Services.AddOpenApi();

// ===============================
// Application Services
// ===============================
builder.Services.AddScoped<IDiagnosisService, DiagnosisService>();
builder.Services.AddScoped<IImageUploadService, ImageUploadService>();

builder.Services.AddHttpClient<IYoloService, YoloService>(client =>
{
    client.BaseAddress = new Uri("http://127.0.0.1:8000/");
});

builder.Services.AddScoped<ITreatmentService, TreatmentService>();
builder.Services.AddScoped<ITextToSpeechService, FakeTtsService>();
builder.Services.AddScoped<IFcmService, UnifiedFcmService>();
builder.Services.AddScoped<IAdminTreatmentPlanService, AdminTreatmentPlanService>();

// ===============================
// Weather Service
// ===============================
builder.Services.AddHttpClient("OpenWeatherClient", client =>
{
    client.BaseAddress = new Uri("https://api.openweathermap.org/");
    client.Timeout = TimeSpan.FromSeconds(10);
});

builder.Services.AddScoped<IWeatherService, OpenWeatherService>();
builder.Services.AddScoped<WeatherMonitoringJob>();

// ===============================
// Other Services
// ===============================
builder.Services.AddScoped<IDiseaseService, DiseaseService>();
builder.Services.AddScoped<IAgriculturalLogService, AgriculturalLogService>();
builder.Services.AddScoped<ILibraryService, LibraryService>();
builder.Services.AddScoped<ILibraryCategoryService, LibraryCategoryService>();
builder.Services.AddScoped<INotificationService, NotificationService>();

// ===============================
// Firebase
// ===============================
var firebaseKeyPath = Path.Combine(builder.Environment.ContentRootPath, "firebase-key.json");

FirebaseApp.Create(new AppOptions()
{
    Credential = GoogleCredential.FromFile(firebaseKeyPath)
});

builder.Services.AddScoped<IFirebaseAuthService, FirebaseAuthService>();

// ===============================
// Hangfire
// ===============================
builder.Services.AddHangfire(config =>
    config.UseSqlServerStorage(connectionString));

builder.Services.AddHangfireServer();

builder.Services.AddScoped<TreatmentReminderJob>();

// ===============================
// Build App
// ===============================
var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHangfireDashboard();

app.UseStaticFiles();
app.UseRouting();

app.UseCors("AllowFrontend");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// ===============================
// Recurring Jobs
// ===============================
RecurringJob.AddOrUpdate<WeatherMonitoringJob>(
    "weather-monitoring-job",
    job => job.RunAsync(),
    Cron.Hourly);

// ===============================
// Seed Admin
// ===============================
await app.Services.EnsureSeedAdminAsync();

app.Run();