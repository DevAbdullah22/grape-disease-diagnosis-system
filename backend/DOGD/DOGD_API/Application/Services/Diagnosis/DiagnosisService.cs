
using DOGD_API.Application.DTOs.Diagnosis;
using DOGD_API.Application.Services.AI;
using DOGD_API.Data;
using Microsoft.EntityFrameworkCore;

namespace DOGD_API.Application.Services.Diagnosis
{
    public interface IDiagnosisService
    {
        Task<DiagnosisResultDto> DiagnoseAsync(DiagnosisRequestDto dto);
    }

    public class DiagnosisService : IDiagnosisService
    {
        private readonly AppDbContext _db;
        private readonly IYoloService _yolo;
        private readonly IImageUploadService _uploader;
        private readonly ILogger<DiagnosisService> _logger;

        public DiagnosisService(AppDbContext db, IYoloService yolo, IImageUploadService uploader, ILogger<DiagnosisService> logger)
        {
            _db = db;
            _yolo = yolo;
            _uploader = uploader;
            _logger = logger;
        }

        public async Task<DiagnosisResultDto> DiagnoseAsync(DiagnosisRequestDto dto)
        {
            string imageUrl = string.Empty;
            var diagnosisSaved = false;

            try
            {
                // 1) رفع الصورة كما هو، ثم تحليل AI.
                imageUrl = await _uploader.UploadImageAsync(dto.Image);
                var (status, diseaseName, confidence) = await _yolo.AnalyzeAsync(dto.Image);
                try { _logger.LogDebug("Yolo Analyze -> status: {s}, disease: {d}, confidence: {c}", status, diseaseName, confidence); } catch { }

                // 2) الاعتماد فقط على status القادم من FastAPI (بدون أي تخمين نصي).
                if (status == "not_grape")
                {
                    try { await _uploader.DeleteImageAsync(imageUrl); } catch { }
                    return new DiagnosisResultDto
                    {
                        DiagnosisId = Guid.Empty,
                        DiseaseId = Guid.Empty,
                        DiseaseName = string.Empty,
                        Description = string.Empty,
                        Confidence = 0f,
                        ImageUrl = imageUrl,
                        Status = "not_grape",
                        Message = "الصورة ليست ورقة عنب"
                    };
                }

                if (status == "disease_not_detected" || status == "uncertain")
                {
                    try { await _uploader.DeleteImageAsync(imageUrl); } catch { }
                    return new DiagnosisResultDto
                    {
                        DiagnosisId = Guid.Empty,
                        DiseaseId = Guid.Empty,
                        DiseaseName = string.Empty,
                        Description = string.Empty,
                        Confidence = 0f,
                        ImageUrl = imageUrl,
                        Status = "unknown_disease",
                        Message = "لم يتم التعرف على الحالة"
                    };
                }

                // أي حالة غير معروفة من خدمة AI تُعامل كحالة غير معروفة آمنة.
                if (status != "disease_detected")
                {
                    try { await _uploader.DeleteImageAsync(imageUrl); } catch { }
                    return new DiagnosisResultDto
                    {
                        DiagnosisId = Guid.Empty,
                        DiseaseId = Guid.Empty,
                        DiseaseName = string.Empty,
                        Description = string.Empty,
                        Confidence = 0f,
                        ImageUrl = imageUrl,
                        Status = "unknown_disease",
                        Message = "لم يتم التعرف على الحالة"
                    };
                }

                // 3) حالة مرض مكتشف: ابحث عنه في قاعدة البيانات.
                var normalizedDiseaseName = (diseaseName ?? string.Empty).Trim();
                var disease = await _db.Diseases
                    .FirstOrDefaultAsync(d => d.Name == normalizedDiseaseName);

                if (disease == null)
                {
                    try { await _uploader.DeleteImageAsync(imageUrl); } catch { }
                    return new DiagnosisResultDto
                    {
                        DiagnosisId = Guid.Empty,
                        DiseaseId = Guid.Empty,
                        DiseaseName = string.Empty,
                        Description = string.Empty,
                        Confidence = 0f,
                        ImageUrl = imageUrl,
                        Status = "unknown_disease",
                        Message = "لم يتم التعرف على الحالة"
                    };
                }

                // 4) حفظ التشخيص فقط في حالة disease_detected الصحيحة.
                var diagnosis = new DOGD_API.Models.Diagnosis
                {
                    Id = Guid.NewGuid(),
                    UserId = dto.UserId,
                    DiseaseId = disease.Id,
                    Confidence = confidence,
                    ImageUrl = imageUrl,
                    DiagnosisDate = DateTime.UtcNow,
                    Status = "Not_Treated"
                };

                _db.Diagnoses.Add(diagnosis);
                await _db.SaveChangesAsync();
                diagnosisSaved = true;

                return new DiagnosisResultDto
                {
                    DiseaseId = disease.Id,
                    DiagnosisId = diagnosis.Id,
                    DiseaseName = disease.Name,
                    Description = disease.Description,
                    Confidence = confidence,
                    ImageUrl = imageUrl,
                    Status = "ok",
                    Message = string.Empty
                };
            }
            catch (Exception ex)
            {
                try
                {
                    _logger.LogError(ex, "Diagnosis flow failed.");
                }
                catch { }

                // لا نترك صور مرفوعة يتيمة إذا فشل المسار قبل الحفظ.
                if (!diagnosisSaved && !string.IsNullOrWhiteSpace(imageUrl))
                {
                    try { await _uploader.DeleteImageAsync(imageUrl); } catch { }
                }

                return new DiagnosisResultDto
                {
                    DiagnosisId = Guid.Empty,
                    DiseaseId = Guid.Empty,
                    DiseaseName = string.Empty,
                    Description = string.Empty,
                    Confidence = 0f,
                    ImageUrl = imageUrl,
                    Status = "error",
                    Message = "حدث خطأ، حاول مرة أخرى"
                };
            }
        }
    }

}
