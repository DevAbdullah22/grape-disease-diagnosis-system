
namespace DOGD_API.Models
{
    public class DiseaseWeatherRule
    {
        public Guid Id { get; set; }
        public string DiseaseName { get; set; }

        public double MinTemperature { get; set; }
        public double MaxTemperature { get; set; }

        public double MinHumidity { get; set; }
        public double MaxHumidity { get; set; }

        public string WarningMessage { get; set; }
    }
}
