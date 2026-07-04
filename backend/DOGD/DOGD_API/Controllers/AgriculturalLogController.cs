using DOGD_API.Application.Services.Logs_Services;
using Microsoft.AspNetCore.Mvc;

namespace DOGD_API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AgriculturalLogController : ControllerBase
    {
        private readonly IAgriculturalLogService _service;

        public AgriculturalLogController(IAgriculturalLogService service)
        {
            _service = service;
        }

        [HttpGet("{userId}/history")]
        public async Task<IActionResult> GetUserHistory(Guid userId)
        {
            var log = await _service.GetUserHistoryAsync(userId);
            return Ok(log);
        }

        [HttpGet("diagnosis/{diagnosisId}")]
        public async Task<IActionResult> GetDiagnosisDetails(Guid diagnosisId)
        {
            var details = await _service.GetDiagnosisDetailsAsync(diagnosisId);
            if (details == null)
                return NotFound("Diagnosis not found.");
            // convert any relative urls in reference images to absolute
            if (details.ReferenceImages != null && details.ReferenceImages.Count > 0)
            {
                var baseUrl = $"{Request.Scheme}://{Request.Host}";
                foreach (var img in details.ReferenceImages)
                {
                    if (!string.IsNullOrWhiteSpace(img.ImageUrl) && img.ImageUrl.StartsWith("/"))
                        img.ImageUrl = baseUrl + img.ImageUrl;
                }
            }

            return Ok(details);
        }
    }

}
