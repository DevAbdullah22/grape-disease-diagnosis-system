using DOGD_API.Application.DTOs.DiseaseDtos;
using DOGD_API.Application.DTOs.LogsDtos;
using DOGD_API.Data;
using Microsoft.EntityFrameworkCore;

namespace DOGD_API.Application.Services.Logs_Services
{
    public class AgriculturalLogService : IAgriculturalLogService
    {
        private readonly AppDbContext _db;

        public AgriculturalLogService(AppDbContext db)
        {
            _db = db;
        }


        // =====================================================
        // 📜 سجل التشخيصات للمستخدم
        // =====================================================
        public async Task<List<DiagnosisSummaryDto>> GetUserHistoryAsync(Guid userId)
        {
            return await _db.Diagnoses
                .Where(d => d.UserId == userId)
                .Include(d => d.Disease)
                .OrderByDescending(d => d.DiagnosisDate)
                .Select(d => new DiagnosisSummaryDto
                {
                    DiagnosisId = d.Id,
                    DiseaseName = d.Disease.Name,
                    Date = d.DiagnosisDate,
                    ImageUrl = d.ImageUrl,
                    Status = d.Status
                })
                .ToListAsync();
        }

        // =====================================================
        // 🔍 تفاصيل تشخيص واحد + الخطة العلاجية + التنفيذ
        // =====================================================
        public async Task<DiagnosisDetailsDto?> GetDiagnosisDetailsAsync(Guid diagnosisId)
        {
            var diagnosis = await _db.Diagnoses
                .Include(d => d.Disease)
                    .ThenInclude(d => d.TreatmentPlan)
                        .ThenInclude(p => p.Steps)
                .Include(d => d.Executions)
                .FirstOrDefaultAsync(d => d.Id == diagnosisId);

            if (diagnosis == null)
                return null;

            return new DiagnosisDetailsDto
            {
                DiagnosisId = diagnosis.Id,
                DiseaseId = diagnosis.Disease.Id,

                DiseaseName = diagnosis.Disease.Name,
                DiseaseDescription = diagnosis.Disease.Description,
                Confidence = diagnosis.Confidence,
                ImageUrl = diagnosis.ImageUrl,
                DiagnosisDate = diagnosis.DiagnosisDate,
                Status = diagnosis.Status,

                ReferenceImages = diagnosis.Disease.ReferenceImages
                    .Select(r => new ReferenceImageDto
                    {
                        Id = r.Id,
                        ImageUrl = r.ImageUrl
                    })
                    .ToList(),
                // =============================
                // 🌿 الخطة العلاجية (إن وجدت)
                // =============================
                TreatmentPlan = diagnosis.Disease.TreatmentPlan == null
                    ? null
                    : new TreatmentPlanLogDto
                    {
                        Name = diagnosis.Disease.TreatmentPlan.Name,
                        DoseIntervalDays = diagnosis.Disease.TreatmentPlan.DoseIntervalDays,
                        Steps = diagnosis.Disease.TreatmentPlan.Steps
                            .OrderBy(s => s.StepOrder)
                            .Select(s => new TreatmentStepLogDto
                            {
                                StepOrder = s.StepOrder,
                                PesticideName = s.PesticideName,
                                PesticideImageUrl = s.PesticideImageUrl,
                                DosageInstructions = s.DosageInstructions,
                                MixQuantityAndType = s.MixQuantityAndType,
                                SafetyInfo = s.SafetyInfo,
                                ImportantNotes = s.ImportantNotes
                                // interval removed
                            })
                            .ToList()
                    },

                // =============================
                // 💉 الجرعات المنفذة
                // =============================
                Executions = diagnosis.Executions
                    .OrderBy(e => e.DoseNumber)
                    .Select(e => new TreatmentExecutionDto
                    {
                        DoseNumber = e.DoseNumber,
                        ExecutedAt = e.ExecutedAt,
                        NextDoseAt = e.NextDoseAt
                    })
                    .ToList()
            };
        }





        
    }

}
