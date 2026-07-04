using System.Text.Json.Serialization;

namespace DOGD_API.Application.DTOs.Weather
{
    public class OpenWeatherCurrentDto
    {
        [JsonPropertyName("main")]
        public MainInfo Main { get; set; }

        public class MainInfo
        {
            [JsonPropertyName("temp")]
            public double Temp { get; set; }

            [JsonPropertyName("humidity")]
            public double Humidity { get; set; }
        }
    }
}
