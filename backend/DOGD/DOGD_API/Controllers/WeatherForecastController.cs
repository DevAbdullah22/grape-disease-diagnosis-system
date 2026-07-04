using Microsoft.AspNetCore.Mvc;

namespace DOGD_API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class WeatherForecastController : ControllerBase
    {
        private static readonly string[] Summaries = new[]
        {
            "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
        };

        private readonly ILogger<WeatherForecastController> _logger;

        public WeatherForecastController(ILogger<WeatherForecastController> logger)
        {
            _logger = logger;
        }

        // Lightweight DTO used only by this controller so we can remove the shared model.
        public sealed record WeatherDto(DateOnly Date, int TemperatureC, int TemperatureF, string? Summary);

        [HttpGet(Name = "GetWeatherForecast")]
        public IEnumerable<WeatherDto> Get()
        {
            return Enumerable.Range(1, 5).Select(index =>
            {
                var tempC = Random.Shared.Next(-20, 55);
                var tempF = 32 + (int)(tempC * 9 / 5.0);
                return new WeatherDto(
                    DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
                    tempC,
                    tempF,
                    Summaries[Random.Shared.Next(Summaries.Length)]
                );
            })
            .ToArray();
        }
    }
}
