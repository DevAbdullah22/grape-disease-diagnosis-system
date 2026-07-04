using DOGD_API.Application.Services.Notifications;
using DOGD_API.Application.Services.Weather;
using DOGD_API.Data;
using DOGD_API.Models;
using Microsoft.EntityFrameworkCore;

namespace DOGD_API.Application.BackgroundJobs
{
    public class WeatherMonitoringJob
    {
        private readonly AppDbContext _db;
        private readonly IWeatherService _weatherService;
        private readonly IFcmService _fcmService;
        private readonly ILogger<WeatherMonitoringJob> _logger;

        private static readonly TimeSpan AlertCooldown = TimeSpan.FromHours(6);

        public WeatherMonitoringJob(
            AppDbContext db,
            IWeatherService weatherService,
            IFcmService fcmService,
            ILogger<WeatherMonitoringJob> logger)
        {
            _db = db;
            _weatherService = weatherService;
            _fcmService = fcmService;
            _logger = logger;
        }

        public async Task RunAsync()
        {
            var farms = await _db.Farms.AsNoTracking().ToListAsync();
            var rules = await _db.DiseaseWeatherRules.AsNoTracking().ToListAsync();

            if (!farms.Any() || !rules.Any())
                return;

            foreach (var farm in farms)
            {
                try
                {
                    var weather = await _weatherService
                        .GetCurrentAsync(farm.Latitude, farm.Longitude);

                    if (weather?.Main == null)
                        continue;

                    var temp = weather.Main.Temp;
                    var hum = weather.Main.Humidity;

                    foreach (var rule in rules)
                    {
                        var match =
                            temp >= rule.MinTemperature &&
                            temp <= rule.MaxTemperature &&
                            hum >= rule.MinHumidity &&
                            hum <= rule.MaxHumidity;

                        if (!match)
                            continue;

                        var title =
                            $"تنبيه الطقس: {farm.Name}";

                        var body =
                            $"تم رصد ظروف جوية مناسبة لانتشار {rule.DiseaseName} (درجة الحرارة {temp}°C، الرطوبة {hum}%). يرجى التحقق واتخاذ الإجراءات الوقائية.";

                        var sent = await _fcmService.SendAsync(
                            farm.UserId,
                            "Weather",
                            title,
                            body,
                            new
                            {
                                FarmId = farm.Id.ToString(),
                                FarmName = farm.Name,
                                Disease = rule.DiseaseName
                            });

                        _db.Notifications.Add(new Notification
                        {
                            Id = Guid.NewGuid(),
                            UserId = farm.UserId,
                            Title = title,
                            Body = body,
                            Type = "Weather",
                            RelatedId = farm.Id,
                            IsSent = sent,
                            SentAt = sent ? DateTime.UtcNow : null,
                            CreatedAt = DateTime.UtcNow
                        });
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex,
                        "Error processing farm {FarmId}",
                        farm.Id);
                }
            }

            await _db.SaveChangesAsync();
        }
    }
}