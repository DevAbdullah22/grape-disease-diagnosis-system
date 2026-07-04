
using DOGD_API.Application.DTOs.User;
using DOGD_API.Application.Services.Auth;
using DOGD_API.Data;
using DOGD_API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DOGD_API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UserController : ControllerBase
    {
        private readonly AppDbContext _db;
        private readonly IFirebaseAuthService _firebaseAuth;

        public UserController(AppDbContext db, IFirebaseAuthService firebaseAuth)
        {
            _db = db;
            _firebaseAuth = firebaseAuth;
        }

        [HttpPost("firebase-register")]
        public async Task<IActionResult> RegisterWithFirebase([FromBody] FirebaseRegisterRequestDto dto)
        {
            if (string.IsNullOrEmpty(dto.IdToken))
                return BadRequest("ID Token is required.");

            // 1) تحقق من صحة التوكن
            var decodedToken = await _firebaseAuth.VerifyIdTokenAsync(dto.IdToken);

            var firebaseUid = decodedToken.Uid;
            var firebaseEmail = decodedToken.Claims.ContainsKey("email")
                                ? decodedToken.Claims["email"]?.ToString()
                                : null;

            if (firebaseEmail == null)
                return BadRequest("Firebase token does not contain an email.");

            // 2) هل المستخدم موجود مسبقًا؟
            var user = await _db.Users.FirstOrDefaultAsync(u => u.FirebaseUid == firebaseUid);

            if (user != null)
            {
                user.LastLogin = DateTime.UtcNow;
                await _db.SaveChangesAsync();

                return Ok(new
                {
                    message = "User already exists.",
                    user
                });
            }

            // 3) إنشاء مستخدم جديد
            var newUser = new User
            {
                Id = Guid.NewGuid(),
                FirebaseUid = firebaseUid,
                Email = firebaseEmail,
                FullName = dto.FullName ?? "",
                PhotoUrl = dto.PhotoUrl,
                EmailVerified = true,
                CreatedAt = DateTime.UtcNow,
                LastLogin = DateTime.UtcNow
            };

            _db.Users.Add(newUser);
            await _db.SaveChangesAsync();

            return Ok(new
            {
                message = "User created successfully.",
                user = newUser
            });
        }

        [HttpPost("update-fcm-token")]
        public async Task<IActionResult> UpdateFcmToken([FromBody] UpdateFcmTokenRequestDto dto)
        {
            if (string.IsNullOrEmpty(dto?.FirebaseUid))
                return BadRequest("FirebaseUid is required.");

            var user = await _db.Users.FirstOrDefaultAsync(u => u.FirebaseUid == dto.FirebaseUid);
            if (user == null)
                return NotFound("User not found");

            user.FcmToken = dto.Token;
            user.LastLogin = DateTime.UtcNow; // optional: update last activity
            await _db.SaveChangesAsync();

            return Ok(new { message = "Fcm token updated", user });
        }

        // GET api/User/me?firebaseUid={uid}
        [HttpGet("me")]
        public async Task<IActionResult> GetByFirebaseUid([FromQuery] string firebaseUid)
        {
            if (string.IsNullOrEmpty(firebaseUid))
                return BadRequest("firebaseUid is required");

            var user = await _db.Users.FirstOrDefaultAsync(u => u.FirebaseUid == firebaseUid);
            if (user == null) return NotFound("User not found");

            return Ok(user);
        }
    }
}