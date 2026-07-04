using DOGD_API.Application.DTOs.LogsDtos;

namespace DOGD_API.Application.Services.Logs_Services
{
    public interface IAgriculturalLogService
    {
        Task<List<DiagnosisSummaryDto>> GetUserHistoryAsync(Guid userId);
        Task<DiagnosisDetailsDto> GetDiagnosisDetailsAsync(Guid diagnosisId);
    }
}
