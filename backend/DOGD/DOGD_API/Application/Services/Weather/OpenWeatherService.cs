using DOGD_API.Application.DTOs.Weather;
using System.Text.Json;

namespace DOGD_API.Application.Services.Weather
{
    public class OpenWeatherService : IWeatherService
    {
        private readonly IHttpClientFactory _http;
        private readonly IConfiguration _config;
        private readonly ILogger<OpenWeatherService> _logger;

        private const string ClientName = "OpenWeatherClient";

        public OpenWeatherService(
            IHttpClientFactory http,
            IConfiguration config,
            ILogger<OpenWeatherService> logger)
        {
            _http = http;
            _config = config;
            _logger = logger;
        }

        public async Task<OpenWeatherCurrentDto?> GetCurrentAsync(
            double lat,
            double lon,
            CancellationToken cancellationToken = default)
        {
            if (!IsValidCoordinates(lat, lon))
                return null;

            var apiKey = _config["OpenWeather:ApiKey"];
            if (string.IsNullOrWhiteSpace(apiKey))
                return null;

            try
            {
                var client = _http.CreateClient(ClientName);

                var url =
                    $"data/2.5/weather?lat={lat}&lon={lon}&units=metric&appid={apiKey}";

                var response = await client.GetAsync(url, cancellationToken);

                if (!response.IsSuccessStatusCode)
                    return null;

                var json = await response.Content.ReadAsStringAsync(cancellationToken);

                return JsonSerializer.Deserialize<OpenWeatherCurrentDto>(
                    json,
                    new JsonSerializerOptions
                    {
                        PropertyNameCaseInsensitive = true
                    });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "OpenWeatherService error");
                return null;
            }
        }

        private static bool IsValidCoordinates(double lat, double lon)
        {
            if (double.IsNaN(lat) || double.IsNaN(lon))
                return false;

            if (lat < -90 || lat > 90 || lon < -180 || lon > 180)
                return false;

            if (Math.Abs(lat) < 0.000001 && Math.Abs(lon) < 0.000001)
                return false;

            return true;
        }
    }
}