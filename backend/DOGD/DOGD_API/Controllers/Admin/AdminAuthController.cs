using System.Threading.Tasks;
using DOGD_API.Application.DTOs;
using DOGD_API.Application.DTOs.Admin;
using DOGD_API.Application.Services.Auth;
using DOGD_API.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace DOGD_API.Controllers.Admin
{
    [ApiController]
    [Route("api/admin/auth")]
    public class AdminAuthController : ControllerBase
    {
        private readonly AppDbContext _db;
        private readonly IJwtService _jwtService;

        public AdminAuthController(AppDbContext db, IJwtService jwtService)
        {
            _db = db;
            _jwtService = jwtService;
        }

        [HttpPost("login")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        public async Task<IActionResult> Login([FromBody] AdminLoginDto dto)
        {
            // Find admin by username using EF Core (parameterized queries to avoid SQL injection)
            var admin = await _db.Admins.SingleOrDefaultAsync(a => a.Username == dto.Username);

            if (admin == null)
            {
                // Do not leak which part failed beyond invalid credentials
                return Unauthorized();
            }

            if (!admin.IsActive)
            {
                // Admin exists but is inactive/blocked
                return Forbid();
            }

            // Verify password hash using BCrypt; this does not expose plaintext passwords
            var passwordMatches = BCrypt.Net.BCrypt.Verify(dto.Password, admin.PasswordHash);

            if (!passwordMatches)
            {
                return Unauthorized();
            }

            // Update last login timestamp on successful authentication
            admin.LastLogin = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            var token = _jwtService.GenerateToken(admin.Id, admin.Username);

            return Ok(new { token });
        }
    }
}
