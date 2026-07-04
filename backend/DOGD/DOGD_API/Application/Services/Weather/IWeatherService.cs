
using DOGD_API.Application.DTOs.Weather;

namespace DOGD_API.Application.Services.Weather
{
    public interface IWeatherService
    {
        Task<OpenWeatherCurrentDto?> GetCurrentAsync(
            double lat,
            double lon,
            CancellationToken cancellationToken = default);
    }
}