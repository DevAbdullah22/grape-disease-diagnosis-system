


using System.Net.Http.Headers;
using System.Text.Json;
using DOGD_API.Application.DTOs.AI;
using DOGD_API.Application.Services.AI;

public class YoloService : IYoloService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<YoloService> _logger;

    public YoloService(HttpClient httpClient, ILogger<YoloService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<(string status, string disease, float confidence)>
        AnalyzeAsync(IFormFile image)
    {
        using var form = new MultipartFormDataContent();

        using var stream = image.OpenReadStream();
        var content = new StreamContent(stream);
        content.Headers.ContentType =
            new MediaTypeHeaderValue(image.ContentType);

        // الاسم لازم يكون "file" نفس FastAPI
        form.Add(content, "file", image.FileName);

        var response = await _httpClient.PostAsync("diagnose", form);
        response.EnsureSuccessStatusCode();

        var json = await response.Content.ReadAsStringAsync();

        // حاول قراءة الحقول بشكل مرن لأن اسم الحقل قد يختلف بين الخادمات
        var result = JsonSerializer.Deserialize<YoloResponse>(
            json,
            new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

        // قيم افتراضية آمنة
        string status = string.IsNullOrWhiteSpace(result?.Status)
            ? "uncertain"
            : result!.Status.Trim().ToLowerInvariant();
        string diseaseClass = result?.Class ?? string.Empty;
        float confidenceRaw = result?.Confidence ?? 0f;

        // تسجيل للمساعدة في تتبع السبب
        try
        {
            _logger.LogInformation("YOLO response JSON: {json}", json);
            _logger.LogInformation("Parsed YOLO -> status: {status}, class: {cls}, confidenceRaw: {conf}",
                status, diseaseClass, confidenceRaw);
        }
        catch { }

        return (
            status,
            diseaseClass,
            confidenceRaw > 1f ? confidenceRaw / 100f : confidenceRaw
        );
    }
}
