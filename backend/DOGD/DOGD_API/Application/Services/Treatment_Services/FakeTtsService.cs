namespace DOGD_API.Application.Services.Treatment_Services
{
    public class FakeTtsService : ITextToSpeechService
    {
        private readonly IWebHostEnvironment _env;
        public FakeTtsService(IWebHostEnvironment env)
        {
            _env = env;
        }

        public async Task<string> TextToSpeechAsync(string text, string fileNameHint = null)
        {
            var folder = Path.Combine(_env.WebRootPath, "tts");
            if (!Directory.Exists(folder)) Directory.CreateDirectory(folder);

            var fileName = $"{Guid.NewGuid()}.mp3"; // placeholder file name
            var path = Path.Combine(folder, fileName);

            // نكتب النص داخل ملف txt فقط كبديل مؤقت (يمكن استبداله بملف صوتي فعلي لاحقاً)
            await File.WriteAllTextAsync(path, "TTS placeholder: " + text);

            // نرجع رابط قابل للوصول من الويب
            return $"/tts/{fileName}";
        }
    }

}
