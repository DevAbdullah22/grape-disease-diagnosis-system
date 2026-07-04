//namespace DOGD_API.Application.Services.AI
//{
//    public interface IYoloService
//    {
//        Task<(string disease, float confidence)>
//            AnalyzeAsync(IFormFile image);
//    }

//}


namespace DOGD_API.Application.Services.AI
{
    public interface IYoloService
    {
        // Returns the FastAPI status first; callers should branch only on status.
        Task<(string status, string disease, float confidence)>
            AnalyzeAsync(IFormFile image);
    }

}
