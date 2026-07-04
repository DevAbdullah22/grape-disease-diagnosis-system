using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace DOGD_API.Application.Services.Auth
{
    public interface IJwtService
    {
        string GenerateToken(Guid adminId, string username);
    }

    // Simple POCO to bind JWT settings
    public class JwtSettings
    {
        public string Key { get; set; }
        public string Issuer { get; set; }
        public string Audience { get; set; }
        public int ExpMinutes { get; set; } = 60;
    }

    public class JwtService : IJwtService
    {
        private readonly JwtSettings _settings;
        private readonly byte[] _keyBytes;

        public JwtService(IConfiguration config)
        {
            _settings = new JwtSettings();
            config.GetSection("Jwt").Bind(_settings);

            if (string.IsNullOrWhiteSpace(_settings.Key))
                throw new ArgumentException("JWT secret key is not configured.");

            // Ensure the signing key is at least 256 bits. If the configured secret is shorter
            // derive a 256-bit key via SHA-256 to avoid weak key sizes that fail signing.
            var rawKey = Encoding.UTF8.GetBytes(_settings.Key);
            if (rawKey.Length < 32)
            {
                using var sha = System.Security.Cryptography.SHA256.Create();
                _keyBytes = sha.ComputeHash(rawKey);
            }
            else
            {
                _keyBytes = rawKey;
            }
        }

        public string GenerateToken(Guid adminId, string username)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = new SymmetricSecurityKey(_keyBytes);
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256Signature);

            // Include role as a claim for role-based authorization
            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, adminId.ToString()),
                new Claim(JwtRegisteredClaimNames.UniqueName, username),
                new Claim(ClaimTypes.Role, "Admin"), // recognized by [Authorize(Roles = "Admin")]
                new Claim("role", "Admin") // ensure some consumers see the role claim as well
            };

            var token = new JwtSecurityToken(
                issuer: _settings.Issuer,
                audience: _settings.Audience,
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(_settings.ExpMinutes),
                signingCredentials: creds
            );

            return tokenHandler.WriteToken(token);
        }
    }
}