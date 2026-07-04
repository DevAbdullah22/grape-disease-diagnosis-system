using DOGD_API.Application.DTOs.DiseaseDtos;
using DOGD_API.Data;
using DOGD_API.Models;
using Microsoft.EntityFrameworkCore;

namespace DOGD_API.Application.Services.Disease
{
    public class DiseaseService : IDiseaseService
    {
        private readonly AppDbContext _db;
        private readonly ILogger<DiseaseService> _logger;
        private readonly DOGD_API.Application.Services.Diagnosis.IImageUploadService _imageUpload;

        public DiseaseService(AppDbContext db, ILogger<DiseaseService> logger, DOGD_API.Application.Services.Diagnosis.IImageUploadService imageUpload)
        {
            _db = db;
            _logger = logger;
            _imageUpload = imageUpload;
        }

        public async Task<List<DiseaseDto>> GetAllAsync()
        {
            return await _db.Diseases
                .Select(d => new DiseaseDto
                {
                    Id = d.Id,
                    Name = d.Name,
                    Description = d.Description,
                    ImageUrl = d.ImageUrl,
                    ReferenceImages = d.ReferenceImages.Select(r => new ReferenceImageDto { Id = r.Id, ImageUrl = r.ImageUrl }).ToList()
                })
                .ToListAsync();
        }

        public async Task<DiseaseDto> CreateWithFileAsync(CreateDiseaseDto dto, IFormFile? imageFile)
        {
            string imageUrl = dto.ImageUrl;
            if (imageFile != null)
            {
                imageUrl = await _imageUpload.UploadImageAsync(imageFile);
            }

            var created = await CreateAsync(new CreateDiseaseDto { Name = dto.Name, Description = dto.Description, ImageUrl = imageUrl });
            return created;
        }

        public async Task<DiseaseDto?> GetByIdAsync(Guid id)
        {
            var d = await _db.Diseases.Include(x => x.ReferenceImages).FirstOrDefaultAsync(x => x.Id == id);
            if (d == null) return null;
            return new DiseaseDto
            {
                Id = d.Id,
                Name = d.Name,
                Description = d.Description,
                ImageUrl = d.ImageUrl,
                ReferenceImages = d.ReferenceImages.Select(r => new ReferenceImageDto { Id = r.Id, ImageUrl = r.ImageUrl }).ToList()
            };
        }

        public async Task<DiseaseDto> CreateAsync(CreateDiseaseDto dto)
        {
            var d = new DOGD_API.Models.Disease
            {
                Id = Guid.NewGuid(),
                Name = dto.Name,
                Description = dto.Description,
                ImageUrl = dto.ImageUrl
            };

            _db.Diseases.Add(d);
            await _db.SaveChangesAsync();

            return new DiseaseDto { Id = d.Id, Name = d.Name, Description = d.Description, ImageUrl = d.ImageUrl, ReferenceImages = new List<ReferenceImageDto>() };
        }

        public async Task<DiseaseDto> UpdateAsync(UpdateDiseaseDto dto)
        {
            var d = await _db.Diseases.FindAsync(dto.Id);
            if (d == null) throw new KeyNotFoundException("Disease not found");

            d.Name = dto.Name;
            d.Description = dto.Description;
            d.ImageUrl = dto.ImageUrl;

            await _db.SaveChangesAsync();

            // load ref images
            var refs = await _db.ReferenceImages.Where(r => r.DiseaseId == d.Id).ToListAsync();
            return new DiseaseDto { Id = d.Id, Name = d.Name, Description = d.Description, ImageUrl = d.ImageUrl, ReferenceImages = refs.Select(r => new ReferenceImageDto { Id = r.Id, ImageUrl = r.ImageUrl }).ToList() };
        }

        public async Task<DiseaseDto> UpdateWithFileAsync(Guid id, UpdateDiseaseDto dto, IFormFile? imageFile, bool hasName, bool hasDescription, bool hasImageUrl)
        {
            var existing = await _db.Diseases.FindAsync(id);
            if (existing == null) throw new KeyNotFoundException("Disease not found");

            string imageUrl = existing.ImageUrl;

            if (imageFile != null)
            {
                var newUrl = await _imageUpload.UploadImageAsync(imageFile);
                try { await _imageUpload.DeleteImageAsync(existing.ImageUrl); } catch { }
                imageUrl = newUrl;
            }
            else if (hasImageUrl)
            {
                imageUrl = dto.ImageUrl;
            }

            existing.Name = hasName ? dto.Name : existing.Name;
            existing.Description = hasDescription ? dto.Description : existing.Description;
            existing.ImageUrl = imageUrl;

            await _db.SaveChangesAsync();

            return new DiseaseDto { Id = existing.Id, Name = existing.Name, Description = existing.Description, ImageUrl = existing.ImageUrl };
        }

        public async Task<List<ReferenceImageDto>> AddReferenceImagesAsync(Guid id, List<IFormFile> files)
        {
            var disease = await _db.Diseases.FindAsync(id);
            if (disease == null) throw new KeyNotFoundException("Disease not found");

            if (files == null || files.Count == 0) return new List<ReferenceImageDto>();

            var uploadedUrls = new List<string>();
            var added = new List<DOGD_API.Application.DTOs.DiseaseDtos.ReferenceImageDto>();

            foreach (var file in files)
            {
                var url = await _imageUpload.UploadImageAsync(file);
                uploadedUrls.Add(url);
                var ri = new DOGD_API.Models.ReferenceImage { ImageUrl = url, DiseaseId = id };
                _db.ReferenceImages.Add(ri);
                added.Add(new DOGD_API.Application.DTOs.DiseaseDtos.ReferenceImageDto { Id = ri.Id, ImageUrl = ri.ImageUrl });
            }

            await _db.SaveChangesAsync();

            if (string.IsNullOrWhiteSpace(disease.ImageUrl))
            {
                var first = uploadedUrls.FirstOrDefault();
                if (!string.IsNullOrWhiteSpace(first))
                {
                    disease.ImageUrl = first;
                    await _db.SaveChangesAsync();
                }
            }

            // return newly added images by querying latest
            var result = await _db.ReferenceImages.Where(r => r.DiseaseId == id).OrderByDescending(r => r.Id)
                .Take(uploadedUrls.Count)
                .Select(r => new DOGD_API.Application.DTOs.DiseaseDtos.ReferenceImageDto { Id = r.Id, ImageUrl = r.ImageUrl })
                .ToListAsync();

            return result;
        }

        public async Task DeleteReferenceImageAsync(Guid id, int imageId)
        {
            var img = await _db.ReferenceImages.FirstOrDefaultAsync(r => r.Id == imageId && r.DiseaseId == id);
            if (img == null) throw new KeyNotFoundException("Reference image not found");

            try { await _imageUpload.DeleteImageAsync(img.ImageUrl); } catch { }

            _db.ReferenceImages.Remove(img);
            await _db.SaveChangesAsync();

            var disease = await _db.Diseases.FindAsync(id);
            if (disease != null && disease.ImageUrl == img.ImageUrl)
            {
                var next = await _db.ReferenceImages.Where(r => r.DiseaseId == id).OrderBy(r => r.Id).FirstOrDefaultAsync();
                disease.ImageUrl = next?.ImageUrl ?? string.Empty;
                await _db.SaveChangesAsync();
            }
        }

        public async Task DeleteAsync(Guid id)
        {
            var d = await _db.Diseases.FindAsync(id);
            if (d == null) throw new KeyNotFoundException("Disease not found");

            // Remove related reference images first
            var images = _db.ReferenceImages.Where(r => r.DiseaseId == id);
            _db.ReferenceImages.RemoveRange(images);

            _db.Diseases.Remove(d);
            await _db.SaveChangesAsync();
        }
    }
}
