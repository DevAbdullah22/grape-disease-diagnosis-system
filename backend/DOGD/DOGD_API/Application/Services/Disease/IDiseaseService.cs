using DOGD_API.Application.DTOs.DiseaseDtos;

namespace DOGD_API.Application.Services.Disease
{
    public interface IDiseaseService
    {
        Task<List<DiseaseDto>> GetAllAsync();
        Task<DiseaseDto?> GetByIdAsync(Guid id);
        Task<DiseaseDto> CreateAsync(CreateDiseaseDto dto);
        Task<DiseaseDto> UpdateAsync(UpdateDiseaseDto dto);
        Task DeleteAsync(Guid id);
        Task<DiseaseDto> CreateWithFileAsync(CreateDiseaseDto dto, IFormFile? imageFile);
        Task<DiseaseDto> UpdateWithFileAsync(Guid id, UpdateDiseaseDto dto, IFormFile? imageFile, bool hasName, bool hasDescription, bool hasImageUrl);
        Task<List<ReferenceImageDto>> AddReferenceImagesAsync(Guid id, List<IFormFile> files);
        Task DeleteReferenceImageAsync(Guid id, int imageId);
    }
}
