

using DOGD_API.Application.DTOs.Diagnosis;
using DOGD_API.Application.Services.Diagnosis;
using DOGD_API.Application.DTOs.LogsDtos;
using Microsoft.AspNetCore.Mvc;
using DOGD_API.Data;
using Microsoft.EntityFrameworkCore;

namespace DOGD_API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DiagnosisController : ControllerBase
    {
        private readonly IDiagnosisService _service;
        private readonly AppDbContext _db;
        private readonly Application.Services.Auth.IFirebaseAuthService _firebaseAuth;

        public DiagnosisController(IDiagnosisService service, AppDbContext db, Application.Services.Auth.IFirebaseAuthService firebaseAuth)
        {
            _service = service;
            _db = db;
            _firebaseAuth = firebaseAuth;
        }

        [HttpGet("last")]
        public async Task<IActionResult> GetLastDiagnosis([FromQuery] Guid userId)
        {
            if (userId == Guid.Empty)
                return BadRequest(new { message = "userId is required." });

            var last = await _db.Diagnoses
                .Where(d => d.UserId == userId)
                .Include(d => d.Disease)
                .OrderByDescending(d => d.DiagnosisDate)
                .Select(d => new DiagnosisSummaryDto
                {
                    DiagnosisId = d.Id,
                    DiseaseName = d.Disease.Name,
                    DiagnosisDate = d.DiagnosisDate,
                    Date = d.DiagnosisDate,
                    ImageUrl = d.ImageUrl,
                    Status = d.Status
                })
                .FirstOrDefaultAsync();

            if (last == null)
                return NotFound(new { message = "No diagnosis found for this user." });

            return Ok(last);
        }

        [HttpPost("analyze")]
        public async Task<IActionResult> Analyze([FromForm] DiagnosisRequestDto dto)
        {
            if (dto.Image == null)
                return BadRequest("Image is required.");

            // إذا تم تمرير UserId لكنّه لا يطابق أي مستخدم، حاول أن نستخرج IdToken أو Authorization
            DOGD_API.Models.User? user = null;

            if (dto.UserId != Guid.Empty)
            {
                user = await _db.Users.FindAsync(dto.UserId);
            }

            // إذا لم يوجد user محليًا، حاول الحصول على IdToken من الحقول أو الهيدر
            if (user == null)
            {
                string? idToken = null;
                try
                {
                    if (Request.HasFormContentType && Request.Form.ContainsKey("IdToken"))
                        idToken = Request.Form["IdToken"].FirstOrDefault();
                }
                catch { }

                if (string.IsNullOrEmpty(idToken))
                {
                    // فحص هيدر Authorization: Bearer <token>
                    var auth = Request.Headers["Authorization"].FirstOrDefault();
                    if (!string.IsNullOrEmpty(auth) && auth.StartsWith("Bearer "))
                        idToken = auth.Substring("Bearer ".Length).Trim();
                }

                if (!string.IsNullOrEmpty(idToken))
                {
                    try
                    {
                        var decoded = await _firebaseAuth.VerifyIdTokenAsync(idToken);
                        var firebaseUid = decoded.Uid;
                        var firebaseEmail = decoded.Claims.ContainsKey("email") ? decoded.Claims["email"]?.ToString() : null;

                        if (firebaseUid != null && firebaseEmail != null)
                        {
                            user = await _db.Users.FirstOrDefaultAsync(u => u.FirebaseUid == firebaseUid);
                            if (user == null)
                            {
                                user = new DOGD_API.Models.User
                                {
                                    Id = Guid.NewGuid(),
                                    FirebaseUid = firebaseUid,
                                    Email = firebaseEmail,
                                    EmailVerified = true,
                                    CreatedAt = DateTime.UtcNow,
                                    LastLogin = DateTime.UtcNow
                                };
                                _db.Users.Add(user);
                                await _db.SaveChangesAsync();
                            }

                            // ضع معرف الباكند في DTO قبل تنفيذ التشخيص
                            dto.UserId = user.Id;
                        }
                    }
                    catch (Exception ex)
                    {
                        // لا نعيد تفاصيل الاستثناء الخام للعميل.
                        _ = ex;
                        return Unauthorized(new { message = "Invalid id token" });
                    }
                }
            }

            // أخيرًا تأكد أن لدينا معرف مستخدم صالح
            if (dto.UserId == Guid.Empty)
                return BadRequest(new { message = "UserId is required (or provide a valid IdToken/Authorization header)" });

            DiagnosisResultDto? result;
            try
            {
                result = await _service.DiagnoseAsync(dto);
            }
            catch
            {
                // حماية إضافية: لا تمرير أي استثناء خام إلى Flutter.
                result = new DiagnosisResultDto
                {
                    Status = "error",
                    Message = "حدث خطأ، حاول مرة أخرى"
                };
            }

            if (result == null)
                return Ok(new DiagnosisResultDto
                {
                    Status = "error",
                    Message = "حدث خطأ، حاول مرة أخرى"
                });

            return Ok(result);
        }
    }

}
