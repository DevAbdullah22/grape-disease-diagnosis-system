namespace DOGD_API.Application.Services.Treatment_Services
{
    public interface ITextToSpeechService
    {
        Task<string> TextToSpeechAsync(string text, string fileNameHint = null);
    }

}
