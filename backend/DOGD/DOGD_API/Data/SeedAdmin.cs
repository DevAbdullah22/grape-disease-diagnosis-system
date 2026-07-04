using DOGD_API.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace DOGD_API.Data
{
    public static class SeedAdmin
    {
        // Seeds an initial admin only when both InitialAdmin:Username and InitialAdmin:Password
        // are provided via configuration (appsettings or environment variables).
        public static async Task EnsureSeedAdminAsync(this IServiceProvider services)
        {
            using var scope = services.CreateScope();
            var provider = scope.ServiceProvider;
            var logger = provider.GetRequiredService<ILoggerFactory>().CreateLogger("SeedAdmin");

            var config = provider.GetRequiredService<IConfiguration>();
            var username = config["InitialAdmin:Username"];
            var password = config["InitialAdmin:Password"];

            if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
            {
                logger.LogInformation("Initial admin credentials not provided; skipping admin seeding.");
                return;
            }

            var db = provider.GetRequiredService<AppDbContext>();

            // Ensure DB is available/migrated before seeding
            try
            {
                await db.Database.MigrateAsync();
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Database migrate failed during seeding; continuing anyway.");
            }

            var exists = await db.Admins.AnyAsync(a => a.Username == username);
            if (exists)
            {
                logger.LogInformation("Admin with the provided username already exists; skipping seeding.");
                return;
            }

            // Hash the password with BCrypt before storing — do NOT store plaintext passwords.
            var passwordHash = BCrypt.Net.BCrypt.HashPassword(password);

            var admin = new Admin
            {
                Id = Guid.NewGuid(),
                Username = username,
                PasswordHash = passwordHash,
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                LastLogin = null
            };

            db.Admins.Add(admin);
            await db.SaveChangesAsync();

            logger.LogInformation("Initial admin seeded (username: {Username}).", username);
        }
    }
}
