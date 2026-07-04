using DOGD_API.Application.DTOs.TreatmentPlans.Admin;
using DOGD_API.Application.Services.Diagnosis;
using DOGD_API.Application.Services.Treatment_Services;
using DOGD_API.Data;
using DOGD_API.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

public class AdminTreatmentPlanService : IAdminTreatmentPlanService
{
    private readonly AppDbContext _db;
    private readonly IImageUploadService _imageService;

    public AdminTreatmentPlanService(
        AppDbContext db,
        IImageUploadService imageService)
    {
        _db = db;
        _imageService = imageService;
    }

    // =========================
    // Treatment Plan
    // =========================
    public async Task<TreatmentPlan> CreatePlanAsync(CreateTreatmentPlanDto dto)
    {
        if (!await _db.Diseases.AnyAsync(d => d.Id == dto.DiseaseId))
            throw new ArgumentException("Disease not found");

        var exists = await _db.TreatmentPlans.AnyAsync(p => p.DiseaseId == dto.DiseaseId);
        if (exists)
            throw new InvalidOperationException("Disease already has a treatment plan");

        var plan = new TreatmentPlan
        {
            Id = Guid.NewGuid(),
            DiseaseId = dto.DiseaseId,
            Name = dto.Name,
            DoseIntervalDays = dto.DoseIntervalDays
        };

        _db.TreatmentPlans.Add(plan);
        await _db.SaveChangesAsync();
        return plan;
    }

    public async Task<TreatmentPlan> UpdatePlanAsync(UpdateTreatmentPlanDto dto)
    {
        var plan = await _db.TreatmentPlans.FindAsync(dto.Id)
            ?? throw new KeyNotFoundException("Treatment plan not found");

        plan.Name = dto.Name;
        plan.DoseIntervalDays = dto.DoseIntervalDays;


        await _db.SaveChangesAsync();
        return plan;
    }

    public async Task DeletePlanAsync(Guid planId)
    {
        var plan = await _db.TreatmentPlans
            .Include(p => p.Steps)
            .FirstOrDefaultAsync(p => p.Id == planId)
            ?? throw new KeyNotFoundException("Treatment plan not found");

        _db.TreatmentSteps.RemoveRange(plan.Steps);
        _db.TreatmentPlans.Remove(plan);

        await _db.SaveChangesAsync();
    }

    public async Task<TreatmentPlan?> GetPlanByIdAsync(Guid planId)
        => await _db.TreatmentPlans
            .Include(p => p.Steps.OrderBy(s => s.StepOrder))
            .FirstOrDefaultAsync(p => p.Id == planId);

    public async Task<List<TreatmentPlan>> GetPlansByDiseaseAsync(Guid diseaseId)
        => await _db.TreatmentPlans
            .Where(p => p.DiseaseId == diseaseId)
            .Include(p => p.Steps)
            .ToListAsync();

    // =========================
    // Treatment Steps (مع صورة)
    // =========================
    public async Task<TreatmentStep> CreateStepAsync(
        CreateTreatmentStepDto dto,
        IFormFile? pesticideImage)
    {
        var plan = await _db.TreatmentPlans
            .Include(p => p.Steps)
            .FirstOrDefaultAsync(p => p.Id == dto.TreatmentPlanId)
            ?? throw new ArgumentException("Treatment plan not found");

        if (plan.Steps.Any(s => s.StepOrder == dto.StepOrder))
            throw new InvalidOperationException("Step order already exists in this plan");

        string? imageUrl = null;
        if (pesticideImage != null)
            imageUrl = await _imageService.UploadImageAsync(pesticideImage);

        var step = new TreatmentStep
        {
            Id = Guid.NewGuid(),
            TreatmentPlanId = dto.TreatmentPlanId,
            StepOrder = dto.StepOrder,
            PesticideName = dto.PesticideName,
            ChemicalGroup = dto.ChemicalGroup,
            PesticideImageUrl = imageUrl,
            DosageInstructions = dto.DosageInstructions,
            MixQuantityAndType = dto.MixQuantityAndType,
            SafetyInfo = dto.SafetyInfo,
            ImportantNotes = dto.ImportantNotes
        };

        _db.TreatmentSteps.Add(step);
        await _db.SaveChangesAsync();
        return step;
    }

    public async Task<TreatmentStep> UpdateStepAsync(
        UpdateTreatmentStepDto dto,
        IFormFile? pesticideImage)
    {
        var step = await _db.TreatmentSteps.FindAsync(dto.Id)
            ?? throw new KeyNotFoundException("Treatment step not found");

        if (pesticideImage != null)
            step.PesticideImageUrl = await _imageService.UploadImageAsync(pesticideImage);

        step.StepOrder = dto.StepOrder;
        step.PesticideName = dto.PesticideName;
        step.ChemicalGroup = dto.ChemicalGroup;
        step.DosageInstructions = dto.DosageInstructions;
        step.MixQuantityAndType = dto.MixQuantityAndType;
        step.SafetyInfo = dto.SafetyInfo;
        step.ImportantNotes = dto.ImportantNotes;

        await _db.SaveChangesAsync();
        return step;
    }

    public async Task UpdateStepsOrderAsync(Guid planId, List<UpdateStepOrderDto> orders)
    {
        if (orders == null || orders.Count == 0) return;

        // build a CASE statement to set each step's order in a single SQL update
        var cases = string.Join(Environment.NewLine,
            orders.Select(o => $"WHEN [Id] = '{o.Id}' THEN {o.StepOrder}"));

        var sql = $@"
UPDATE [TreatmentSteps]
SET [StepOrder] = CASE
{cases}
    ELSE [StepOrder]
END
WHERE [TreatmentPlanId] = '{planId}'";

        // execute raw SQL; uniqueness constraint enforced by DB after statement
        await _db.Database.ExecuteSqlRawAsync(sql);
    }

    public async Task<List<TreatmentStep>> GetStepsByPlanAsync(Guid planId)
        => await _db.TreatmentSteps
            .Where(s => s.TreatmentPlanId == planId)
            .OrderBy(s => s.StepOrder)
            .ToListAsync();

    public async Task DeleteStepAsync(Guid stepId)
    {
        var step = await _db.TreatmentSteps.FindAsync(stepId)
            ?? throw new KeyNotFoundException("Treatment step not found");

        if (!string.IsNullOrEmpty(step.PesticideImageUrl))
        {
            try { await _imageService.DeleteImageAsync(step.PesticideImageUrl); }
            catch { }
        }

        _db.TreatmentSteps.Remove(step);
        await _db.SaveChangesAsync();
    }

    // Debug helper: return all plans (including steps) to help diagnose client issues
    public async Task<List<TreatmentPlan>> GetAllPlansAsync()
        => await _db.TreatmentPlans
            .Include(p => p.Steps)
            .ToListAsync();

}
