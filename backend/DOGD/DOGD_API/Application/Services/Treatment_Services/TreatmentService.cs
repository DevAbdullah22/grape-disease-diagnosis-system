

using DOGD_API.Application.BackgroundJobs;
using DOGD_API.Application.DTOs.Treatment;
using DOGD_API.Application.Services.Notifications;
using DOGD_API.Data;
using DOGD_API.Models;
using Hangfire;
using DOGD_API.Application.DTOs.TreatmentPlans;
using Microsoft.EntityFrameworkCore;

namespace DOGD_API.Application.Services.Treatment_Services
{
    public class TreatmentService : ITreatmentService
    {
        private readonly AppDbContext _db;
        private readonly ITextToSpeechService _tts;
        private readonly IFcmService _fcm;
        private readonly ILogger<TreatmentService> _logger;
        private readonly IBackgroundJobClient _backgroundJobs;

        public TreatmentService(
            AppDbContext db,
            ITextToSpeechService tts,
            IFcmService fcm,
            ILogger<TreatmentService> logger,
            IBackgroundJobClient backgroundJobs)
        {
            _db = db;
            _tts = tts;
            _fcm = fcm;
            _logger = logger;
            _backgroundJobs = backgroundJobs;
        }



        //******************************************************************************************************************
        //**********************************************التوصيات الجديدة ********************************************************************
        //******************************************************************************************************************

        // =======================================================
        // 🔥 جلب خطة العلاج المتسلسلة (النظام الجديد)
        // =======================================================
        public async Task<TreatmentPlanDto> GetTreatmentPlanAsync(Guid diagnosisId)
        {
            var diagnosis = await _db.Diagnoses
                .Include(d => d.Disease)
                    .ThenInclude(dis => dis.TreatmentPlan)
                        .ThenInclude(p => p.Steps)
                          .Include(d => d.Executions)

                .FirstOrDefaultAsync(d => d.Id == diagnosisId);

            if (diagnosis == null)
                throw new KeyNotFoundException("Diagnosis not found");

            var plan = diagnosis.Disease.TreatmentPlan;

            if (plan == null)
                throw new InvalidOperationException("No treatment plan found for this disease");

            return new TreatmentPlanDto
            {
                DiagnosisId = diagnosis.Id,
                DiseaseId = diagnosis.DiseaseId,
                DiseaseName = diagnosis.Disease.Name,

                PlanName = plan.Name,
                DoseIntervalDays = plan.DoseIntervalDays,


                Steps = plan.Steps
                    .OrderBy(s => s.StepOrder)
                    .Select(s => new TreatmentStepDto
                    {
                        StepOrder = s.StepOrder,
                        PesticideName = s.PesticideName,
                        ChemicalGroup = s.ChemicalGroup,
                        PesticideImageUrl = s.PesticideImageUrl,
                        DosageInstructions = s.DosageInstructions,
                        MixQuantityAndType = s.MixQuantityAndType,
                        SafetyInfo = s.SafetyInfo,
                        ImportantNotes = s.ImportantNotes
                    })
                     .ToList(),

                // return executions so the client can compute per-step status
                Executions = diagnosis.Executions?
                    .OrderBy(e => e.DoseNumber)
                    .Select(e => new Application.DTOs.LogsDtos.TreatmentExecutionDto
                    {
                        DoseNumber = e.DoseNumber,
                        ExecutedAt = e.ExecutedAt,
                        NextDoseAt = e.NextDoseAt
                    })
                    .ToList()
            };
        }
        // =======================================================
        // 🔥 تنفيذ رشّة علاجية (Step-based Execution)
        // =======================================================
        public async Task<StartTreatmentResultDto> ExecuteTreatmentStepAsync(Guid diagnosisId, int? stepOrder = null)
        {
            var diagnosis = await _db.Diagnoses
                .Include(d => d.Disease)
                    .ThenInclude(dis => dis.TreatmentPlan)
                        .ThenInclude(p => p.Steps)
                .Include(d => d.Executions)
                .FirstOrDefaultAsync(d => d.Id == diagnosisId);

            if (diagnosis == null)
                throw new KeyNotFoundException("Diagnosis not found");

            var plan = diagnosis.Disease.TreatmentPlan
                ?? throw new InvalidOperationException("Treatment plan not found");

            var orderedSteps = plan.Steps.OrderBy(s => s.StepOrder).ToList();

            if (!orderedSteps.Any())
                throw new InvalidOperationException("Treatment plan has no steps");

            // If a specific stepOrder is requested -> manual override
            TreatmentStep targetStep = null;
            if (stepOrder.HasValue)
            {
                targetStep = orderedSteps.FirstOrDefault(s => s.StepOrder == stepOrder.Value);
                if (targetStep == null)
                    throw new KeyNotFoundException("Requested treatment step not found");

                // prevent duplicate execution for same step
                if (diagnosis.Executions != null && diagnosis.Executions.Any(e => e.DoseNumber == targetStep.StepOrder))
                    throw new InvalidOperationException("هذه الخطوة منفّذة مسبقًا.");
            }

            // COUNT unique executed step numbers
            var executedStepsCount = diagnosis.Executions?.Select(e => e.DoseNumber).Distinct().Count() ?? 0;

            // If all steps already executed
            if (executedStepsCount >= orderedSteps.Count)
            {
                diagnosis.Status = "Treated";
                await _db.SaveChangesAsync();

                return new StartTreatmentResultDto
                {
                    ExecutionId = Guid.Empty,
                    DoseNumber = executedStepsCount,
                    ExecutedAt = DateTime.UtcNow,
                    NextDoseAt = null,
                    Message = "اكتملت جميع الرشّات العلاجية."
                };
            }

            // If no specific step requested -> execute next sequential step
            if (targetStep == null)
            {
                // next sequential step is the first non-executed step in orderedSteps
                targetStep = orderedSteps.OrderBy(s => s.StepOrder)
                    .FirstOrDefault(s => diagnosis.Executions == null || !diagnosis.Executions.Any(e => e.DoseNumber == s.StepOrder));

                if (targetStep == null)
                    throw new InvalidOperationException("No available step to execute");

                // Check timing constraint of last execution
                if (diagnosis.Executions != null && diagnosis.Executions.Any())
                {
                    var lastExec = diagnosis.Executions.OrderByDescending(e => e.ExecutedAt).FirstOrDefault();
                    if (lastExec != null && lastExec.NextDoseAt.HasValue && DateTime.UtcNow < lastExec.NextDoseAt.Value)
                    {
                        return new StartTreatmentResultDto
                        {
                            ExecutionId = lastExec.Id,
                            DoseNumber = lastExec.DoseNumber,
                            ExecutedAt = lastExec.ExecutedAt,
                            NextDoseAt = lastExec.NextDoseAt,
                            Message = "لم يحن موعد الرشّة التالية بعد."
                        };
                    }
                }
            }

            // إنشاء تنفيذ جديد للخطوة المطلوبة
            var execution = new TreatmentExecution
            {
                Id = Guid.NewGuid(),
                DiagnosisId = diagnosis.Id,
                DoseNumber = targetStep.StepOrder,
                ExecutedAt = DateTime.UtcNow,
                NextDoseAt = DateTime.UtcNow.AddDays(plan.DoseIntervalDays)
            };

            _db.TreatmentExecutions.Add(execution);

            // update diagnosis status based on distinct executed steps after this execution
            var newExecutedCount = (diagnosis.Executions?.Select(e => e.DoseNumber).Concat(new[] { execution.DoseNumber }).Distinct().Count()) ?? 1;
            diagnosis.Status = newExecutedCount >= orderedSteps.Count ? "Treated" : "In_Progress";

            // إنشاء إشعار
            var notification = new Notification
            {
                Id = Guid.NewGuid(),
                UserId = diagnosis.UserId,
                Title = $"تذكير الرشّة رقم {targetStep.StepOrder}",
                Body = $"موعد الرشّة التالية بعد {plan.DoseIntervalDays} يوم.",
                Type = "TreatmentReminder",
                RelatedId = diagnosis.Id,
                CreatedAt = DateTime.UtcNow,
                IsSent = false
            };

            _db.Notifications.Add(notification);
            await _db.SaveChangesAsync();

            // جدولة الإشعار
            if (execution.NextDoseAt.HasValue)
            {
                _backgroundJobs.Schedule<TreatmentReminderJob>(
                    job => job.SendReminder(diagnosis.UserId, diagnosis.Id),
                    execution.NextDoseAt.Value
                );
            }

            return new StartTreatmentResultDto
            {
                ExecutionId = execution.Id,
                DoseNumber = execution.DoseNumber,
                ExecutedAt = execution.ExecutedAt,
                NextDoseAt = execution.NextDoseAt,
                Message = $"تم تنفيذ الرشّة رقم {targetStep.StepOrder} بنجاح."
            };
        }
        // =======================================================
        // 🔊 تحويل خطة العلاج المتسلسلة إلى صوت
        // =======================================================
        public async Task<TtsResultDto> GenerateTreatmentPlanAudioAsync(Guid diagnosisId)
        {
            var plan = await GetTreatmentPlanAsync(diagnosisId);

            var text = $"خطة العلاج لمرض {plan.DiseaseName}. ";

            foreach (var step in plan.Steps.OrderBy(s => s.StepOrder))
            {
                text += $"الرشّة رقم {step.StepOrder}. ";
                text += $"اسم المبيد {step.PesticideName}. ";
                text += $"طريقة الاستخدام: {step.DosageInstructions}. ";

                if (!string.IsNullOrWhiteSpace(step.ImportantNotes))
                    text += $"ملاحظات مهمة: {step.ImportantNotes}. ";

                text += $"الفاصل الزمني قبل الرشّة التالية {plan.DoseIntervalDays} يوم. ";
            }
        

        var audioUrl = await _tts.TextToSpeechAsync(
                text,
                $"treatment_plan_{diagnosisId}"
            );

            return new TtsResultDto
            {
                AudioUrl = audioUrl
            };
        }

    }
}