using DOGD_API.Application.DTOs.TreatmentPlans.Admin;
using DOGD_API.Application.Services.Treatment_Services;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/admin/treatment-plans")]
public class TreatmentPlansController : ControllerBase
{
    private readonly IAdminTreatmentPlanService _service;

    public TreatmentPlansController(IAdminTreatmentPlanService service)
    {
        _service = service;
    }

    // ===== Plans =====

    [HttpGet("{planId:guid}")]
    public async Task<IActionResult> GetPlan(Guid planId)
        => Ok(await _service.GetPlanByIdAsync(planId));

    [HttpGet("by-disease/{diseaseId:guid}")]
    public async Task<IActionResult> GetByDisease(Guid diseaseId)
        => Ok(await _service.GetPlansByDiseaseAsync(diseaseId));

    // Debug: get all plans (developer helper)
    [HttpGet("debug/all")]
    public async Task<IActionResult> GetAll()
        => Ok(await _service.GetAllPlansAsync());

    [HttpPost]
    public async Task<IActionResult> CreatePlan(CreateTreatmentPlanDto dto)
    {
        try
        {
            var plan = await _service.CreatePlanAsync(dto);
            return Ok(plan);
        }
        catch (InvalidOperationException ex)
        {
            // Conflict: business rule (one plan per disease)
            return Conflict(new { message = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
    [HttpPut]
    public async Task<IActionResult> UpdatePlan(UpdateTreatmentPlanDto dto)
        => Ok(await _service.UpdatePlanAsync(dto));

    [HttpDelete("{planId:guid}")]
    public async Task<IActionResult> DeletePlan(Guid planId)
    {
        await _service.DeletePlanAsync(planId);
        return NoContent();
    }

    // ===== Steps =====

    [HttpGet("{planId:guid}/steps")]
    public async Task<IActionResult> GetSteps(Guid planId)
        => Ok(await _service.GetStepsByPlanAsync(planId));
    [HttpPost("steps")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> CreateStep(
        [FromForm] CreateTreatmentStepDto dto,
        [FromForm] IFormFile? pesticideImage)
    {
        var result = await _service.CreateStepAsync(dto, pesticideImage);
        return Ok(result);
    }

    [HttpPut("steps")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> UpdateStep(
    [FromForm] UpdateTreatmentStepDto dto,
    [FromForm] IFormFile? pesticideImage)
    {
        var result = await _service.UpdateStepAsync(dto, pesticideImage);
        return Ok(result);
    }

    // bulk reorder steps for a plan
    [HttpPut("{planId:guid}/steps/order")]
    public async Task<IActionResult> UpdateStepsOrder(Guid planId, [FromBody] List<UpdateStepOrderDto> orders)
    {
        await _service.UpdateStepsOrderAsync(planId, orders);
        return NoContent();
    }


    [HttpDelete("steps/{stepId:guid}")]
    public async Task<IActionResult> DeleteStep(Guid stepId)
    {
        await _service.DeleteStepAsync(stepId);
        return NoContent();
    }
}
