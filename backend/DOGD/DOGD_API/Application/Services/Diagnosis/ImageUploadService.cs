namespace DOGD_API.Application.Services.Diagnosis
{
    public interface IImageUploadService
    {
        Task<string> UploadImageAsync(IFormFile image);
        Task DeleteImageAsync(string imageUrl);
    }

    public class ImageUploadService : IImageUploadService
    {
        private readonly IWebHostEnvironment _env;

        public ImageUploadService(IWebHostEnvironment env)
        {
            _env = env;
        }

        public async Task<string> UploadImageAsync(IFormFile image)
        {
            var folder = Path.Combine(_env.WebRootPath, "uploads");
            if (!Directory.Exists(folder))
                Directory.CreateDirectory(folder);

            var fileName = $"{Guid.NewGuid()}{Path.GetExtension(image.FileName)}";
            var filePath = Path.Combine(folder, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await image.CopyToAsync(stream);
            }

            return $"/uploads/{fileName}";
        }

        public Task DeleteImageAsync(string imageUrl)
        {
            if (string.IsNullOrEmpty(imageUrl))
                return Task.CompletedTask;

            try
            {
                // imageUrl expected like "/uploads/{fileName}"
                var relative = imageUrl.TrimStart('/').Replace('/', Path.DirectorySeparatorChar);
                var filePath = Path.Combine(_env.WebRootPath, relative);

                if (File.Exists(filePath))
                    File.Delete(filePath);
            }
            catch
            {
                // best-effort delete - do not throw
            }

            return Task.CompletedTask;
        }
    }

}
