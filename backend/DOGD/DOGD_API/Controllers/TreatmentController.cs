using DOGD_API.Application.Services.Treatment_Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace DOGD_API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TreatmentController : ControllerBase
    {
        private readonly ITreatmentService _service , _treatmentService;
        public TreatmentController(ITreatmentService service)
        {
            _service = service;
            _treatmentService= service;
        }

   

        [HttpGet("plan/{diagnosisId}")]
        public async Task<IActionResult> GetTreatmentPlan(Guid diagnosisId)
        {
           
            try
            {
                var result = await _treatmentService.GetTreatmentPlanAsync(diagnosisId);
                return Ok(result);
            }
            catch (KeyNotFoundException) { return NotFound(); }
            catch (Exception ex) { return BadRequest(ex.Message); }
        }

        [HttpPost("execute-step/{diagnosisId}")]
        public async Task<IActionResult> ExecuteTreatmentStep(Guid diagnosisId, [FromQuery] int? stepOrder = null)
        {
            try
            {
                // If stepOrder is provided, service will execute that specific step (manual override)
                var result = await _treatmentService.ExecuteTreatmentStepAsync(diagnosisId, stepOrder);
                return Ok(result);
            }
            catch (KeyNotFoundException) { return NotFound(); }
            catch (InvalidOperationException ex) { return BadRequest(ex.Message); }
            catch (Exception ex) { return BadRequest(ex.Message); }
        }


        [HttpGet("tts/plan/{diagnosisId}")]
        public async Task<IActionResult> GetTreatmentPlanAudio(Guid diagnosisId)
        {
            
            try
            {
                var result = await _treatmentService.GenerateTreatmentPlanAudioAsync(diagnosisId);
                return Ok(result);
            }
            catch (KeyNotFoundException) { return NotFound(); }
            catch (Exception ex) { return BadRequest(ex.Message); }
        }

    }

}
